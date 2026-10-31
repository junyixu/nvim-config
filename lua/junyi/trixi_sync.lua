-- trixi-sync: on-demand sync between a local working copy and a remote project
-- directory. Lua port of ~/bin/trixi-sync, driven by `:TrixiSync` (see
-- plugin/trixi_sync.lua). The baseline files under $XDG_STATE_HOME/trixi-sync/<name>/
-- keep the same format as the bash script, so the two can be used interchangeably.
--
-- Everything runs inside a coroutine: `run()` yields until a vim.system job
-- finishes, so the sync logic reads top-to-bottom like the original script while
-- never blocking the editor on ssh/rsync.

local M = {}

M.subcommands = { 'status', 'pull', 'push', 'logs', 'init', 'reset' }
M.flags = { '--dry-run', '--yes', '--force', '-n', '-y', '-f' }

local USAGE = {
  ':TrixiSync init              首次拉取，并建立同步基线',
  ':TrixiSync status            看两边相对上次同步改了什么',
  ':TrixiSync push  [-y] [-f]   本地 -> 远端（先查远端有没有被改过）',
  ':TrixiSync pull  [-y] [-f]   远端 -> 本地（自动跳过冲突文件）',
  ':TrixiSync logs  [PATTERN]   只拉 logs/，单向，不动代码',
  ':TrixiSync reset             用两边当前状态重建基线（手工解决冲突后用）',
  '',
  '选项：',
  '  -n, --dry-run   只打印将要做什么，不实际传输、不更新基线',
  '  -y, --yes       不询问（删除文件时默认会问）',
  '  -f, --force     忽略“对面自上次同步后被改动 / 两边内容不同”的检查',
  '',
  '配置：环境变量 TRIXI_HOST / TRIXI_REMOTE / TRIXI_LOCAL / TRIXI_NAME / TRIXI_EXCLUDES，',
  '      或 ~/.config/trixi-sync/<name>.conf（KEY=VALUE 行，优先于环境变量）',
}

-- 远端扫描脚本：一次 ssh 同时带回归档 HEAD（#head 行）和文件列表
local REMOTE_SCAN = [=[
dir=$1; shift
cd "$dir" 2>/dev/null || { echo "trixi-sync: 远端目录不存在: $dir" >&2; exit 9; }
if [ -d .git ]; then
  printf '#head\t%s\n' "$(git rev-parse --short HEAD 2>/dev/null || echo none)"
fi
cond=""
for e in "$@"; do cond="${cond:+$cond -o }-name $e"; done
find . \( $cond \) -prune -o -type f -printf '%p\t%s\t%T@\n' \
  | awk -F'\t' -v OFS='\t' '{ sub(/\..*/, "", $3); print }'
]=]

local REPORT = 'trixi-sync://report'
local HR = string.rep('-', 60)

local running = false
local out = {}

-- ---------------------------------------------------------------- 基础

local function say(s)
  out[#out + 1] = s or ''
end

-- 中止本次命令；msg 为 nil 表示原因已经 say 过了
local function abort(msg)
  error({ msg = msg }, 0)
end

local function env(key)
  local v = vim.env[key]
  return v ~= '' and v or nil
end

local function read_conf(path)
  local conf = {}
  local f = io.open(path, 'r')
  if not f then
    return conf
  end
  for line in f:lines() do
    local k, v = line:match '^%s*([%w_]+)=(.-)%s*$'
    if k then
      conf[k] = v:gsub('^(["\'])(.*)%1$', '%2')
    end
  end
  f:close()
  return conf
end

local function config()
  local home = vim.env.HOME
  local name = env 'TRIXI_NAME' or 'trixi-reactant'
  local conf = read_conf(('%s/trixi-sync/%s.conf'):format(env 'XDG_CONFIG_HOME' or home .. '/.config', name))
  local function get(key, default)
    local v = conf[key] or env(key)
    return (v and v ~= '') and v or default
  end

  local c = {
    host = get('TRIXI_HOST', 'tw'),
    remote = get('TRIXI_REMOTE', '/home/junyi/WorkSpace/TrixiReactant.jl'),
    local_dir = vim.fs.normalize(get('TRIXI_LOCAL', home .. '/WorkSpace/TrixiReactant.jl')),
    state = ('%s/trixi-sync/%s'):format(env 'XDG_STATE_HOME' or home .. '/.local/state', name),
    -- 不参与同步的目录名（任意层级）。ref/ 是只读资料，logs/ 是远端产物，
    -- .claude/ 是各机器自己的编辑器配置。.git/ 不归 trixi-sync 管——历史走 git 自己。
    excludes = vim.split(get('TRIXI_EXCLUDES', 'ref logs .git .claude __pycache__ .ipynb_checkpoints'), '%s+', { trimempty = true }),
    ssh_opts = {
      '-o', 'BatchMode=yes',
      '-o', 'ControlMaster=auto',
      '-o', 'ControlPath=' .. home .. '/.ssh/cm-%r@%h:%p',
      '-o', 'ControlPersist=10m',
      '-o', 'ServerAliveInterval=15',
      '-o', 'ServerAliveCountMax=3',
      '-o', 'Compression=no',
    },
  }
  c.rsync_excludes = vim.tbl_map(function(e)
    return '--exclude=' .. e .. '/'
  end, c.excludes)
  c.rsync_e = 'ssh ' .. table.concat(c.ssh_opts, ' ')
  return c
end

-- 在协程里跑外部命令，等它结束后返回 vim.SystemCompleted
local function run(cmd, opts)
  local co = coroutine.running()
  vim.system(cmd, vim.tbl_extend('force', { text = true }, opts or {}), function(r)
    vim.schedule(function()
      coroutine.resume(co, r)
    end)
  end)
  return coroutine.yield()
end

local function rsync(c, args, src, dst)
  local cmd = { 'rsync' }
  vim.list_extend(cmd, args)
  vim.list_extend(cmd, { '-e', c.rsync_e, src, dst })
  return run(cmd)
end

-- ---------------------------------------------------------------- 报告窗口

local function show()
  local buf = vim.fn.bufnr(REPORT)
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, REPORT)
    vim.bo[buf].bufhidden = 'hide'
    vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = buf, nowait = true, desc = 'Close trixi-sync report' })
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].modifiable = false

  local height = math.max(3, math.min(#out, 20))
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    vim.cmd('botright ' .. height .. 'split')
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].winfixheight = true
    vim.cmd 'wincmd p'
  else
    vim.api.nvim_win_set_height(win, height)
  end
  vim.api.nvim_win_set_cursor(win, { #out > 0 and #out or 1, 0 })
end

local function confirm(msg)
  show()
  vim.cmd.redraw()
  return vim.fn.confirm(msg, '&Yes\n&No', 2) == 1
end

-- ---------------------------------------------------------------- 扫描
-- 扫描结果: { ['./path'] = 'size\tmtime' }

local function scan_local(c)
  if vim.fn.isdirectory(c.local_dir) == 0 then
    abort('本地目录不存在: ' .. c.local_dir)
  end
  local skip = {}
  for _, e in ipairs(c.excludes) do
    skip[e] = true
  end
  local files = {}
  local function walk(rel)
    local handle = vim.uv.fs_scandir(rel == '' and c.local_dir or c.local_dir .. '/' .. rel)
    if not handle then
      return
    end
    while true do
      local name, typ = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if not skip[name] then
        local p = rel == '' and name or rel .. '/' .. name
        local st = (typ == 'file' or not typ) and vim.uv.fs_lstat(c.local_dir .. '/' .. p)
        if typ == 'directory' then
          walk(p)
        elseif st and st.type == 'file' then
          files['./' .. p] = st.size .. '\t' .. st.mtime.sec
        end
      end
    end
  end
  walk ''
  return files
end

local function scan_remote(c)
  local cmd = { 'ssh' }
  vim.list_extend(cmd, c.ssh_opts)
  vim.list_extend(cmd, { c.host, 'bash', '-s', c.remote })
  vim.list_extend(cmd, c.excludes)
  local r = run(cmd, { stdin = REMOTE_SCAN })
  if r.code ~= 0 then
    abort(('无法扫描远端 %s:%s\n%s'):format(c.host, c.remote, vim.trim(r.stderr or '')))
  end
  local files, head = {}, nil
  for line in r.stdout:gmatch '[^\n]+' do
    local p, rest = line:match '^([^\t]*)\t(.*)$'
    if p == '#head' then
      head = rest
    elseif p then
      files[p] = rest
    end
  end
  return files, head
end

local function sorted_keys(t)
  local keys = vim.tbl_keys(t)
  table.sort(keys)
  return keys
end

local function read_scan(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local scan = {}
  for line in f:lines() do
    local p, rest = line:match '^([^\t]*)\t(.*)$'
    if p then
      scan[p] = rest
    end
  end
  f:close()
  return scan
end

local function write_lines(path, lines)
  local tmp = path .. '.tmp'
  local f = assert(io.open(tmp, 'w'))
  f:write(table.concat(lines, '\n'), #lines > 0 and '\n' or '')
  f:close()
  assert(os.rename(tmp, path))
end

local function write_scan(path, scan)
  local lines = {}
  for _, p in ipairs(sorted_keys(scan)) do
    lines[#lines + 1] = p .. '\t' .. scan[p]
  end
  write_lines(path, lines)
end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local s = f:read '*a'
  f:close()
  return s
end

-- ---------------------------------------------------------------- 集合
-- 集合: { ['./path'] = true }

-- 相对基线的改动（含新增、修改、删除）
local function changed(cur, base)
  local s = {}
  for p, sig in pairs(cur) do
    if base[p] ~= sig then
      s[p] = true
    end
  end
  for p in pairs(base) do
    if not cur[p] then
      s[p] = true
    end
  end
  return s
end

-- 两边内容不一致（size/mtime 不同，或只有一边有）
local function diff_sides(loc, rem)
  local s = {}
  for p, sig in pairs(loc) do
    if rem[p] ~= sig then
      s[p] = true
    end
  end
  for p in pairs(rem) do
    if not loc[p] then
      s[p] = true
    end
  end
  return s
end

local function inter(a, b)
  local s = {}
  for p in pairs(a) do
    if b[p] then
      s[p] = true
    end
  end
  return s
end

local function minus(a, b)
  local s = {}
  for p in pairs(a) do
    if not b[p] then
      s[p] = true
    end
  end
  return s
end

local function count(s)
  return vim.tbl_count(s)
end

-- 把路径集合渲染成 +新增 / M修改 / -删除
local function render(set, base, cur, prefix)
  for _, p in ipairs(sorted_keys(set)) do
    local mark = not base[p] and '+' or not cur[p] and '-' or 'M'
    say(prefix .. mark .. ' ' .. p)
  end
end

local function print_list(set, title, base, cur)
  say ''
  say(('%s  (%d)'):format(title, count(set)))
  render(set, base, cur, '  ')
end

local function print_plain(set, prefix)
  for _, p in ipairs(sorted_keys(set)) do
    say(prefix .. p)
  end
end

-- ---------------------------------------------------------------- 状态

local function last_sync(c)
  local s = read_file(c.state .. '/last')
  return s and vim.trim(s) or '从未同步'
end

local function collect_status(c)
  local base_l = read_scan(c.state .. '/base.local')
  local base_r = read_scan(c.state .. '/base.remote')
  if not (base_l and base_r) then
    abort "还没有同步基线。首次使用请跑 ':TrixiSync init'（本地已有副本则用 ':TrixiSync reset'）"
  end

  local st = { base_l = base_l, base_r = base_r }
  st.loc = scan_local(c)
  st.rem, st.head = scan_remote(c)

  st.cl = changed(st.loc, base_l)
  st.cr = changed(st.rem, base_r)
  local both = inter(st.cl, st.cr)
  st.local_only = minus(st.cl, st.cr)
  st.remote_only = minus(st.cr, st.cl)

  local side_diff = diff_sides(st.loc, st.rem)
  st.conflict = inter(both, side_diff)
  st.both_same = minus(both, side_diff)

  -- 两边内容不一样、但各自都没相对基线改动（例如上次 pull 跳过了冲突）
  st.diverged = minus(side_diff, vim.tbl_extend('force', {}, st.cl, st.cr))
  return st
end

-- 同步成功后重建基线：以两边“此刻真实的状态”为准
-- st/keep 可选：keep 里的路径沿用旧基线（st.base_l/base_r），让它们下次仍算作改动
local function snapshot(c, tag, st, keep)
  vim.fn.mkdir(c.state, 'p')
  local loc, rem = scan_local(c), (scan_remote(c))
  for p in pairs(keep or {}) do
    loc[p], rem[p] = st.base_l[p], st.base_r[p]
  end
  write_scan(c.state .. '/base.local', loc)
  write_scan(c.state .. '/base.remote', rem)
  write_lines(c.state .. '/last', { os.date '%Y-%m-%d %H:%M' .. ' ' .. tag })
end

-- 解析 rsync --itemize-changes 的输出
local function parse_plan(stdout, xfer, arrow, show_mkdir)
  local items, ntrans, ndel = {}, 0, 0
  for line in stdout:gmatch '[^\n]+' do
    local flag, p = line:match '^(%S+)%s+(.*)$'
    if flag then
      if flag:sub(1, 2) == xfer then
        ntrans = ntrans + 1
        items[#items + 1] = arrow .. ' ' .. p
      elseif flag == '*deleting' then
        ndel = ndel + 1
        items[#items + 1] = '-- ' .. p
      elseif show_mkdir and flag:sub(1, 2) == 'cd' then
        items[#items + 1] = 'mk ' .. p
      end
    end
  end
  return items, ntrans, ndel
end

local function check_rc(r)
  if r.code ~= 0 and r.code ~= 24 then
    abort(('rsync 失败 (rc=%d)，基线未更新\n%s'):format(r.code, vim.trim(r.stderr or '')))
  end
end

local function confirm_delete(o, ndel, where)
  if ndel == 0 or o.yes then
    return
  end
  say ''
  if not confirm(('确认删除%s以上 %d 个文件?'):format(where, ndel)) then
    abort '已取消'
  end
end

-- ---------------------------------------------------------------- 命令

local cmd = {}

function cmd.status(c)
  local st = collect_status(c)
  say(('远端 %s:%s'):format(c.host, c.remote))
  say(('HEAD %s · 上次同步 %s'):format(st.head or 'none', last_sync(c)))
  say(HR)
  print_list(st.local_only, '待 push（本地改过，远端没动）', st.base_l, st.loc)
  print_list(st.remote_only, '待 pull（远端改过，本地没动）', st.base_r, st.rem)
  print_list(st.conflict, '冲突（两边都改过）', st.base_l, st.loc)
  if next(st.diverged) then
    say ''
    say(('两边不一致（需要决定推还是拉）  (%d)'):format(count(st.diverged)))
    print_plain(st.diverged, '  ? ')
  end
  if next(st.both_same) then
    say ''
    say(('两边改成了同样内容（无需处理）  (%d)'):format(count(st.both_same)))
  end
  local conflicts = read_file(c.state .. '/conflicts')
  if conflicts and conflicts ~= '' then
    say ''
    say '上次 pull 遗留的未解决冲突：'
    for p in conflicts:gmatch '[^\n]+' do
      say('  ! ' .. p)
    end
    say "  处理完后跑 ':TrixiSync reset' 清除这条记录"
  end
  if not next(st.cl) and not next(st.cr) then
    say ''
    say '两边与基线一致，没有待同步的改动。'
  end
end

function cmd.push(c, o)
  local st = collect_status(c)

  -- 有冲突直接中止（pull 走的是“跳过并记录”）
  if next(st.conflict) then
    say ''
    say(('检测到 %d 个两边都改过的文件，已中止：'):format(count(st.conflict)))
    render(st.conflict, st.base_l, st.loc, '  ! ')
    say ''
    say "建议用 :DiffRemote 对比后手工合并，然后 ':TrixiSync reset' 再重试。"
    abort()
  end
  if next(st.remote_only) and not o.force then
    say ''
    say '远端自上次同步后有改动，拒绝覆盖（加 -f 可强制）：'
    render(st.remote_only, st.base_r, st.rem, '  ! ')
    abort()
  end
  if next(st.diverged) and not o.force then
    say ''
    say '以下文件两边内容不同，push 会覆盖远端版本（加 -f 继续，或先 pull）：'
    print_plain(st.diverged, '  ? ')
    abort()
  end

  local args = { '--delete', '--itemize-changes' }
  vim.list_extend(args, c.rsync_excludes)
  local src, dst = c.local_dir .. '/', c.host .. ':' .. c.remote .. '/'

  local plan = rsync(c, vim.list_extend({ '-an' }, args), src, dst)
  if plan.code ~= 0 then
    abort('预检失败（ssh/rsync 出错）\n' .. vim.trim(plan.stderr or ''))
  end
  local items, ntrans, ndel = parse_plan(plan.stdout, '<f', '->', true)
  say ''
  say(('将推送 %d 个文件，删除远端 %d 个文件'):format(ntrans, ndel))
  for _, l in ipairs(items) do
    say('  ' .. l)
  end

  confirm_delete(o, ndel, '远端')
  if o.dry then
    say ''
    say '(--dry-run，未实际传输)'
    return
  end

  -- 不因为“预检计数为 0”而跳过：直接跑一次 rsync 最可靠（无事可做时它本身是空操作）
  check_rc(rsync(c, vim.list_extend({ '-a' }, args), src, dst))
  snapshot(c, 'push')
  say ''
  say(ntrans + ndel == 0 and '远端已是最新。' or ('已推送 -> %s:%s'):format(c.host, c.remote))
  say(('基线已更新 (%s)'):format(last_sync(c)))
end

function cmd.pull(c, o)
  local st = collect_status(c)

  if next(st.diverged) and not o.force then
    say ''
    say '以下文件两边内容不同，pull 会覆盖本地版本（加 -f 继续，或先 push）：'
    print_plain(st.diverged, '  ? ')
    abort()
  end

  -- 规则按先后匹配，所以跳过/保护规则必须排在通用 exclude 之前
  local filters = {}
  if next(st.conflict) then
    say ''
    say(('以下 %d 个文件两边都改过，本次跳过，请手工合并：'):format(count(st.conflict)))
    render(st.conflict, st.base_l, st.loc, '  ! ')
    for _, p in ipairs(sorted_keys(st.conflict)) do
      filters[#filters + 1] = '--exclude=' .. p:sub(2)
    end
  end
  -- 本地改过但还没 push 的文件：还在的保护起来别被 --delete 干掉；
  -- 本地删掉的不能再从远端拉回来
  for _, p in ipairs(sorted_keys(st.local_only)) do
    local rel = p:sub(3)
    if st.loc[p] then
      filters[#filters + 1] = '--filter=P /' .. rel
      local d = rel:match '^(.*)/'
      while d do
        filters[#filters + 1] = '--filter=P /' .. d .. '/'
        d = d:match '^(.*)/'
      end
    else
      filters[#filters + 1] = '--exclude=/' .. rel
    end
  end

  local args = { '--delete', '--itemize-changes' }
  vim.list_extend(args, filters)
  vim.list_extend(args, c.rsync_excludes)
  local src, dst = c.host .. ':' .. c.remote .. '/', c.local_dir .. '/'

  local plan = rsync(c, vim.list_extend({ '-an' }, args), src, dst)
  if plan.code ~= 0 then
    abort('预检失败（ssh/rsync 出错）\n' .. vim.trim(plan.stderr or ''))
  end
  local items, ntrans, ndel = parse_plan(plan.stdout, '>f', '<-', false)
  say ''
  say(('将拉取 %d 个文件，删除本地 %d 个文件'):format(ntrans, ndel))
  for _, l in ipairs(items) do
    say('  ' .. l)
  end

  confirm_delete(o, ndel, '本地')
  if o.dry then
    say ''
    say '(--dry-run，未实际传输)'
    return
  end

  check_rc(rsync(c, vim.list_extend({ '-a' }, args), src, dst))

  -- 把被跳过的冲突记下来，status 会一直提醒，直到 reset
  if next(st.conflict) then
    write_lines(c.state .. '/conflicts', sorted_keys(st.conflict))
  end
  -- 本地还没 push 的改动不进基线，pull 之后它们仍是“待 push”
  snapshot(c, 'pull', st, st.local_only)
  vim.cmd.checktime()
  say ''
  say(('已拉取 <- %s:%s'):format(c.host, c.remote))
  say(('基线已更新 (%s)'):format(last_sync(c)))
end

function cmd.logs(c, o, pat)
  vim.fn.mkdir(c.local_dir .. '/logs', 'p')
  local args = { '-az', '--info=stats1' }
  if o.dry then
    args[#args + 1] = '-n'
  end
  if pat then
    vim.list_extend(args, { '--include=*/', '--include=*' .. pat .. '*', '--exclude=*' })
  end
  say('拉取 logs/' .. (pat and ('（匹配 *%s*）'):format(pat) or ''))
  local r = rsync(c, args, c.host .. ':' .. c.remote .. '/logs/', c.local_dir .. '/logs/')
  if r.code ~= 0 then
    abort('拉取 logs 失败\n' .. vim.trim(r.stderr or ''))
  end
  vim.list_extend(out, vim.split(vim.trim(r.stdout), '\n'))
end

function cmd.init(c, o)
  vim.fn.mkdir(c.local_dir, 'p')
  say(('首次同步 %s:%s -> %s'):format(c.host, c.remote, c.local_dir))
  local args = { '-a', '--info=stats1' }
  if o.dry then
    args[#args + 1] = '-n'
  end
  vim.list_extend(args, c.rsync_excludes)
  local r = rsync(c, args, c.host .. ':' .. c.remote .. '/', c.local_dir .. '/')
  if r.code ~= 0 then
    abort('首次同步失败\n' .. vim.trim(r.stderr or ''))
  end
  vim.list_extend(out, vim.split(vim.trim(r.stdout), '\n'))
  if o.dry then
    say '(--dry-run，未建立基线)'
    return
  end
  snapshot(c, 'init')
  say ''
  say('完成。本地工作目录: ' .. c.local_dir)
  say(("下一步: cd %s && julia --project -e 'using Pkg; Pkg.instantiate()'"):format(c.local_dir))
end

function cmd.reset(c)
  snapshot(c, 'reset')
  os.remove(c.state .. '/conflicts')
  say(('基线已按两边当前状态重建 (%s)'):format(last_sync(c)))
end

-- ---------------------------------------------------------------- 入口

local function parse(fargs)
  local o, args = { dry = false, yes = false, force = false }, {}
  local rest = false
  for _, a in ipairs(fargs) do
    if rest or a:sub(1, 1) ~= '-' then
      args[#args + 1] = a
    elseif a == '--' then
      rest = true
    elseif a == '-n' or a == '--dry-run' then
      o.dry = true
    elseif a == '-y' or a == '--yes' then
      o.yes = true
    elseif a == '-f' or a == '--force' then
      o.force = true
    elseif a == '-h' or a == '--help' then
      o.help = true
    else
      return nil, ('未知选项: %s（:TrixiSync -h 看帮助）'):format(a)
    end
  end
  return o, args
end

---@param fargs string[] e.g. { 'pull', '-y' }
function M.run(fargs)
  local o, args = parse(fargs)
  if not o then
    vim.notify('trixi-sync: ' .. args, vim.log.levels.ERROR)
    return
  end
  local name = args[1]
  if o.help or not name or name == 'help' then
    out = vim.deepcopy(USAGE)
    show()
    return
  end
  if not cmd[name] then
    vim.notify(('trixi-sync: 未知命令: %s（:TrixiSync -h 看帮助）'):format(name), vim.log.levels.ERROR)
    return
  end
  if running then
    vim.notify('trixi-sync: 上一个命令还在跑', vim.log.levels.WARN)
    return
  end

  running = true
  out = {}
  vim.notify(('trixi-sync %s …'):format(name))
  coroutine.wrap(function()
    local ok, err = pcall(cmd[name], config(), o, args[2])
    running = false
    local level = vim.log.levels.INFO
    if not ok then
      local msg
      if type(err) == 'table' then
        msg = err.msg
        level = msg == '已取消' and vim.log.levels.INFO or vim.log.levels.WARN
      else
        msg = tostring(err)
        level = vim.log.levels.ERROR
      end
      if msg then
        say ''
        say('trixi-sync: ' .. msg)
      end
    end
    show()
    vim.notify(('trixi-sync %s: %s'):format(name, ok and '完成' or '中止'), level)
  end)()
end

function M.complete(arglead, cmdline)
  local candidates = arglead:sub(1, 1) == '-' and M.flags or M.subcommands
  -- 子命令只补第一个位置参数
  if candidates == M.subcommands then
    for w in cmdline:gmatch '%s(%S+)' do
      if vim.tbl_contains(M.subcommands, w) and w ~= arglead then
        return {}
      end
    end
  end
  return vim.tbl_filter(function(s)
    return vim.startswith(s, arglead)
  end, candidates)
end

return M

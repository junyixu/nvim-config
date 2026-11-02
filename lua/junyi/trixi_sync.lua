-- trixi-sync: on-demand sync between a local working copy and a remote project
-- directory. Lua port of ~/bin/trixi-sync, driven by `:TrixiSync` (see
-- plugin/trixi_sync.lua). The baseline files under $XDG_STATE_HOME/trixi-sync/<name>/
-- keep the same format as the shell script, so the two can be used interchangeably.
--
-- Everything runs inside a coroutine: `run()` yields until a vim.system job
-- finishes, so the sync logic reads top-to-bottom like the original script while
-- never blocking the editor on ssh/rsync.

local M = {}

M.subcommands = { 'status', 'pull', 'push', 'logs', 'init', 'reset' }
M.flags = { '--dry-run', '--yes', '--force', '-n', '-y', '-f' }

local FLAG_KEYS = {
  ['-n'] = 'dry', ['--dry-run'] = 'dry',
  ['-y'] = 'yes', ['--yes'] = 'yes',
  ['-f'] = 'force', ['--force'] = 'force',
  ['-h'] = 'help', ['--help'] = 'help',
}

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

-- 往报告里追加若干行；say('', title) 是常见的“空一行再写标题”
local function say(...)
  vim.list_extend(out, { ... })
end

-- 中止本次命令；msg 为 nil 表示原因已经 say 过了
local function abort(msg)
  error({ msg = msg }, 0)
end

local function env(key)
  local v = vim.env[key]
  return v ~= '' and v or nil
end

-- 文件不存在时返回 nil
local function read_lines(path)
  return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or nil
end

local function write_lines(path, lines)
  local tmp = path .. '.tmp'
  assert(vim.fn.writefile(lines, tmp) == 0, 'cannot write ' .. tmp)
  assert(os.rename(tmp, path))
end

local function sorted_keys(t)
  local keys = vim.tbl_keys(t)
  table.sort(keys)
  return keys
end

local function config()
  local home = vim.env.HOME
  local name = env 'TRIXI_NAME' or 'trixi-reactant'
  local conf = {}
  local conf_path = ('%s/trixi-sync/%s.conf'):format(env 'XDG_CONFIG_HOME' or home .. '/.config', name)
  for _, line in ipairs(read_lines(conf_path) or {}) do
    local k, v = line:match '^%s*([%w_]+)=(.-)%s*$'
    if k then
      conf[k] = v:gsub('^(["\'])(.*)%1$', '%2')
    end
  end
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
    ssh = {
      'ssh',
      '-o', 'BatchMode=yes',
      '-o', 'ControlMaster=auto',
      '-o', 'ControlPath=' .. home .. '/.ssh/cm-%r@%h:%p',
      '-o', 'ControlPersist=10m',
      '-o', 'ServerAliveInterval=15',
      '-o', 'ServerAliveCountMax=3',
      '-o', 'Compression=no',
    },
  }
  c.excluded = {}
  for _, e in ipairs(c.excludes) do
    c.excluded[e] = true
  end
  c.rsync_excludes = vim.tbl_map(function(e)
    return '--exclude=' .. e .. '/'
  end, c.excludes)
  c.rsync_e = table.concat(c.ssh, ' ')
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

-- 远端是 POSIX shell；不用 vim.fn.shellescape，它会随本地 'shell' 选项变
local function shq(s)
  return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- ssh 会把 host 之后的参数拼成一条命令串，所以每个参数都要自己转义
local function ssh(c, remote_argv, opts)
  local cmd = vim.list_slice(c.ssh)
  vim.list_extend(cmd, { c.host, table.concat(vim.tbl_map(shq, remote_argv), ' ') })
  return run(cmd, opts)
end

local function rsync(c, args, src, dst)
  return run(vim.list_extend(vim.list_extend({ 'rsync' }, args), { '-e', c.rsync_e, src, dst }))
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
  vim.api.nvim_win_set_cursor(win, { math.max(#out, 1), 0 })
end

local function confirm(msg)
  show()
  vim.cmd.redraw()
  return vim.fn.confirm(msg, '&Yes\n&No', 2) == 1
end

-- ---------------------------------------------------------------- 扫描
-- 扫描结果 / 基线: { ['./path'] = 'size\tmtime' }，文件格式每行 path<TAB>size<TAB>mtime

local function scan_local(c)
  if vim.fn.isdirectory(c.local_dir) == 0 then
    abort('本地目录不存在: ' .. c.local_dir)
  end
  -- 与 find -prune -name 一致：同名的目录和文件都排除
  local function excluded(rel)
    return c.excluded[vim.fs.basename(rel)]
  end
  local files = {}
  local walk = vim.fs.dir(c.local_dir, {
    depth = math.huge,
    skip = function(dir)
      return not excluded(dir)
    end,
  })
  for rel, typ in walk do
    -- 'file' 只含普通文件；符号链接是 'link'，与 find -type f 一致不收
    if typ == 'file' and not excluded(rel) then
      local st = vim.uv.fs_lstat(c.local_dir .. '/' .. rel)
      if st then
        files['./' .. rel] = st.size .. '\t' .. st.mtime.sec
      end
    end
  end
  return files
end

local function parse_scan(lines)
  local scan, head = {}, nil
  for _, line in ipairs(lines) do
    local p, rest = line:match '^([^\t]*)\t(.*)$'
    if p == '#head' then
      head = rest
    elseif p then
      scan[p] = rest
    end
  end
  return scan, head
end

local function scan_remote(c)
  local r = ssh(c, { 'bash', '-s', c.remote, unpack(c.excludes) }, { stdin = REMOTE_SCAN })
  if r.code ~= 0 then
    abort(('无法扫描远端 %s:%s\n%s'):format(c.host, c.remote, vim.trim(r.stderr or '')))
  end
  return parse_scan(vim.split(r.stdout, '\n', { trimempty = true }))
end

local function read_scan(path)
  local lines = read_lines(path)
  return lines and (parse_scan(lines))
end

local function write_scan(path, scan)
  write_lines(path, vim.tbl_map(function(p)
    return p .. '\t' .. scan[p]
  end, sorted_keys(scan)))
end

-- ---------------------------------------------------------------- 集合
-- 集合: { ['./path'] = true }

local function filter(t, pred)
  local s = {}
  for p in pairs(t) do
    if pred(p) then
      s[p] = true
    end
  end
  return s
end

local function inter(a, b)
  return filter(a, function(p) return b[p] end)
end

local function minus(a, b)
  return filter(a, function(p) return not b[p] end)
end

local function union(a, b)
  return vim.tbl_extend('force', {}, a, b)
end

-- 扫描 a 相对 b 的新增、修改、删除；也用来求“两边不一致”的路径
local function changed(a, b)
  return union(filter(a, function(p) return a[p] ~= b[p] end), minus(b, a))
end

-- 把路径集合渲染成 +新增 / M修改 / -删除
local function render(set, base, cur, prefix)
  for _, p in ipairs(sorted_keys(set)) do
    local mark = not base[p] and '+' or not cur[p] and '-' or 'M'
    say(prefix .. mark .. ' ' .. p)
  end
end

local function print_list(set, title, base, cur)
  say('', ('%s  (%d)'):format(title, vim.tbl_count(set)))
  render(set, base, cur, '  ')
end

local function print_plain(set, prefix)
  for _, p in ipairs(sorted_keys(set)) do
    say(prefix .. p)
  end
end

-- ---------------------------------------------------------------- 状态

local function last_sync(c)
  local lines = read_lines(c.state .. '/last')
  return lines and lines[1] or '从未同步'
end

-- 解析 md5sum 输出: { ['./path'] = hash }
local function parse_md5(stdout)
  local hashes = {}
  for line in (stdout or ''):gmatch '[^\n]+' do
    local h, p = line:match '^(%x+)  (.*)$'
    if h then
      hashes[p] = h
    end
  end
  return hashes
end

-- side_diff 只看 size/mtime，会把“内容相同、只是 mtime 不同”的文件误判成两边不一致
-- （典型来源：手工合并冲突、编辑器重写、cp 不带 -p）。这里对两边都有的那批文件——通常
-- 很少——再做一次真实内容校验，只保留内容确实不同的路径。校验失败时保留原判定（宁严勿松）。
local function refine_side_diff(c, side_diff, loc, rem)
  local paths = vim.tbl_filter(function(p)
    return loc[p] and rem[p]
  end, sorted_keys(side_diff))
  if #paths == 0 then
    return side_diff
  end

  local stdin = table.concat(paths, '\n') .. '\n'
  local hash_cmd = "xargs -r -d '\\n' md5sum --"
  local rl = run({ 'sh', '-c', hash_cmd }, { cwd = c.local_dir, stdin = stdin })
  local rr = ssh(c, { 'sh', '-c', ('cd %s && %s'):format(shq(c.remote), hash_cmd) }, { stdin = stdin })
  -- xargs 返回 123 表示 md5sum 对部分文件出错；对应路径没有哈希，按“不同”处理
  if (rl.code ~= 0 and rl.code ~= 123) or (rr.code ~= 0 and rr.code ~= 123) then
    say 'trixi-sync: 警告: 内容校验失败，本次回退到 size/mtime 判定'
    return side_diff
  end

  local hl, hr = parse_md5(rl.stdout), parse_md5(rr.stdout)
  return filter(side_diff, function(p)
    return not (hl[p] and hl[p] == hr[p])
  end)
end

-- pull 留下的冲突名单可能已经手工合并完，只保留仍有差异的条目，免得一直提示
local function prune_conflicts(c, still_diff)
  local path = c.state .. '/conflicts'
  local rec = read_lines(path)
  if not rec or #rec == 0 then
    return
  end
  local keep = vim.tbl_filter(function(p)
    return still_diff[p]
  end, rec)
  if #keep > 0 then
    write_lines(path, keep)
  else
    os.remove(path)
  end
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

  st.cl = changed(st.loc, base_l) -- 本地相对基线的改动
  st.cr = changed(st.rem, base_r) -- 远端相对基线的改动
  local both = inter(st.cl, st.cr)
  local side_diff = refine_side_diff(c, changed(st.loc, st.rem), st.loc, st.rem)

  st.local_only = minus(st.cl, st.cr) -- 待 push
  st.remote_only = minus(st.cr, st.cl) -- 待 pull
  st.conflict = inter(both, side_diff) -- 两边都改过，且内容不同
  st.both_same = minus(both, side_diff) -- 两边改成了同样内容
  -- 两边内容不一样、但各自都没相对基线改动（例如上次 pull 跳过了冲突）
  st.diverged = minus(side_diff, union(st.cl, st.cr))

  prune_conflicts(c, union(st.conflict, st.diverged))
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

-- ---------------------------------------------------------------- 传输

local function refuse_if_diverged(st, o, msg)
  if next(st.diverged) and not o.force then
    say('', msg)
    print_plain(st.diverged, '  ? ')
    abort()
  end
end

local function confirm_delete(o, ndel, where)
  if ndel > 0 and not o.yes then
    say ''
    if not confirm(('确认删除%s以上 %d 个文件?'):format(where, ndel)) then
      abort '已取消'
    end
  end
end

-- 预检 -> 打印计划 -> 确认删除 -> 执行。返回改动的文件数；--dry-run 时返回 nil
local function transfer(c, o, push, filters)
  local loc, rem = c.local_dir .. '/', c.host .. ':' .. c.remote .. '/'
  local src, dst, verb, where, xfer, arrow = loc, rem, '推送', '远端', '<f', '->'
  if not push then
    src, dst, verb, where, xfer, arrow = rem, loc, '拉取', '本地', '>f', '<-'
  end
  -- 规则按先后匹配，所以跳过/保护规则必须排在通用 exclude 之前
  local args = { '--delete', '--itemize-changes' }
  vim.list_extend(args, filters or {})
  vim.list_extend(args, c.rsync_excludes)

  local plan = rsync(c, vim.list_extend({ '-an' }, args), src, dst)
  if plan.code ~= 0 then
    abort('预检失败（ssh/rsync 出错）\n' .. vim.trim(plan.stderr or ''))
  end

  -- 解析 rsync --itemize-changes 的输出
  local items, ntrans, ndel = {}, 0, 0
  for line in plan.stdout:gmatch '[^\n]+' do
    local flag, p = line:match '^(%S+)%s+(.*)$'
    if flag and flag:sub(1, 2) == xfer then
      ntrans = ntrans + 1
      items[#items + 1] = ('  %s %s'):format(arrow, p)
    elseif flag == '*deleting' then
      ndel = ndel + 1
      items[#items + 1] = '  -- ' .. p
    elseif flag and flag:sub(1, 2) == 'cd' then
      items[#items + 1] = '  mk ' .. p
    end
  end
  say('', ('将%s %d 个文件，删除%s %d 个文件'):format(verb, ntrans, where, ndel))
  vim.list_extend(out, items)

  confirm_delete(o, ndel, where)
  if o.dry then
    say('', '(--dry-run，未实际传输)')
    return nil
  end

  -- 不因为“预检计数为 0”而跳过：直接跑一次 rsync 最可靠（无事可做时它本身是空操作）
  local r = rsync(c, vim.list_extend({ '-a' }, args), src, dst)
  if r.code ~= 0 and r.code ~= 24 then -- 24 = 传输期间源文件消失，不算失败
    abort(('rsync 失败 (rc=%d)，基线未更新\n%s'):format(r.code, vim.trim(r.stderr or '')))
  end
  return ntrans + ndel
end

-- ---------------------------------------------------------------- 命令

local cmd = {}

function cmd.status(c)
  local st = collect_status(c)
  say(('远端 %s:%s'):format(c.host, c.remote), ('HEAD %s · 上次同步 %s'):format(st.head or 'none', last_sync(c)), HR)
  print_list(st.local_only, '待 push（本地改过，远端没动）', st.base_l, st.loc)
  print_list(st.remote_only, '待 pull（远端改过，本地没动）', st.base_r, st.rem)
  print_list(st.conflict, '冲突（两边都改过）', st.base_l, st.loc)
  if next(st.diverged) then
    say('', ('两边不一致（需要决定推还是拉）  (%d)'):format(vim.tbl_count(st.diverged)))
    print_plain(st.diverged, '  ? ')
  end
  if next(st.both_same) then
    say('', ('两边改成了同样内容（无需处理）  (%d)'):format(vim.tbl_count(st.both_same)))
  end
  local rec = read_lines(c.state .. '/conflicts') or {}
  if #rec > 0 then
    say('', '上次 pull 遗留的未解决冲突：')
    for _, p in ipairs(rec) do
      say('  ! ' .. p)
    end
    say "  处理完后跑 ':TrixiSync reset' 清除这条记录"
  end
  if not next(st.cl) and not next(st.cr) then
    say('', '两边与基线一致，没有待同步的改动。')
  end
end

function cmd.push(c, o)
  local st = collect_status(c)
  -- 有冲突直接中止（pull 走的是“跳过并记录”）
  if next(st.conflict) then
    say('', ('检测到 %d 个两边都改过的文件，已中止：'):format(vim.tbl_count(st.conflict)))
    render(st.conflict, st.base_l, st.loc, '  ! ')
    say('', "建议用 :DiffRemote 对比后手工合并，然后 ':TrixiSync reset' 再重试。")
    abort()
  end
  if next(st.remote_only) and not o.force then
    say('', '远端自上次同步后有改动，拒绝覆盖（加 -f 可强制）：')
    render(st.remote_only, st.base_r, st.rem, '  ! ')
    abort()
  end
  refuse_if_diverged(st, o, '以下文件两边内容不同，push 会覆盖远端版本（加 -f 继续，或先 pull）：')

  local n = transfer(c, o, true)
  if not n then
    return
  end
  snapshot(c, 'push')
  say('', n == 0 and '远端已是最新。' or ('已推送 -> %s:%s'):format(c.host, c.remote))
  say(('基线已更新 (%s)'):format(last_sync(c)))
end

function cmd.pull(c, o)
  local st = collect_status(c)
  refuse_if_diverged(st, o, '以下文件两边内容不同，pull 会覆盖本地版本（加 -f 继续，或先 push）：')
  if next(st.conflict) then
    say('', ('以下 %d 个文件两边都改过，本次跳过，请手工合并：'):format(vim.tbl_count(st.conflict)))
    render(st.conflict, st.base_l, st.loc, '  ! ')
  end

  -- 冲突文件，以及本地改过但还没 push 的文件，一律 exclude：不被远端旧版本覆盖、
  -- 不被 --delete 删掉，本地删掉的也不会再从远端拉回来（P 只防删除、不防覆盖，所以不能用 P）。
  -- 远端删了整个目录时，rsync 会删掉目录里其它文件、留下非空目录，不需要额外保护目录。
  -- 规则以 / 开头，只匹配这一个路径
  local filters = vim.tbl_map(function(p)
    return '--exclude=/' .. p:sub(3)
  end, sorted_keys(union(st.conflict, st.local_only)))
  if not transfer(c, o, false, filters) then
    return
  end

  -- 把被跳过的冲突记下来，status 会一直提醒，直到 reset
  if next(st.conflict) then
    write_lines(c.state .. '/conflicts', sorted_keys(st.conflict))
  end
  -- 本地还没 push 的改动不进基线，pull 之后它们仍是“待 push”
  snapshot(c, 'pull', st, st.local_only)
  vim.cmd.checktime()
  say('', ('已拉取 <- %s:%s'):format(c.host, c.remote), ('基线已更新 (%s)'):format(last_sync(c)))
end

function cmd.logs(c, o, pat)
  vim.fn.mkdir(c.local_dir .. '/logs', 'p')
  local args = { '-az', '--info=stats1', o.dry and '-n' or nil }
  if pat then
    vim.list_extend(args, { '--include=*/', '--include=*' .. pat .. '*', '--exclude=*' })
  end
  say('拉取 logs/' .. (pat and ('（匹配 *%s*）'):format(pat) or ''))
  local r = rsync(c, args, c.host .. ':' .. c.remote .. '/logs/', c.local_dir .. '/logs/')
  if r.code ~= 0 then
    abort('拉取 logs 失败\n' .. vim.trim(r.stderr or ''))
  end
  say(unpack(vim.split(vim.trim(r.stdout), '\n')))
end

function cmd.init(c, o)
  vim.fn.mkdir(c.local_dir, 'p')
  say(('首次同步 %s:%s -> %s'):format(c.host, c.remote, c.local_dir))
  local args = vim.list_extend({ '-a', '--info=stats1', o.dry and '-n' or nil }, c.rsync_excludes)
  local r = rsync(c, args, c.host .. ':' .. c.remote .. '/', c.local_dir .. '/')
  if r.code ~= 0 then
    abort('首次同步失败\n' .. vim.trim(r.stderr or ''))
  end
  say(unpack(vim.split(vim.trim(r.stdout), '\n')))
  if o.dry then
    say '(--dry-run，未建立基线)'
    return
  end
  snapshot(c, 'init')
  say('', '完成。本地工作目录: ' .. c.local_dir)
  say(("下一步: cd %s && julia --project -e 'using Pkg; Pkg.instantiate()'"):format(c.local_dir))
end

function cmd.reset(c)
  snapshot(c, 'reset')
  os.remove(c.state .. '/conflicts')
  say(('基线已按两边当前状态重建 (%s)'):format(last_sync(c)))
end

-- ---------------------------------------------------------------- 入口

local function parse(fargs)
  local o, args, rest = {}, {}, false
  for _, a in ipairs(fargs) do
    if rest or a:sub(1, 1) ~= '-' then
      args[#args + 1] = a
    elseif a == '--' then
      rest = true
    elseif FLAG_KEYS[a] then
      o[FLAG_KEYS[a]] = true
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
      -- abort() 抛的是 { msg = ... }（msg 可为 nil）；其它都是代码里的意外错误
      local msg
      if type(err) == 'table' then
        msg = err.msg
        level = msg == '已取消' and vim.log.levels.INFO or vim.log.levels.WARN
      else
        msg = tostring(err)
        level = vim.log.levels.ERROR
      end
      if msg then
        say('', 'trixi-sync: ' .. msg)
      end
    end
    show()
    vim.notify(('trixi-sync %s: %s'):format(name, ok and '完成' or '中止'), level)
  end)()
end

function M.complete(arglead, cmdline)
  if arglead:sub(1, 1) == '-' then
    return vim.tbl_filter(function(s)
      return vim.startswith(s, arglead)
    end, M.flags)
  end
  -- 子命令只补第一个位置参数
  for w in cmdline:gmatch '%s(%S+)' do
    if vim.tbl_contains(M.subcommands, w) and w ~= arglead then
      return {}
    end
  end
  return vim.tbl_filter(function(s)
    return vim.startswith(s, arglead)
  end, M.subcommands)
end

return M

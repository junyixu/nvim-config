-- 把 markdown 文本发到 kitty 里跑着的 Claude Code / opencode / pi / codex（不走 nvim 内建终端）
--
-- 不复用 vim-slime 的 kitty target：它把结尾换行作为 "\n" 单独发送，
-- 在 Claude Code 里 "\n" (Ctrl-J) 是插入换行而非提交。这里改为
-- bracketed paste 粘贴正文，稍等片刻再发 "\r" 提交。
--
-- 窗口分类（nvim 自身窗口除外），字段都来自 `kitty @ ls`：
--
--   A. 本地前台进程 (foreground_processes) 的 cmdline 里有 agent
--      如 `claude`、`node …/codex.js`、`kitten ssh host claude`            → 确认是 agent
--   B. 本地前台进程是 ssh
--      B1. kitten ssh：远端自动开启 shell integration（kitty.conf 没禁用时），
--          远端 shell 每次执行命令前用 OSC 133;C 报告命令行
--          - last_reported_cmdline 是 agent 且 at_prompt == false           → 确认是 agent
--          - at_prompt == true（远端已回到提示符）                          → 排除
--          - 其他（alias 启动、远端 tmux 里、二跳 ssh、integration 被禁用）→ 排除
--            （kitten ssh 本该能确认，确认不了多半不是 agent，不去猜）
--      B2. 普通 ssh：远端没有 integration，last_reported_cmdline 停留在本地 shell
--          报告的 `ssh vps`，at_prompt 恒为 false                           → 未确认的 ssh
--          （若在远端手动装了 kitty shell integration，则同 B1，确认不了时仍算未确认）
--   C. 经 zmx 会话跑的 agent：前台进程 cmdline 或 last_reported_cmdline（at_prompt == false）
--      里 `zmx` 之后出现 agent，如 `zmx attach dev claude`、`ssh vps -t 'zmx a dev claude'` → 确认是 agent
--   D. 窗口标题含 ◐ 或 ✳（Claude Code 设置的标题）                          → 确认是 agent
--   E. 其他（本地 zsh、本地 vim……）                                        → 排除，
--      以免把 markdown 当命令执行
--
-- 选择，结果缓存在 b:claude_kitty_window：
--   1. 当前 tab 有确认 agent → 直接选（多个时取最近活动过的，active_window_history）
--   2. 否则提示「当前 tab 没有 agent」，用 vim.ui.select 列出候选让用户挑：
--      所有确认 agent 和所有 ssh 窗口（未确认的也列，确认逻辑可能漏判），
--      当前 tab 在前，其他 tab 里各 OS 窗口当前显示的 tab 优先；最后一项是手动输入 window_id
--      列表走 snacks picker 时，下方只预览光标所在项那一个窗口的当前屏幕（kitty @ get-text）
--
-- 绑定是 buffer 级的，prompt1.md / prompt2.md 可以各发各的窗口。
-- 手动切换用 M.switch（:ClaudeKitty [id]、<space>fc）：跳过第 1 步，总是弹列表
local M = {}

-- paste 结束到发送回车之间的等待，太短 Claude Code 可能吞掉回车
local SUBMIT_DELAY_MS = 100

-- Windows 上只用 neovide --wsl，经 tailscale 控制 archsurface 上的 kitty
local NEOVIDE_KITTY = 'tcp:100.85.19.60:12345'
-- archsurface 关机时不要一直卡住 nvim
local NEOVIDE_TIMEOUT_MS = 3000

-- Linux desktop 上的 neovide 照常走 KITTY_LISTEN_ON
local function remote_kitty()
  return vim.g.neovide and vim.g.is_wsl
end

-- 从桌面启动器打开的 neovide 没有 KITTY_LISTEN_ON；
-- kitty.conf 的 listen_on unix:/tmp/kitty 会被自动加上 -PID，只能 glob 出最新的那个 socket
local function newest_kitty_socket()
  local newest, newest_mtime
  for _, path in ipairs(vim.fn.glob('/tmp/kitty-*', false, true)) do
    local stat = vim.uv.fs_stat(path)
    if stat and stat.type == 'socket' and (not newest_mtime or stat.mtime.sec > newest_mtime) then
      newest, newest_mtime = path, stat.mtime.sec
    end
  end
  return newest and 'unix:' .. newest
end

local function kitty(args, stdin)
  local cmd = { 'kitty', '@' }
  local to = remote_kitty() and NEOVIDE_KITTY or vim.env.KITTY_LISTEN_ON
  if (not to or to == '') and vim.g.neovide then
    to = newest_kitty_socket()
  end
  if to and to ~= '' then
    vim.list_extend(cmd, { '--to', to })
  end
  vim.list_extend(cmd, args)
  return vim.system(cmd, { stdin = stdin, text = true, timeout = remote_kitty() and NEOVIDE_TIMEOUT_MS or nil }):wait()
end

-- 都是 TUI，bracketed paste + 回车提交的行为一致
local AGENTS = { claude = true, opencode = true, pi = true, codex = true }

local function names_agent(word)
  -- npm 装的会是 `node .../bin/codex.js` 这种形式
  return AGENTS[(vim.fs.basename(word):gsub('%.[cm]?js$', ''))] ~= nil
end

--- @return 'kitten'|'plain'|nil
local function ssh_kind(win)
  local kind
  for _, proc in ipairs(win.foreground_processes or {}) do
    local cmdline = proc.cmdline or {}
    local exe = cmdline[1] and vim.fs.basename(cmdline[1])
    -- `kitten ssh host` / `kitty +kitten ssh host`；kitten ssh 自己也会起一个 ssh 子进程，所以 kitten 优先
    if (exe == 'kitten' or exe == 'kitty') and vim.list_contains(cmdline, 'ssh') then
      return 'kitten'
    elseif exe == 'ssh' then
      kind = 'plain'
    end
  end
  return kind
end

-- 包一层再执行真正命令的前缀，如 `env FOO=1 claude`、`exec codex`
local WRAPPERS = { env = true, exec = true, nohup = true, command = true, builtin = true, time = true }

--- shell 报告的命令行里真正执行的程序：跳过 `FOO=bar` 环境变量前缀和 WRAPPERS，
--- 只看第一个词，避免 `vim pi`、`cd claude` 这类参数里出现 agent 名的误判
--- @param cmdline string
--- @return string?
local function command_program(cmdline)
  for word in cmdline:gmatch '%S+' do
    if not word:match '^[%a_][%w_]*=' and not WRAPPERS[word] then
      return word
    end
  end
end

--- 命令行里 `zmx` 之后出现 agent，如 `zmx attach dev claude`；
--- 按空白切词并去掉引号，ssh 把远端命令整个作为一个参数时也能认出
--- @param cmdline string
local function zmx_agent(cmdline)
  local seen_zmx = false
  for word in cmdline:gmatch '%S+' do
    word = word:gsub('^[\'"]+', ''):gsub('[\'"]+$', '')
    if vim.fs.basename(word) == 'zmx' then
      seen_zmx = true
    elseif seen_zmx and names_agent(word) then
      return true
    end
  end
  return false
end

local function is_agent(win)
  local title = win.title or ''
  if title:find('◐', 1, true) or title:find('✳', 1, true) then
    return true
  end
  for _, proc in ipairs(win.foreground_processes or {}) do
    local cmdline = proc.cmdline or {}
    if vim.iter(cmdline):any(names_agent) or zmx_agent(table.concat(cmdline, ' ')) then
      return true
    end
  end
  local remote_cmd = win.last_reported_cmdline
  if win.at_prompt == false and type(remote_cmd) == 'string' and zmx_agent(remote_cmd) then
    return true
  end
  if ssh_kind(win) and win.at_prompt == false and type(remote_cmd) == 'string' then
    local program = command_program(remote_cmd)
    return program ~= nil and names_agent(program)
  end
  return false
end

--- 当前 tab 在前，其余 tab 里各 OS 窗口当前显示的 (is_active) 优先，再按 kitty 的 tab 顺序
--- @return table? current, table[] others
local function list_tabs()
  local res = kitty { 'ls' }
  if res.code ~= 0 then
    vim.notify('claude_kitty: `kitty @ ls` failed: ' .. vim.trim(res.stderr or ''), vim.log.levels.WARN)
    return nil, {}
  end
  local ok, os_windows = pcall(vim.json.decode, res.stdout)
  if not ok then
    vim.notify('claude_kitty: cannot parse `kitty @ ls` output', vim.log.levels.WARN)
    return nil, {}
  end

  local current, others = nil, {}
  for _, os_win in ipairs(os_windows) do
    for _, tab in ipairs(os_win.tabs) do
      local has_self = vim.iter(tab.windows):any(function(w)
        return w.is_self
      end)
      if has_self then
        current = tab
      else
        table.insert(others, tab)
      end
    end
  end
  -- table.sort 不稳定，用原序号保持 kitty 的 tab 顺序
  for i, tab in ipairs(others) do
    tab._order = i
  end
  table.sort(others, function(a, b)
    if (a.is_active == true) ~= (b.is_active == true) then
      return a.is_active == true
    end
    return a._order < b._order
  end)
  return current, others
end

--- tab 里除自身外的窗口，最近活动的排前面
local function candidates(tab)
  local recency = {}
  for i, id in ipairs(tab.active_window_history or {}) do
    recency[id] = i
  end
  local wins = vim.tbl_filter(function(w)
    return not w.is_self
  end, tab.windows)
  table.sort(wins, function(a, b)
    return (recency[a.id] or 0) > (recency[b.id] or 0)
  end)
  return wins
end

local function describe(tab, win, is_current)
  local kind = is_agent(win) and 'agent' or ({ kitten = 'kitten ssh', plain = 'ssh' })[ssh_kind(win) or ''] or 'local'
  local cmd = type(win.last_reported_cmdline) == 'string' and win.last_reported_cmdline or ''
  return ('%s #%d [%s] %s  %s'):format(is_current and 'this tab' or ('tab ' .. (tab.title or tab.id)), win.id, kind, win.title or '', cmd)
end

--- @param guess? { id: integer, label: string } 最可能的窗口，作为默认值
local function ask_id(cb, guess)
  local prompt = 'kitty window_id: '
  if guess then
    prompt = ('most likely: %s\nkitty window_id: '):format(guess.label)
  end
  local id = tonumber(vim.fn.input(prompt, guess and tostring(guess.id) or ''))
  if id then
    cb(id)
  end
end

--- snacks picker 的预览函数：用终端 buffer 显示窗口当前屏幕，保留 get-text --ansi 的颜色
--- 必须走 kitty()：snacks 的 preview.cmd 在 pty 里跑，`kitty @` 经 tty 找不到 kitty
--- @param texts table<integer, string> 按 window_id 缓存，光标来回移动时不重复请求
local function preview_window(ctx, texts)
  local id = ctx.item.item.id
  if not id then
    return ctx.preview:reset() -- 「手动输入」那一项没有对应窗口
  end
  if not texts[id] then
    local res = kitty { 'get-text', '--ansi', '--match', 'id:' .. id }
    if res.code ~= 0 then
      return ctx.preview:notify('`kitty @ get-text` failed: ' .. vim.trim(res.stderr or ''), 'warn', { item = false })
    end
    texts[id] = res.stdout:gsub('%s+$', ''):gsub('\r?\n', '\r\n')
  end
  local buf = ctx.preview:scratch()
  vim.api.nvim_chan_send(vim.api.nvim_open_term(buf, {}), texts[id])
end

--- 列出候选让用户挑；用户取消则不调用 done
--- @param current table?
--- @param others table[]
--- @param done fun(id: integer)
--- @param warning? string 弹列表前的提示
local function pick(current, others, done, warning)
  local items = {}
  local tabs = vim.list_extend(current and { current } or {}, others)
  for _, tab in ipairs(tabs) do
    for _, win in ipairs(candidates(tab)) do
      if is_agent(win) or ssh_kind(win) then
        table.insert(items, { id = win.id, label = describe(tab, win, tab == current) })
      end
    end
  end
  -- 最可能的：列表第一项，没有就取当前 tab 里上一个活动窗口
  local guess = items[1]
  if not guess and current then
    local prev = candidates(current)[1]
    if prev then
      guess = { id = prev.id, label = describe(current, prev, true) }
    end
  end
  if #items == 0 then
    return ask_id(done, guess)
  end
  table.insert(items, { label = 'enter window_id manually', guess = guess })

  if warning then
    vim.notify(warning, vim.log.levels.WARN)
  end
  local texts = {}
  vim.ui.select(items, {
    prompt = 'Send to kitty window',
    snacks = {
      layout = {
        preset = 'vertical',
        layout = { width = 0.8, height = 0.9 },
        -- 列表高度随项数，其余都给预览
        config = function(layout)
          for _, box in ipairs(layout.layout) do
            if box.win == 'list' then
              box.height = math.min(#items, 10)
            elseif box.win == 'preview' then
              box.height = nil
            end
          end
        end,
      },
      preview = function(ctx)
        preview_window(ctx, texts)
      end,
    },
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if not item then
      return
    end
    if item.id then
      done(item.id)
    else
      ask_id(done, item.guess)
    end
  end)
end

--- @param force? boolean 忽略缓存重新确定
--- @param cb fun(id: integer) 确定了目标窗口才会调用；用户取消则不调用
function M.window(force, cb)
  -- vim.ui.select 是异步的，回调时当前 buffer 可能已经换了
  local buf = vim.api.nvim_get_current_buf()
  local function done(id)
    vim.b[buf].claude_kitty_window = id
    cb(id)
  end

  if not force and vim.b[buf].claude_kitty_window then
    return cb(vim.b[buf].claude_kitty_window)
  end

  local current, others = list_tabs()
  if current then
    for _, win in ipairs(candidates(current)) do
      if is_agent(win) then
        return done(win.id)
      end
    end
  end

  pick(current, others, done, 'claude_kitty: no agent detected in this tab, pick a window')
end

--- 手动切换当前 buffer 绑定的窗口；当前 tab 有 agent 时也不自动选
--- @param id? integer 直接绑定到这个 window_id，省略则弹列表
function M.switch(id)
  local buf = vim.api.nvim_get_current_buf()
  local function done(new_id)
    vim.b[buf].claude_kitty_window = new_id
    vim.notify('claude_kitty: target window ' .. new_id)
  end

  if id then
    return done(id)
  end
  local current, others = list_tabs()
  pick(current, others, done)
end

local function send_text(id, text)
  return kitty({ 'send-text', '--match', 'id:' .. id, '--stdin' }, text).code == 0
end

local function paste_and_submit(id, payload)
  if not send_text(id, payload) then
    return false
  end
  vim.defer_fn(function()
    send_text(id, '\r')
  end, SUBMIT_DELAY_MS)
  return true
end

--- @param text string
function M.send(text)
  text = text:gsub('%s+$', '')
  if text == '' then
    return
  end

  local payload = '\27[200~' .. text .. '\27[201~'
  M.window(false, function(id)
    if paste_and_submit(id, payload) then
      return
    end
    -- 缓存的窗口可能已关闭，重新确定一次再试
    M.window(true, function(new_id)
      if not paste_and_submit(new_id, payload) then
        vim.notify('claude_kitty: failed to send to kitty window ' .. new_id, vim.log.levels.WARN)
      end
    end)
  end)
end

local saved_cursor

--- operatorfunc；不带参数调用时设置 operatorfunc 并返回 'g@'，用于 expr 映射
--- @param type? 'line'|'char'|'block'
function M.operator(type)
  if type == nil then
    saved_cursor = vim.api.nvim_win_get_cursor(0)
    vim.o.operatorfunc = "v:lua.require'custom.claude_kitty'.operator"
    return 'g@'
  end

  local mode = ({ line = 'V', char = 'v', block = '\22' })[type]
  local lines = vim.fn.getregion(vim.fn.getpos "'[", vim.fn.getpos "']", { type = mode })
  if saved_cursor then
    pcall(vim.api.nvim_win_set_cursor, 0, saved_cursor)
    saved_cursor = nil
  end
  M.send(table.concat(lines, '\n'))
end

function M.send_visual()
  local lines = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  M.send(table.concat(lines, '\n'))
end

return M

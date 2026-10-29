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
--   C. 其他（本地 zsh、本地 vim……）                                        → 排除，
--      以免把 markdown 当命令执行
--
-- 选择顺序，结果缓存在 b:claude_kitty_window：
--   1. 当前 tab 的确认 agent
--   2. 当前 tab 的未确认 ssh
--   3. 其他 tab 的确认 agent
--   4. 其他 tab 的未确认 ssh
--   5. 都没有就手动输入 window_id
-- 其他 tab 里，各 OS 窗口当前显示的 tab (is_active) 优先，其余按 kitty 的 tab 顺序。
-- 同一 tab 里有多个时取最近活动过的那个（active_window_history）。
local M = {}

-- paste 结束到发送回车之间的等待，太短 Claude Code 可能吞掉回车
local SUBMIT_DELAY_MS = 100

local function kitty(args, stdin)
  local cmd = { 'kitty', '@' }
  if vim.env.KITTY_LISTEN_ON and vim.env.KITTY_LISTEN_ON ~= '' then
    vim.list_extend(cmd, { '--to', vim.env.KITTY_LISTEN_ON })
  end
  vim.list_extend(cmd, args)
  return vim.system(cmd, { stdin = stdin, text = true }):wait()
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

local function is_agent(win)
  for _, proc in ipairs(win.foreground_processes or {}) do
    if vim.iter(proc.cmdline or {}):any(names_agent) then
      return true
    end
  end
  local remote_cmd = win.last_reported_cmdline
  if ssh_kind(win) and win.at_prompt == false and type(remote_cmd) == 'string' then
    return vim.iter(remote_cmd:gmatch '%S+'):any(names_agent)
  end
  return false
end

--- 普通 ssh 看不到远端进程，只能猜；已确认回到提示符的除外
local function is_guessable(win)
  return ssh_kind(win) == 'plain' and win.at_prompt ~= true
end

--- @return integer? window_id
local function detect_window()
  local res = kitty { 'ls' }
  if res.code ~= 0 then
    return nil
  end
  local ok, os_windows = pcall(vim.json.decode, res.stdout)
  if not ok then
    return nil
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
  -- 各 OS 窗口当前显示的 tab 优先；table.sort 不稳定，用原序号保持 kitty 的 tab 顺序
  for i, tab in ipairs(others) do
    tab._order = i
  end
  table.sort(others, function(a, b)
    if (a.is_active == true) ~= (b.is_active == true) then
      return a.is_active == true
    end
    return a._order < b._order
  end)

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

  --- @param tabs table[]
  --- @param pred fun(win: table): boolean
  local function pick(tabs, pred)
    for _, tab in ipairs(tabs) do
      for _, win in ipairs(candidates(tab)) do
        if pred(win) then
          return win.id
        end
      end
    end
  end

  local here = { current }
  return pick(here, is_agent) or pick(here, is_guessable) or pick(others, is_agent) or pick(others, is_guessable)
end

--- @param force? boolean 忽略缓存重新确定
--- @return integer? window_id
function M.window(force)
  if not force and vim.b.claude_kitty_window then
    return vim.b.claude_kitty_window
  end
  local id = detect_window() or tonumber(vim.fn.input 'kitty window_id: ')
  vim.b.claude_kitty_window = id
  return id
end

local function send_text(id, text)
  return kitty({ 'send-text', '--match', 'id:' .. id, '--stdin' }, text).code == 0
end

--- @param text string
function M.send(text)
  text = text:gsub('%s+$', '')
  if text == '' then
    return
  end

  local id = M.window()
  local payload = '\27[200~' .. text .. '\27[201~'
  -- 缓存的窗口可能已关闭，重新确定一次再试
  if id and not send_text(id, payload) then
    id = M.window(true)
    if id and not send_text(id, payload) then
      id = nil
    end
  end
  if not id then
    vim.notify('claude_kitty: no kitty window to send to', vim.log.levels.WARN)
    return
  end

  vim.defer_fn(function()
    send_text(id, '\r')
  end, SUBMIT_DELAY_MS)
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

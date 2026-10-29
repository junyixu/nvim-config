-- 把 markdown 文本发到 kitty 里跑着的 Claude Code / opencode / pi / codex（不走 nvim 内建终端）
--
-- 不复用 vim-slime 的 kitty target：它把结尾换行作为 "\n" 单独发送，
-- 在 Claude Code 里 "\n" (Ctrl-J) 是插入换行而非提交。这里改为
-- bracketed paste 粘贴正文，稍等片刻再发 "\r" 提交。
--
-- 目标窗口按以下顺序确定，结果缓存在 b:claude_kitty_window：
--   1. 当前 tab 里确认在跑 AGENTS 之一的窗口：本地前台进程就是 agent，或者是 ssh 窗口、
--      且远端 shell integration（kitten ssh 默认开启）报告的命令是 agent 并且还没回到提示符
--   2. 当前 tab 里的 ssh 窗口（普通 ssh 看不到远端进程，只能猜），已确认回到提示符的除外
--   3. 其他 tab 里确认在跑 agent 的窗口（同 1 的判定，不做 2 那样的猜测）
--   4. 找不到就手动输入 window_id
-- 同一 tab 里有多个时取最近活动过的那个（active_window_history）。
-- 不会选本地 shell 窗口，以免把 markdown 当命令执行
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

local function is_ssh(win)
  for _, proc in ipairs(win.foreground_processes or {}) do
    local cmdline = proc.cmdline or {}
    local exe = cmdline[1] and vim.fs.basename(cmdline[1])
    -- `ssh host` / `kitten ssh host` / `kitty +kitten ssh host`
    if exe == 'ssh' or ((exe == 'kitten' or exe == 'kitty') and vim.list_contains(cmdline, 'ssh')) then
      return true
    end
  end
  return false
end

local function is_agent(win)
  for _, proc in ipairs(win.foreground_processes or {}) do
    if vim.iter(proc.cmdline or {}):any(names_agent) then
      return true
    end
  end
  local remote_cmd = win.last_reported_cmdline
  if is_ssh(win) and win.at_prompt == false and type(remote_cmd) == 'string' then
    return vim.iter(remote_cmd:gmatch '%S+'):any(names_agent)
  end
  return false
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

  if current then
    local wins = candidates(current)
    for _, win in ipairs(wins) do
      if is_agent(win) then
        return win.id
      end
    end
    for _, win in ipairs(wins) do
      if is_ssh(win) and win.at_prompt ~= true then
        return win.id
      end
    end
  end

  -- 别的 tab 只认确认在跑 agent 的窗口，不猜 ssh 窗口
  for _, tab in ipairs(others) do
    for _, win in ipairs(candidates(tab)) do
      if is_agent(win) then
        return win.id
      end
    end
  end
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

-- 把 markdown 文本发到 kitty 里跑着的 Claude Code / opencode / pi / codex（不走 nvim 内建终端）
--
-- 不复用 vim-slime 的 kitty target：它把结尾换行作为 "\n" 单独发送，
-- 在 Claude Code 里 "\n" (Ctrl-J) 是插入换行而非提交。这里改为
-- bracketed paste 粘贴正文，稍等片刻再发 "\r" 提交。
--
-- 目标窗口按以下顺序确定，结果缓存在 b:claude_kitty_window：
--   1. 前台进程是 AGENTS 之一的窗口：当前 tab 优先，其次其他 tab；
--      有多个时取最近活动过的那个（active_window_history）
--   2. 找不到就手动输入 window_id
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

local function is_agent(win)
  for _, proc in ipairs(win.foreground_processes or {}) do
    for _, arg in ipairs(proc.cmdline or {}) do
      -- npm 装的会是 `node .../bin/codex.js` 这种形式
      if AGENTS[vim.fs.basename(arg):gsub('%.[cm]?js$', '')] then
        return true
      end
    end
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

  -- 只认跑着 agent 的窗口；当前 tab 优先，同一 tab 内越近活动越优先
  local best, best_rank
  for _, os_win in ipairs(os_windows) do
    for _, tab in ipairs(os_win.tabs) do
      local recency = {}
      for i, id in ipairs(tab.active_window_history or {}) do
        recency[id] = i
      end
      local is_current = vim.iter(tab.windows):any(function(w)
        return w.is_self
      end)

      for _, win in ipairs(tab.windows) do
        if not win.is_self and is_agent(win) then
          local rank = (is_current and 1e6 or 0) + (recency[win.id] or 0)
          if not best_rank or rank > best_rank then
            best, best_rank = win.id, rank
          end
        end
      end
    end
  end
  return best
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

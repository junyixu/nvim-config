local job_id = 0
local term_bufnr = nil
local term_width = 80

-- - ftplugin/julia.lua now keeps a registry of Julia REPL jobs/buffers, scrolls any
--     live terminal window via scroll_buf_to_bottom(), and cleans registry entries
--     when a terminal dies. <space>st still spawns the REPL on the right, but every
--     time the window is shown we reapply the width and push the cursor to the bottom
--     so the view tails the next chunk of output.
--   - Every time <space>st runs we seed b:slime_config with the REPL’s job id/pid
--     and register that job id in the global table, so we know exactly which terminal
--     buffer belongs to a given slime target.
--   - Added a guarded SlimeOverrideSend (see ftplugin/julia.lua) which still calls
--     the configured target’s send function but, if a jobid is present, invokes the
--     Lua helper JuliaSlimeAfterSend. That helper schedules a non-disruptive scroll
--     of the mapped terminal window, so each slime send repositions the cursor at
--     the last line and keeps Neovim’s terminal in “follow” mode (per usr/share/nvim/
--     runtime/doc/terminal.txt:14, the emulator only tails output while the cursor
--     sits on the final line).
--
--   Notes
--
--   - I didn’t find any mention of this behavior in vim-slime’s docs; web results
--     such as kassio/neoterm#156 describe the same “terminal freezes on old output”
--     symptom and point back to Neovim’s rule that only the last-line cursor keeps
--     the PTY tailing. The new override implements that rule automatically for every
--     slime send without stealing focus or reopening the terminal.
--   - Verify by opening a Julia buffer, hit <space>st, send code with your slime
--     mappings, and watch the right-side REPL stay pinned to the newest line even
--     after you manually scroll up; hiding/reopening with <M-=> still restores the
--     session at the bottom.
--
--   Next: if you ever need different behavior for non-Julia slime targets, remove or
--   adjust the override block in ftplugin/julia.lua; otherwise you’re good to start
--   REPL-driven work with the new auto-follow.

_G.__julia_term_registry = _G.__julia_term_registry or {}
local term_registry = _G.__julia_term_registry

local function register_term(job, bufnr)
  if job and job > 0 and bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    term_registry[job] = bufnr
  end
end

local function scroll_buf_to_bottom(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 })
end

local function configure_slime_job(bufnr)
  if not job_id or job_id <= 0 then
    return
  end

  local ok_existing, existing = pcall(vim.api.nvim_buf_get_var, bufnr, 'slime_config')
  local config = {}
  if ok_existing and type(existing) == 'table' then
    config = existing
  end

  config.jobid = job_id

  local ok_pid, pid = pcall(vim.fn.jobpid, job_id)
  if ok_pid and type(pid) == 'number' and pid > 0 then
    config.pid = pid
  end

  vim.api.nvim_buf_set_var(bufnr, 'slime_config', config)
  register_term(job_id, term_bufnr)
end

local function ensure_term_running()
  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    return true
  end

  if job_id > 0 then
    term_registry[job_id] = nil
  end
  job_id = 0
  term_bufnr = nil
  vim.notify('Julia terminal is not running yet', vim.log.levels.INFO, { title = 'ftplugin/julia.lua' })
  return false
end

local function show_term_window()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, term_width)
    scroll_buf_to_bottom(term_bufnr)
    return
  end

  vim.cmd 'botright vsplit'
  vim.cmd.wincmd 'L'
  vim.api.nvim_win_set_buf(0, term_bufnr)
  vim.api.nvim_win_set_width(0, term_width)
  scroll_buf_to_bottom(term_bufnr)
  vim.cmd.wincmd 'p'
end

local function hide_term_window()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win == -1 then
    return
  end

  if #vim.api.nvim_list_wins() == 1 then
    vim.notify('Cannot hide the Julia terminal when it is the only window', vim.log.levels.WARN, { title = 'ftplugin/julia.lua' })
    return
  end

  vim.api.nvim_win_close(win, true)
end

local function toggle_term_window()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win == -1 then
    show_term_window()
  else
    hide_term_window()
  end
end

vim.keymap.set('n', '<space>st', function()
  local source_buf = vim.api.nvim_get_current_buf()
  vim.cmd 'botright vsplit'
  vim.cmd.wincmd 'L'
  vim.cmd.term()
  term_bufnr = vim.api.nvim_get_current_buf()
  -- send `julia --project=.` to the terminal to start a julia REPL
  vim.api.nvim_win_set_width(0, term_width)
  scroll_buf_to_bottom(term_bufnr)
  job_id = vim.bo.channel
  vim.fn.chansend(job_id, { 'julia --banner=no --project=.\r\n' })
  configure_slime_job(source_buf)
  vim.cmd.wincmd 'p'
end, { buffer = true, desc = 'open a term' })

vim.keymap.set('n', '<M-=>', function()
  toggle_term_window()
end, { buffer = true, desc = 'toggle julia term' })

if not _G.JuliaSlimeAfterSend then
  _G.JuliaSlimeAfterSend = function(target_job)
    local parsed_job = tonumber(target_job)
    if not parsed_job then
      return
    end

    local bufnr = term_registry[parsed_job]
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
      term_registry[parsed_job] = nil
      return
    end

    vim.schedule(function()
      scroll_buf_to_bottom(bufnr)
    end)
  end

  vim.cmd [[
    function SlimeOverrideSend(config, text) abort
      let l:target = slime#config#resolve('target')
      execute 'call slime#targets#' . l:target . '#send(a:config, a:text)'
      if has_key(a:config, 'jobid')
        call v:lua.JuliaSlimeAfterSend(a:config['jobid'])
      endif
    endfunction
  ]]
end

local job_id = 0
local term_bufnr = nil
local term_width = 80

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
end

local function ensure_term_running()
  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    return true
  end

  vim.notify('Julia terminal is not running yet', vim.log.levels.INFO, { title = 'ftplugin/julia.lua' })
  return false
end

local function scroll_term_to_bottom(win)
  if not term_bufnr or not vim.api.nvim_buf_is_valid(term_bufnr) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(term_bufnr)
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end

local function show_term_window()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, term_width)
    scroll_term_to_bottom(win)
    return
  end

  vim.cmd 'botright vsplit'
  vim.cmd.wincmd 'L'
  vim.api.nvim_win_set_buf(0, term_bufnr)
  vim.api.nvim_win_set_width(0, term_width)
  scroll_term_to_bottom(0)
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
  scroll_term_to_bottom(0)
  job_id = vim.bo.channel
  vim.fn.chansend(job_id, { 'julia --banner=no --project=.\r\n' })
  configure_slime_job(source_buf)
  vim.cmd.wincmd 'p'
end, { buffer = true, desc = 'open a term' })

vim.keymap.set('n', '<M-=>', function()
  toggle_term_window()
end, { buffer = true, desc = 'toggle julia term' })

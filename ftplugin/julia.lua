local job_id = 0
local term_bufnr = nil
local term_width = 80

local function ensure_term_running()
  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    return true
  end

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
    return
  end

  vim.cmd 'botright vsplit'
  vim.cmd.wincmd 'L'
  vim.api.nvim_win_set_buf(0, term_bufnr)
  vim.api.nvim_win_set_width(0, term_width)
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
  vim.cmd 'botright vsplit'
  vim.cmd.wincmd 'L'
  vim.cmd.term()
  term_bufnr = vim.api.nvim_get_current_buf()
  -- send `julia --project=.` to the terminal to start a julia REPL
  vim.api.nvim_win_set_width(0, term_width)
  job_id = vim.bo.channel
  vim.fn.chansend(job_id, { 'julia --banner=no --project=.\r\n' })
  vim.cmd.wincmd 'p'
end, { buffer = true, desc = 'open a term' })

vim.keymap.set('n', '<M-=>', function()
  toggle_term_window()
end, { buffer = true, desc = 'toggle julia term' })

local job_id = 0
local term_bufnr = nil

local function open_or_focus_term()
  if not term_bufnr or not vim.api.nvim_buf_is_valid(term_bufnr) then
    vim.notify('Julia terminal is not running yet', vim.log.levels.INFO, { title = 'ftplugin/julia.lua' })
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, 20)
    return
  end

  vim.cmd 'botright vsplit'
  vim.api.nvim_win_set_buf(0, term_bufnr)
  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_width(0, 30)
end
vim.keymap.set('n', '<space>st', function()
  vim.cmd.new()
  vim.cmd.term()
  term_bufnr = vim.api.nvim_get_current_buf()
  vim.cmd.wincmd 'J'
  -- send `julia --project=.` to the terminal to start a julia REPL
  vim.api.nvim_win_set_height(0, 5)
  job_id = vim.bo.channel
  vim.fn.chansend(job_id, { 'julia --banner=no --project=.\r\n' })
  vim.cmd.wincmd 'p'
end, { buffer = true, desc = 'open a term' })

vim.keymap.set('n', '<M-=>', function()
  open_or_focus_term()
end, { buffer = true, desc = 'focus julia term' })

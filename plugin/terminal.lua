local job_id = 0
vim.keymap.set('n', '<space>st', function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_height(0, 5)
  job_id = vim.bo.channel
end)
vim.keymap.set('n', '<space>ss', function()
  vim.fn.chansend(job_id, { 'ls -la\r\n' })
end)

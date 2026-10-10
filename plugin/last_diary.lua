-- Diary navigation entry points. Only stubs live here; the implementation in
-- lua/junyi/last_diary.lua is required on first use.

if vim.g.loaded_last_diary then
  return
end
vim.g.loaded_last_diary = true

local function nav(fn)
  return function()
    require('junyi.last_diary')[fn]()
  end
end

vim.api.nvim_create_user_command('DiaryPrev', nav 'prev', { desc = 'Open previous diary entry' })
vim.api.nvim_create_user_command('DiaryNext', nav 'next', { desc = 'Open next diary entry' })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('LastDiary', { clear = true }),
  pattern = 'markdown',
  callback = function(args)
    vim.keymap.set('n', '<localleader>p', nav 'prev', { buffer = args.buf, silent = true, desc = 'Previous diary entry' })
    vim.keymap.set('n', '<localleader>n', nav 'next', { buffer = args.buf, silent = true, desc = 'Next diary entry' })
  end,
})

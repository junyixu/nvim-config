-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = vim.api.nvim_create_augroup('QuickfixHeightAdjustment', { clear = true }),
  pattern = { 'vimgrep', 'grep' }, -- 匹配 vimgrep 和 grep 命令
  callback = function()
    local qf_items = vim.fn.getqflist()
    if #qf_items == 0 then
      return
    end
    local height = tostring(math.min(#qf_items, 15))
    vim.cmd('cwindow ' .. height)
  end,
})

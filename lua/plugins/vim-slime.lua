-- jpalardy/vim-slime – send code to REPLs

return {
  'jpalardy/vim-slime',
  init = function()
    vim.g.slime_target = 'neovim'
  end,
  config = function()
    vim.g.slime_suggest_default = true
    vim.g.slime_menu_config = false
    vim.g.slime_input_pid = false

    vim.keymap.set('n', '<Leader>s', '<Plug>SlimeMotionSend', { remap = true, desc = 'Slime: Send Motion' })
    vim.keymap.set('n', '<Leader>ss', '<Plug>SlimeLineSend', { remap = true, desc = 'Slime: Send Line' })
    vim.keymap.set('n', '<Leader>sp', '<Plug>SlimeParagraphSend', { remap = true, desc = 'Slime: Send Paragraph' })
    vim.keymap.set('v', '<Leader>s', '<Plug>SlimeRegionSend', { remap = true, desc = 'Slime: Send Region' })
    vim.keymap.set('n', '<Leader>sc', '<Plug>SlimeConfig', { remap = true, desc = 'Slime: Configure Target' })
  end,
}

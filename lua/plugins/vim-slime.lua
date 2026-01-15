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

    vim.keymap.set('n', '<space><space>', '<Plug>SlimeMotionSend', { remap = true, desc = 'Slime: Send Motion' })
    vim.keymap.set('n', '<space><space><space>', '<Plug>SlimeLineSend', { remap = true, desc = 'Slime: Send Line' })
    vim.keymap.set('n', '<space><space>p', '<Plug>SlimeParagraphSend', { remap = true, desc = 'Slime: Send Paragraph' })
    vim.keymap.set('v', '<space><space>', '<Plug>SlimeRegionSend', { remap = true, desc = 'Slime: Send Region' })
    vim.keymap.set('n', '<space><space>c', '<Plug>SlimeConfig', { remap = true, desc = 'Slime: Configure Target' })
  end,
}

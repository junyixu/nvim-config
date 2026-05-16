-- ~/.config/nvim/ftplugin/typst.lua
vim.keymap.set('n', '<leader>tp', function()
  local client = vim.lsp.get_clients({ name = 'tinymist', bufnr = 0 })[1]
  if not client then
    vim.notify('tinymist not attached', vim.log.levels.WARN)
    return
  end
  client:exec_cmd({ command = 'tinymist.startDefaultPreview', title = 'Preview' })
end, { buffer = 0, desc = 'Typst preview' })

-- gO: 通过 snacks picker 跳转 typst 标题 (tinymist 文档符号)
vim.keymap.set('n', 'gO', function()
  require('snacks').picker.lsp_symbols {
    layout = 'dropdown',
    tree = true,
  }
end, { buffer = 0, desc = 'Typst headings (snacks)' })

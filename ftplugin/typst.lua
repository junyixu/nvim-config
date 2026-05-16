-- gO: 通过 snacks picker 跳转 typst 标题 (tinymist 文档符号)
vim.keymap.set('n', 'gO', function()
  require('snacks').picker.lsp_symbols {
    layout = 'dropdown',
    tree = true,
  }
end, { buffer = 0, desc = 'Typst headings (snacks)' })

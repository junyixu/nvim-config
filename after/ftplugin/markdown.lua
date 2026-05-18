vim.keymap.set('i', '<CR>', function()
  local ok, mod = pcall(require, 'custom.markdown_smart_cr')
  if not ok then
    return vim.api.nvim_replace_termcodes('<CR>', true, false, true)
  end
  return mod.smart_cr()
end, { expr = true, buffer = true, silent = true })

-- gO: 通过 snacks picker 跳转 markdown 标题
-- 放 after/ftplugin 以覆盖 Neovim 内置 runtime/ftplugin/markdown.lua 的 gO (treesitter._headings.show_toc)
vim.keymap.set('n', 'gO', function()
  require('snacks').picker.lsp_symbols {
    layout = 'dropdown',
    tree = true,
  }
end, { buffer = 0, desc = 'Markdown headings (snacks)' })

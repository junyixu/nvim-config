-- ~/.config/nvim/lsp/tinymist.lua (Neovim 0.11+ 原生 LSP 配置约定)
return {
  cmd = { 'tinymist' },
  filetypes = { 'typst' },
  root_markers = { 'typst.toml', '.git' },
  settings = {
    formatterMode = 'typstyle',   -- 或 'typstfmt'
    formatterPrintWidth = 100,
    exportPdf = 'never',          -- 'onType' / 'onSave' / 'onDocumentHasTitle' / 'never'
    semanticTokens = 'enable',
  },
}

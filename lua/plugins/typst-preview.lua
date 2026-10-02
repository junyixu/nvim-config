return {
  'chomosuke/typst-preview.nvim',
  enabled = vim.g.full,
  ft = 'typst',
  version = '1.*',
  opts = {
    invert_colors = 'auto',
    dependencies_bin = { tinymist = 'tinymist' }, -- use system tinymist (Typst 0.15) instead of the bundled one
  }, -- lazy.nvim will implicitly calls `setup {}`
}

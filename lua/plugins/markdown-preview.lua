-- Browser preview for markdown; `mkdp#util#install()` fetches a prebuilt binary, so no yarn/npm needed
return {
  'iamcco/markdown-preview.nvim',
  enabled = vim.g.full,
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  build = function()
    -- lazy-loaded via ft/cmd, so put it on rtp first or the autoload function is undefined (E117)
    require('lazy').load { plugins = { 'markdown-preview.nvim' } }
    vim.fn['mkdp#util#install']()
  end,
}

-- quarto-dev/quarto-nvim – Quarto IDE support

return {
  'quarto-dev/quarto-nvim',
  ft = { 'quarto' },
  dependencies = {
    'jmbuhr/otter.nvim',
    'nvim-treesitter/nvim-treesitter',
    'jpalardy/vim-slime',
  },
  config = function()
    local quarto = require 'quarto'
    quarto.setup {
      debug = false,
      closePreviewOnExit = true,
      lspFeatures = {
        enabled = true,
        chunks = 'curly',
        languages = { 'python', 'julia', 'lua' },
        diagnostics = { enabled = true, triggers = { 'BufWritePost' } },
        completion = { enabled = true },
      },
      codeRunner = {
        enabled = true,
        default_method = 'slime',
        ft_runners = {},
        never_run = { 'yaml' },
      },
    }
    vim.keymap.set('n', '<leader>qp', quarto.quartoPreview, { silent = true, noremap = true })
  end,
}

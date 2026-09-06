return {
  {
    'stevearc/aerial.nvim',
    lazy = true,
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialClose', 'AerialInfo' },
    keys = {
      { '<leader>ta', '<cmd>AerialToggle<CR>', desc = 'Toggle Aerial' },
    },
    opts = {
      filter_kind = {
        ['_'] = { 'Class', 'Constructor', 'Enum', 'Function', 'Interface', 'Module', 'Method', 'Struct' },
        typst = { 'Namespace' },
      },
    },
    -- Optional dependencies
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
  },
}

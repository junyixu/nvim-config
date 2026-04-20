return {
  {
    'stevearc/aerial.nvim',
    lazy = true,
    cmd = { 'AerialToggle', 'AerialOpen', 'AerialClose', 'AerialInfo' },
    keys = {
      { '<leader>ta', '<cmd>AerialToggle<CR>', desc = 'Toggle Aerial' },
    },
    opts = {},
    -- Optional dependencies
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
  },
}

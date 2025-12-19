-- lewis6991/gitsigns.nvim – Git signs in the gutter
-- lua/plugins/gitsigns.lua

return {
  'lewis6991/gitsigns.nvim',
  lazy = false,
  opts = {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
  },
  -- 重点：使用 gitsigns.nav_hunk()
  keys = {
    {
      '<leader>hs',
      function()
        require('gitsigns').stage_hunk()
      end,
      mode = { 'n', 'v' },
      desc = 'Stage Hunk',
    },
    {
      '<leader>hr',
      function()
        require('gitsigns').reset_hunk()
      end,
      mode = { 'n', 'v' },
      desc = 'Reset Hunk',
    },
    {
      '<leader>hp',
      function()
        require('gitsigns').preview_hunk()
      end,
      desc = 'Preview Hunk',
    },
    {
      '<leader>gb',
      function()
        require('gitsigns').toggle_current_line_blame()
      end,
      desc = 'Toggle Current Line Blame',
    },
  },
}

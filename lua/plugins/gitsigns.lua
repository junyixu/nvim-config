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
  keys = {
    {
      ']c',
      function()
        require('gitsigns').nav_hunk 'next'
      end,
      desc = 'Next Git Hunk',
    },
    {
      '[c',
      function()
        require('gitsigns').nav_hunk 'prev'
      end,
      desc = 'Previous Git Hunk',
    },
    -- 模仿 mini.diff: ghgh (Stage Hunk)
    {
      'ghgh',
      function()
        require('gitsigns').stage_hunk()
      end,
      desc = 'Stage Hunk',
    },

    {
      'ghh',
      function()
        require('gitsigns').stage_hunk { vim.fn.line '.', vim.fn.line '.' }
      end,
      mode = { 'n' },
      desc = 'Stage Hunk',
    },

    {
      'gHH',
      function()
        require('gitsigns').reset_hunk { vim.fn.line '.', vim.fn.line '.' }
      end,
      mode = { 'n' },
      desc = 'Reset Hunk',
    },

    {
      'gHgh',
      function()
        require('gitsigns').reset_hunk()
      end,
      desc = 'Reset Hunk',
    },

    -- Visual Mode 下直接用 gh Stage 选中的范围
    {
      'gh',
      function()
        require('gitsigns').stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end,
      mode = { 'x' },
      desc = 'Stage Selected Range',
    },

    {
      'gH',
      function()
        require('gitsigns').reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end,
      mode = { 'x' },
      desc = 'Reset Selected Range',
    },

    -- 定义 gh 作为 Operator-pending textobject (支持 dgh, ygh 等)
    {
      'gh',
      ':<C-U>Gitsigns select_hunk<CR>',
      mode = { 'o' },
      desc = 'Git Hunk Text Object',
    },
    {
      'ghp',
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

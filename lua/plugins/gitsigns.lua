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
    -- 1. 跳转到下一个 Hunk (使用 ]g)
    {
      ']c',
      function()
        require('gitsigns').nav_hunk 'next'
      end,
      desc = 'Next Git Hunk',
    },
    -- 2. 跳转到上一个 Hunk (使用 [g)
    {
      '[c',
      function()
        require('gitsigns').nav_hunk 'prev'
      end,
      desc = 'Previous Git Hunk',
    },
    -- 推荐添加的 Hunk 操作（保持不变，因为它们没有被弃用）
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

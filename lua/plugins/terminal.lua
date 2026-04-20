return {
  {
    'willothy/flatten.nvim',
    config = true,
    -- or pass configuration with
    opts = {
      window = {
        open = 'split',
        diff = 'tab_vsplit',
        focus = 'first',
      },
    },
    -- Ensure that it runs first to minimize delay when opening file from terminal
    lazy = false,
    priority = 1001,
  },
}

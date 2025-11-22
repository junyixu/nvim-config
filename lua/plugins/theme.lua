-- Theme configuration

return {
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    'ellisonleao/gruvbox.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    config = function()
      require('gruvbox').setup {
        italic = {
          strings = false,
          comments = false,
          operators = false,
        },
      }

      -- Load the colorscheme here.
      -- Gruvbox has 'gruvbox' with dark/light controlled by vim.o.background
      vim.cmd.colorscheme 'gruvbox'
    end,
  },
}

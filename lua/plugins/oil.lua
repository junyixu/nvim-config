return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    dependencies = { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    lazy = false,

    config = function(_, opts)
      require('oil').setup {
        columns = {
          'icon',
          -- "permissions",
          -- "size",
          -- 'mtime',
        },
        keymaps = {
          ['gd'] = function()
            require('oil').set_columns { 'icon', 'permissions', 'size', 'mtime' }
          end,
          -- You can pass additional opts to vim.keymap.set by using
          -- a table with the mapping as the first element.
          ['<leader>ff'] = {
            function()
              local ok, snacks = pcall(require, 'snacks')
              if not ok or not snacks.picker then
                return
              end
              snacks.picker.files { cwd = require('oil').get_current_dir() }
            end,
            mode = 'n',
            nowait = true,
            desc = 'Find files in the current directory',
          },
          -- Mappings that are a string starting with "actions." will be
          -- one of the built-in actions, documented below.
          -- ['`'] = 'actions.tcd',
          -- Some actions have parameters. These are passed in via the `opts` key.
          ['<leader>:'] = {
            'actions.open_cmdline',
            opts = {
              shorten_path = true,
              modify = ':h',
            },
            desc = 'Open the command line with the current directory as an argument',
          },
        },
      }
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    end,
  },
}

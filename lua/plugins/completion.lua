-- Autoformat and autocompletion plugins

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>F',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
    },
  },

  { -- Autocompletion
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'folke/lazydev.nvim',
      'micangl/cmp-vimtex',
    },
    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
      },

      appearance = {
        nerd_font_variant = 'mono',
      },

      completion = {
        -- By default, you may press `<c-space>` to show the documentation.
        -- Optionally, set `auto_show = true` to show the documentation after a delay.
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
      },

      sources = {
        default = { 'lsp', 'path', 'cmdline', 'lazydev', 'snippets' },
        -- default = { 'lsp', 'path', 'cmdline', 'lazydev', 'snippets' },
        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
        snippets = {
          score_offset = 1,
        },
      },

      opts_extend = { 'sources.default' },
      snippets = { preset = 'luasnip' },

      -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
      -- which automatically downloads a prebuilt binary when enabled.
      --
      -- By default, we use the Lua implementation instead, but you may enable
      -- the rust implementation via `'prefer_rust_with_warning'`
      --
      -- See :h blink-cmp-config-fuzzy for more information
      fuzzy = { implementation = 'prefer_rust_with_warning' },

      -- Shows a signature help window while you type arguments for a function
      signature = { enabled = true },
    },
  },

  {
    'iurimateus/luasnip-latex-snippets.nvim',
    -- vimtex isn't required if using treesitter
    dependencies = {
      'L3MON4D3/LuaSnip',
      {
        'lervag/vimtex',
        lazy = false, -- Set to false to always load VimTeX, or true for lazy loading based on filetype
        -- tag = "v2.15", -- Optional: uncomment to pin to a specific release
        init = function()
          -- Place your VimTeX-specific global configurations here
          vim.g.vimtex_view_method = 'zathura' -- Example: set your preferred viewer
          -- Add other VimTeX configurations as needed
        end,
        ft = 'tex', -- Optional: lazy load only for .tex files if `lazy = true`
      },
    },
    config = function()
      require('luasnip-latex-snippets').setup { use_treesitter = true, allow_on_markdown = true }
    end,
  },
  {
    'L3MON4D3/LuaSnip',
    version = '2.*',
    build = (function()
      -- Build Step is needed for regex support in snippets.
      -- This step is not supported in many windows environments.
      -- Remove the below condition to re-enable on windows.
      if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
        return
      end
      return 'make install_jsregexp'
    end)(),
    dependencies = {
      -- `friendly-snippets` contains a variety of premade snippets.
      --    See the README about individual language/framework/plugin snippets:
      --    https://github.com/rafamadriz/friendly-snippets
      -- {
      --   'rafamadriz/friendly-snippets',
      --   config = function()
      --     require('luasnip.loaders.from_vscode').lazy_load()
      --   end,
      -- },
    },
    config = function()
      -- Load snippets from ~/.config/nvim/luasnippets/
      -- require('luasnip.loaders.from_lua').load { paths = vim.fn.stdpath 'config' .. '/luasnippets' }

      local ls = require 'luasnip'
      local filetype_funcs = require 'luasnip.extras.filetype_functions'

      ls.setup {
        update_events = { 'TextChanged', 'TextChangedI' },
        enable_autosnippets = true,
        store_selection_keys = '<Tab>',
        -- Use treesitter to determine filetype at cursor position
        -- This allows snippets to work correctly in injected regions (e.g., code blocks in Quarto)
        ft_func = filetype_funcs.from_cursor_pos,

        -- Load additional filetypes for Quarto files
        load_ft_func = filetype_funcs.extend_load_ft {
          quarto = { 'markdown', 'r', 'julia', 'python' },
        },
      }
      vim.keymap.set({ 'i' }, '<C-f>', function()
        ls.expand()
      end, { silent = true, desc = 'expand autocomplete' })
      vim.keymap.set({ 'i', 's' }, '<Tab>', function()
        ls.jump(1)
      end, { silent = true, desc = 'next autocomplete' })
      vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
        ls.jump(-1)
      end, { silent = true, desc = 'previous autocomplete' })
      vim.keymap.set({ 'i', 's' }, '<C-E>', function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true, desc = 'select autocomplete' })
    end,
  },
  {
    'micangl/cmp-vimtex',
    ft = 'tex',
    config = function()
      require('cmp_vimtex').setup {}
    end,
  },
  {
    'saghen/blink.compat',
    version = '*',
    opts = { impersonate_nvim_cmp = false },
  },
}

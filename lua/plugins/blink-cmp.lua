-- saghen/blink.cmp – main completion engine

return {
  'saghen/blink.cmp',
  dependencies = { 'archie-judd/blink-cmp-words' },
  lazy = true,
  event = 'VimEnter',
  version = '1.*',
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = {
      -- NOTE: Keep Blink's default preset but let the plain Neovim mappings in
      -- plugin/luasnip.vim own <Tab>/<S-Tab>, so snippet expansion/jumps still
      -- work even when the completion menu is visible.
      preset = 'default',
      ['<Tab>'] = false,
      ['<S-Tab>'] = false,
      ['<C-f>'] = false,
      ['<C-b>'] = false,
      ['<C-e>'] = false,
      ['<C-u>'] = { 'scroll_signature_up', 'fallback' },
      ['<C-d>'] = { 'scroll_signature_down', 'fallback' },

      -- default in all keymap presets
      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
      ['<A-1>'] = {
        function(cmp)
          cmp.accept { index = 1 }
        end,
      },
      ['<A-2>'] = {
        function(cmp)
          cmp.accept { index = 2 }
        end,
      },
      ['<A-3>'] = {
        function(cmp)
          cmp.accept { index = 3 }
        end,
      },
      ['<A-4>'] = {
        function(cmp)
          cmp.accept { index = 4 }
        end,
      },
      ['<A-5>'] = {
        function(cmp)
          cmp.accept { index = 5 }
        end,
      },
      ['<A-6>'] = {
        function(cmp)
          cmp.accept { index = 6 }
        end,
      },
      ['<A-7>'] = {
        function(cmp)
          cmp.accept { index = 7 }
        end,
      },
      ['<A-8>'] = {
        function(cmp)
          cmp.accept { index = 8 }
        end,
      },
      ['<A-9>'] = {
        function(cmp)
          cmp.accept { index = 9 }
        end,
      },
      ['<A-0>'] = {
        function(cmp)
          cmp.accept { index = 10 }
        end,
      },
    },
    completion = {
      -- 禁用补全函数的自动括号
      accept = {
        auto_brackets = {
          enabled = false,
        },
      },
      documentation = { auto_show = true, auto_show_delay_ms = 2000 },
      -- ghost_text = {
      --   enabled = true,
      --   show_with_menu = false, -- only show when menu is closed
      -- },

      -- want to set the following options
      menu = {
        -- auto_show = false, -- only show menu on manual <C-space>
        draw = {
          treesitter = { 'lsp' },
          columns = { { 'item_idx' }, { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
          components = {
            item_idx = {
              text = function(ctx)
                return ctx.idx == 10 and '0' or ctx.idx >= 10 and ' ' or tostring(ctx.idx)
              end,
              -- highlight = 'BlinkCmpItemIdx', -- optional, only if you want to change its color
            },
          },
        },
      },
    },
    sources = {
      default = { 'lsp', 'path', 'cmdline', 'lazydev', 'snippets' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        thesaurus = {
          name = 'blink-cmp-words',
          module = 'blink-cmp-words.thesaurus',
          -- All available options
          opts = {
            -- A score offset applied to returned items.
            -- By default the highest score is 0 (item 1 has a score of -1, item 2 of -2 etc..).
            score_offset = 0,

            -- Default pointers define the lexical relations listed under each definition,
            -- see Pointer Symbols below.
            -- Default is as below ("antonyms", "similar to" and "also see").
            definition_pointers = { '!', '&', '^' },

            -- The pointers that are considered similar words when using the thesaurus,
            -- see Pointer Symbols below.
            -- Default is as below ("similar to", "also see" }
            similarity_pointers = { '&', '^' },

            -- The depth of similar words to recurse when collecting synonyms. 1 is similar words,
            -- 2 is similar words of similar words, etc. Increasing this may slow results.
            similarity_depth = 2,
          },
        },
      },
      per_filetype = {
        codecompanion = { 'codecompanion' },
        markdown = { 'lsp', 'thesaurus' },
        tex = { 'lsp', 'thesaurus' },
      },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
  },
}

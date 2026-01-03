return {
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'master', -- 关键：手动指定旧分支
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('nvim-treesitter.configs').setup {
        textobjects = {
          select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ['am'] = '@function.outer',
              ['im'] = '@function.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',

              ['ak'] = { query = '@block.outer', desc = 'Select around block (begin/end)' },
              ['ik'] = { query = '@block.inner', desc = 'Select inner block body' },

              ['al'] = { query = '@loop.outer', desc = 'Select around loop' },
              ['il'] = { query = '@loop.inner', desc = 'Select inner loop' },

              ['ix'] = '@codechunk.inner',
              ['ax'] = '@codechunk.outer',

              ['ad'] = { query = '@conditional.outer', desc = 'Select around conditional (if/end)' },
              ['id'] = { query = '@conditional.inner', desc = 'Select inner conditional body' },

              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              -- You can also use captures from other query groups like `locals.scm`
              -- ['as'] = { query = '@local.scope', query_group = 'locals', desc = 'Select language scope' },
              -- You can choose the select mode (default is charwise 'v')
              --
              -- Can also be a function which gets passed a table with the keys
              -- * query_string: eg '@function.inner'
              -- * method: eg 'v' or 'o'
              -- and should return the mode ('v', 'V', or '<c-v>') or a table
              -- mapping query_strings to modes.
            },
            selection_modes = {
              ['@block.outer'] = 'V', -- begin...end 按行选
              ['@loop.outer'] = 'V', -- 循环按行选
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V', -- linewise
              ['@class.outer'] = '<c-v>', -- blockwise
              ['@conditional.outer'] = 'v',
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true or false
            -- include_surrounding_whitespace = false,
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              [']m'] = '@function.outer',
              [']]'] = { query = '@class.outer', desc = 'Next class start' },
              --
              -- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queries.
              [']l'] = '@loop.outer', -- 对应 al
              [']k'] = '@block.outer', -- 对应 ak
              [']a'] = '@parameter.inner', --以此类推
              [']i'] = '@conditional.outer', -- if else
              -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
              -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
              -- [']s'] = { query = '@local.scope', query_group = 'locals', desc = 'Next scope' },
              [']z'] = { query = '@fold', query_group = 'folds', desc = 'Next fold' },
            },
            goto_next_end = {
              [']M'] = '@function.outer',
              [']['] = '@class.outer',
              [']L'] = '@loop.outer',
              [']K'] = '@block.outer',
              [']I'] = '@conditional.outer', -- if else
            },
            goto_previous_start = {
              ['[m'] = '@function.outer',
              ['[l'] = '@loop.outer',
              ['[k'] = '@block.outer',
              ['[i'] = '@conditional.outer',
              ['[['] = {
                query = { '@class.outer', '@text.title' },
                desc = 'Prev class or heading',
              },
            },
            goto_previous_end = {
              ['[M'] = '@function.outer',
              ['[L'] = '@loop.outer',
              ['[K'] = '@block.outer',
              ['[]'] = '@class.outer',
              ['[I'] = '@conditional.outer', -- if else
            },
            -- Below will go to either the start or the end, whichever is closer.
            -- Use if you want more granular movements
            -- Make it even more gradual by adding multiple queries and regex.
            goto_next = {
              -- [']i'] = '@conditional.outer', -- if else
            },
            goto_previous = {
              -- ['[i'] = '@conditional.outer',
            },
          },
        },
      }
    end,
  },
}

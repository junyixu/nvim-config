return {
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    init = function()
      -- 禁用内置 ftplugin 映射以避免冲突（Julia 等语言可能有内置映射）
      vim.g.no_plugin_maps = true
    end,
    config = function()
      local select = require 'nvim-treesitter-textobjects.select'
      local move = require 'nvim-treesitter-textobjects.move'

      -- 1. 功能配置
      require('nvim-treesitter-textobjects').setup {
        select = {
          enable = true, -- 注意：最新 README 没写 enable，但 main 分支逻辑建议保留或根据报错调整
          lookahead = true,
          selection_modes = {
            ['@function.outer'] = 'v',
            ['@class.outer'] = 'V',
            ['@block.outer'] = 'V',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
        },
      }

      -- 2. 手动绑定 Select 映射 (Visual & Operator-pending 模式)
      local select_maps = {
        ['am'] = '@function.outer',
        ['im'] = '@function.inner',
        ['al'] = '@class.outer',
        ['il'] = '@class.inner',
        ['ak'] = '@block.outer',
        ['ik'] = '@block.inner',
        ['ir'] = '@frame.inner',
        ['ar'] = '@frame.outer',
        ['ao'] = '@loop.outer',
        ['io'] = '@loop.inner',
        ['ad'] = '@conditional.outer',
        ['id'] = '@conditional.inner',
        ['ix'] = '@codechunk.inner', -- Quarto run cell
        ['ax'] = '@codechunk.outer',
      }

      for key, query in pairs(select_maps) do
        vim.keymap.set({ 'x', 'o' }, key, function()
          select.select_textobject(query, 'textobjects')
        end)
      end

      -- 3. 手动绑定 Move 映射 (Normal, Visual, Operator-pending)
      local move_maps = {
        [']m'] = { query = '@function.outer', func = move.goto_next_start },
        [']M'] = { query = '@function.outer', func = move.goto_next_end },
        ['[m'] = { query = '@function.outer', func = move.goto_previous_start },
        ['[M'] = { query = '@function.outer', func = move.goto_previous_end },
        [']]'] = { query = '@class.outer', func = move.goto_next_start },
        ['[['] = { query = '@class.outer', func = move.goto_previous_start },
        [']o'] = { query = '@loop.outer', func = move.goto_next_start },
        [']O'] = { query = '@loop.outer', func = move.goto_next_end },
        ['[o'] = { query = '@loop.outer', func = move.goto_previous_start },
        ['[O'] = { query = '@loop.outer', func = move.goto_previous_end },
        [']k'] = { query = '@block.outer', func = move.goto_next_start },
        [']K'] = { query = '@block.outer', func = move.goto_next_end },
        ['[k'] = { query = '@block.outer', func = move.goto_previous_start },
        ['[K'] = { query = '@block.outer', func = move.goto_previous_end },
        [']i'] = { query = '@conditional.outer', func = move.goto_next_start },
        [']I'] = { query = '@conditional.outer', func = move.goto_next_end },
        ['[i'] = { query = '@conditional.outer', func = move.goto_previous_start },
        ['[I'] = { query = '@conditional.outer', func = move.goto_previous_end },
        ['[f'] = { query = '@call.outer', func = move.goto_previous_start },
        [']f'] = { query = '@call.outer', func = move.goto_next_start },
      }

      for key, conf in pairs(move_maps) do
        vim.keymap.set({ 'n', 'x', 'o' }, key, function()
          conf.func(conf.query, 'textobjects')
        end)
      end
    end,
  },
}

-- echasnovski/mini.nvim – assorted UI helpers

return {
  'nvim-mini/mini.nvim',
  config = function()
    local ai = require 'mini.ai'
    ai.setup {
      -- custom_textobjects = {
      --   -- camelCase / snake_case subword (doc example from mini-ai.txt)
      --   v = {
      --     {
      --       '__*[%l%d]+%f[^%l%d]',
      --       '%u[%l%d]+%f[^%l%d]',
      --       '%f[%S][%l%d]+%f[^%l%d]',
      --       '%f[%w][%l%d]+%f[^%l%d]',
      --       '^[%l%d]+%f[^%l%d]',
      --     },
      --     '^(%_*)().*()(%_*)$',
      --   },
      -- },
      custom_textobjects = {
        -- camelCase / snake_case subword (doc example from mini-ai.txt)
        v = {
          {
            '%u[%l%d]+%f[^%l%d]',
            '%f[%S][%l%d]+%f[^%l%d]',
            '%f[%P][%l%d]+%f[^%l%d]',
            '^[%l%d]+%f[^%l%d]',
          },
          '^().*()$',
        },
        a = require('mini.ai').gen_spec.argument { separator = '%s*[,;]%s*' },
      },
      n_lines = 50,
    }
    require('mini.surround').setup {
      custom_surroundings = {
        ['('] = { output = { left = '( ', right = ' )' } },
        ['['] = { output = { left = '[ ', right = ' ]' } },
        ['{'] = { output = { left = '{ ', right = ' }' } },
        ['<'] = { output = { left = '< ', right = ' >' } },
      },
      mappings = {
        add = 'ys',
        delete = 'ds',
        find = '',
        find_left = '',
        highlight = '',
        replace = 'cs',
        update_n_lines = '',
      },
      search_method = 'cover_or_next',
    }

    -- 'ys' is also mapped in Visual mode by mini.surround, so remove it to keep regular Visual 'y' instant
    pcall(vim.keymap.del, 'x', 'ys')

    vim.api.nvim_set_keymap('x', 's', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { noremap = true })
    vim.api.nvim_set_keymap('n', 'yss', 'ys_', { noremap = false })

    require('mini.pairs').setup {
      modes = { insert = true, command = false, terminal = false },
      mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[%a\\].' },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^`\\].' },
        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^"\\].' },
      },
    }

    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}

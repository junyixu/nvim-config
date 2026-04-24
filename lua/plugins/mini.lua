return {
  'nvim-mini/mini.nvim',
  config = function()
    local ai = require 'mini.ai'

    local function gen_subword_regions(ai_type, opts)
      local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
      local n_lines = (opts and opts.n_lines) or 50

      local last_line = vim.api.nvim_buf_line_count(0)
      local from_line = math.max(1, cursor_row - n_lines)
      local to_line = math.min(last_line, cursor_row + n_lines)

      local function is_lower(c)
        return c:match '%l' ~= nil
      end
      local function is_upper(c)
        return c:match '%u' ~= nil
      end
      local function is_digit(c)
        return c:match '%d' ~= nil
      end
      local function is_sep(c)
        return c == '_'
      end

      local function split_subwords(token)
        local segments = {}
        local i = 1
        local n = #token
        while i <= n do
          while i <= n and is_sep(token:sub(i, i)) do
            i = i + 1
          end
          if i > n then
            break
          end

          local seg_start = i
          local j = i
          while j <= n do
            local cur = token:sub(j, j)
            local nxt = (j < n) and token:sub(j + 1, j + 1) or nil
            local nxt2 = (j + 1 < n) and token:sub(j + 2, j + 2) or nil

            if nxt == nil or is_sep(nxt) then
              break
            end

            if (is_lower(cur) or is_digit(cur)) and is_upper(nxt) then
              break
            end
            if is_upper(cur) and is_upper(nxt) and (nxt2 ~= nil and is_lower(nxt2)) then
              break
            end

            j = j + 1
          end

          table.insert(segments, { start_idx = seg_start, end_idx = j })
          i = j + 1
        end
        return segments
      end

      local res = {}

      for row = from_line, to_line do
        local line = vim.fn.getline(row)
        local init = 1
        while init <= #line do
          local token_start, token_end = line:find('[%a%d_]+', init)
          if not token_start then
            break
          end

          local token = line:sub(token_start, token_end)
          if token:find '[%a%d]' then
            for _, seg in ipairs(split_subwords(token)) do
              local left, right = seg.start_idx, seg.end_idx

              if ai_type == 'a' then
                while left > 1 and is_sep(token:sub(left - 1, left - 1)) do
                  left = left - 1
                end
                while right < #token and is_sep(token:sub(right + 1, right + 1)) do
                  right = right + 1
                end
              end

              table.insert(res, {
                from = { line = row, col = token_start + left - 1 },
                to = { line = row, col = token_start + right - 1 },
              })
            end
          end

          init = token_end + 1
        end
      end

      return (#res > 0) and res or nil
    end

    ai.setup {
      custom_textobjects = {
        i = require('mini.extra').gen_ai_spec.indent(),
        a = ai.gen_spec.argument { brackets = { '%b()', '%b{}' }, separator = '%s*[,;]%s*' },
        v = gen_subword_regions,
      },
      n_lines = 100,
      mappings = {
        around_next = '',
        inside_next = '',
        around_last = '',
        inside_last = '',
      },
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
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\][^%w%.]' },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^`\\].' },
        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^"\\].' },
      },
    }

    local statusline = require 'mini.statusline'
    statusline.setup {
      use_icons = vim.g.have_nerd_font,
      content = {
        inactive = function()
          return string.format('%%#MiniStatuslineInactive#%%F%%= [%d] ', vim.fn.winnr())
        end,
      },
    }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}

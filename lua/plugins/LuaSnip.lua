-- L3MON4D3/LuaSnip – snippet engine

return {
  'L3MON4D3/LuaSnip',
  version = '2.*',
  event = 'InsertEnter',
  keys = {
    {
      '<leader>es',
      function()
        local filetype = vim.bo.filetype
        if filetype == 'quarto' or filetype == 'markdown' then
          filetype = 'tex'
        end
        local snippet_path = vim.fn.stdpath 'config' .. '/luasnippets/' .. filetype .. '.lua'
        vim.cmd('vsplit ' .. snippet_path)
      end,
      mode = 'n',
      desc = 'auto pick filetype and edit the snippet',
    },
  },
  build = (function()
    if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
      return
    end
    return 'make install_jsregexp'
  end)(),
  config = function()
    require('luasnip.loaders.from_lua').load { paths = vim.fn.stdpath 'config' .. '/luasnippets' }
    local ls = require 'luasnip'
    local filetype_funcs = require 'luasnip.extras.filetype_functions'
    local types = require 'luasnip.util.types'

    ls.setup {
      update_events = { 'TextChanged', 'TextChangedI' },
      enable_autosnippets = true,
      store_selection_keys = '<tab>',
      ft_func = filetype_funcs.from_cursor_pos,
      load_ft_func = filetype_funcs.extend_load_ft {
        quarto = { 'markdown', 'r', 'julia', 'python' },
      },
      ext_opts = {
        [types.choiceNode] = {
          active = {
            virt_text = { { '<- Current Choice', 'DiagnosticHint' } },
            virt_text_pos = 'eol', -- optional, defaults to eol
          },
          passive = {
            virt_text = { { '<- Choice Node', 'Comment' } },
          },
        },
      },
    }

    -- Treesitter returns `markdown_inline` for normal text regions, so make sure the
    -- regular markdown snippets are still considered there.
    ls.filetype_extend('markdown_inline', { 'markdown' })

    local function unlink_if_active()
      if ls.in_snippet() then
        ls.unlink_current()
      end
    end

    vim.keymap.set({ 'i', 's' }, '<Esc>', function()
      unlink_if_active()
      return '<Esc>'
    end, { expr = true, silent = true, desc = 'leave insert/select and unlink LuaSnip snippet' })

    vim.keymap.set({ 'i', 's' }, '<C-c>', function()
      unlink_if_active()
      return '<Esc>'
    end, { expr = true, silent = true, desc = 'leave insert/select and unlink LuaSnip snippet' })

    -- vim.keymap.set({ 'i' }, '<Tab>', function()
    --   if ls.expand_or_jumpable() then
    --     ls.expand()
    --     return ''
    --   else
    --     return '<TAB>'
    --   end
    -- end, { silent = true, desc = 'expand autocomplete' })
    --
    -- vim.keymap.set({ 'i', 's' }, '<C-f>', function()
    --   ls.jump(1)
    -- end, { silent = true, desc = 'next autocomplete' })
    --
    -- vim.keymap.set({ 'i', 's' }, '<C-b>', function()
    --   ls.jump(-1)
    -- end, { silent = true, desc = 'previous autocomplete' })
    --
    -- vim.keymap.set({ 'i', 's' }, '<C-E>', function()
    --   if ls.choice_active() then
    --     ls.change_choice(1)
    --   end
    -- end, { silent = true, desc = 'select autocomplete' })
  end,
}

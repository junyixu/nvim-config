-- L3MON4D3/LuaSnip – snippet engine

return {
  'L3MON4D3/LuaSnip',
  version = '2.*',
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

    ls.setup {
      update_events = { 'TextChanged', 'TextChangedI' },
      enable_autosnippets = true,
      store_selection_keys = '<Tab>',
      ft_func = filetype_funcs.from_cursor_pos,
      load_ft_func = filetype_funcs.extend_load_ft {
        quarto = { 'markdown', 'r', 'julia', 'python' },
      },
    }

    vim.keymap.set({ 'n' }, '<leader>es', function()
      local filetype = vim.bo.filetype
      if filetype == 'quarto' then
        filetype = 'markdown'
      end
      local snippet_path = vim.fn.stdpath 'config' .. '/lua/luasnippets/' .. filetype .. '.lua'
      vim.cmd('vsplit ' .. snippet_path)
    end, { silent = true, desc = 'auto pick filetype and edit the snippet' })

    vim.keymap.set({ 'i' }, '<Tab>', function()
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
}

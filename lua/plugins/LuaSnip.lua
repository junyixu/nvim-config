-- L3MON4D3/LuaSnip – snippet engine

return {
  'L3MON4D3/LuaSnip',
  version = '2.*',
  lazy = true,
  event = 'ModeChanged',
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
      -- 根据 Tree‑sitter 判断光标所在区域的 “局部 filetype”
      -- 在普通 markdown 段落里，Tree‑sitter 会把该区域标成 markdown_inline
      -- 而不是 buffer 的 markdown。
      --  LuaSnip 展开 snippet 时只看 ft_func 返回的列表；
      --  如果它拿到的是 markdown_inline，
      --  而 snippet 只注册在 markdown，
      --  就会查不到，
      --  即便 :set filetype? 显示的是 markdown。
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
    -- 作用: 告诉 LuaSnip：
    -- 当 Tree‑sitter 给出 markdown_inline 时，也把 markdown 这套 snippet 加进来，
    -- 这样 markdown 文档里正常段落也能继续使用 markdown snippets。
    -- 所以即使 buffer 的 filetype 是 markdown，
    -- 只要你启用了 Tree‑sitter 的 from_cursor_pos，
    -- 就必须补这一行，确保 Tree‑sitter 返回的子 filetype 也能继承 markdown 的 snippet 集合。

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

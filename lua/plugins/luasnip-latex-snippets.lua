-- iurimateus/luasnip-latex-snippets – LaTeX snippets backed by treesitter

return {
  'iurimateus/luasnip-latex-snippets.nvim',
  dependencies = {
    'L3MON4D3/LuaSnip',
  },
  config = function()
    require('luasnip-latex-snippets').setup { use_treesitter = true, allow_on_markdown = true }
  end,
}

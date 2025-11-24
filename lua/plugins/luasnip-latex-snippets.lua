-- iurimateus/luasnip-latex-snippets – LaTeX snippets backed by treesitter

return {
  'iurimateus/luasnip-latex-snippets.nvim',
  dependencies = {
    'L3MON4D3/LuaSnip',
    {
      'lervag/vimtex',
      lazy = false,
      init = function()
        vim.g.vimtex_view_method = 'zathura'
      end,
      ft = 'tex',
    },
  },
  config = function()
    require('luasnip-latex-snippets').setup { use_treesitter = true, allow_on_markdown = true }
  end,
}

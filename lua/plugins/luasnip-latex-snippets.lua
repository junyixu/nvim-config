-- iurimateus/luasnip-latex-snippets – LaTeX snippets backed by treesitter

return {
  'iurimateus/luasnip-latex-snippets.nvim',
  dependencies = {
    'L3MON4D3/LuaSnip',
  },
  opts = {
    use_treesitter = true,
    allow_on_markdown = true,
  },
  config = function(_, opts)
    require('luasnip-latex-snippets').setup(opts)

    local ls = require 'luasnip'
    local utils = require 'luasnip-latex-snippets.util.utils'

    -- true 表示走 treesitter；如果想让 vimtex 判定就改成 false
    local is_math = utils.with_opts(utils.is_math, true)
    local not_math = utils.with_opts(utils.not_math, true)

    -- 常规 math snippet
    local math_i = require('luasnip-latex-snippets.math_i').retrieve(is_math)
    local math_iA = require('luasnip-latex-snippets.math_iA').retrieve(is_math)
    ls.add_snippets('tex', math_i, { default_priority = 0 })
    ls.add_snippets('tex', math_iA, { default_priority = 0 })

    -- autosnippet：把所有 math_iA/... 的结果合并
    local autos = {}
    local function extend(modname, fn)
      vim.list_extend(autos, require('luasnip-latex-snippets.' .. modname).retrieve(fn))
    end
    extend('math_iA', is_math)
    extend('math_iA_no_backslash', is_math)
    extend('math_rA_no_backslash', is_math)
    extend('math_wRA_no_backslash', is_math)
    extend('math_wrA', is_math)
    extend('math_wA_no_backslash', is_math)
    extend('wA', not_math)
    extend('bwA', not_math)

    for _, snip in ipairs(autos) do
      snip.hidden = true
    end

    ls.add_snippets('tex', autos, { type = 'autosnippets', default_priority = 0 })
  end,
}

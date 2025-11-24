local ls = require 'luasnip'
local ts_utils = require 'luasnip-latex-snippets.util.ts_utils'
local is_math = ts_utils.in_mathzone

local t = ls.text_node
local i = ls.insert_node
local s = ls.snippet

local snip_table = {
  s('mat', {
    t { '\\begin{bmatrix}', '' },
    i(1),
    t { '', '\\end{bmatrix}' },
  }, {
    condition = is_math,
    show_condition = is_math,
  }),

  -- Julia code block
  s('jl', {
    t { '```{julia}', '' },
    i(1),
    t { '', '```' },
  }),
}

return snip_table

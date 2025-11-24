local ls = require 'luasnip'

local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

local inline_math = ls.parser.parse_snippet({ trig = 'mk', name = 'Math', priority = 10, snippetType = 'autosnippet' }, '$ ${1:${TM_SELECTED_TEXT}} $$0')

local snip_table = {
  -- python code block
  s('py', {
    t { '```{python}', '' },
    i(1),
    t { '', '```' },
  }),

  -- Julia code block
  s('jl', {
    t { '```{julia}', '' },
    i(1),
    t { '', '```' },
  }),
  inline_math,
}

return snip_table

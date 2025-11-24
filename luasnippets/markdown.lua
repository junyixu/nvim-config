-- Quarto snippets
-- LuaSnip will automatically load s, t, i, etc. from snip_env

-- Check if cursor is in LaTeX math environment
-- local ls = require 'luasnip'
local utils = require 'luasnip-latex-snippets.util.utils'
local not_math = utils.not_math() -- pass true if using Treesitter
local is_math = utils.is_math()

-- set a higher priority (defaults to 0 for most snippets)
-- local snip = ls.parser.parse_snippet({ trig = 'mk', name = 'Math', condition = not_math, priority = 10 }, '$ ${1:${TM_SELECTED_TEXT}} $$0')
--
-- ls.add_snippets('tex', { snip }, {
--   type = 'autosnippets',
-- })

return {
  -- R code block
  s('r', {
    t { '```{r}', '' },
    i(1),
    t { '', '```' },
  }),

  -- Julia code block
  s('j', {
    t { '```{julia}', '' },
    i(1),
    t { '', '```' },
  }),

  -- LaTeX bmatrix (only in math environment)
  s('mat', {
    t { '\\begin{bmatrix}', '\t' },
    i(1),
    t { '', '\\end{bmatrix}' },
  }, {
    condition = is_math,
  }),
}

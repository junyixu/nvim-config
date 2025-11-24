-- Markdown/Quarto snippets
-- LuaSnip will automatically load s, t, i, etc. from snip_env

local ts_utils = require 'luasnip-latex-snippets.util.ts_utils'
local is_math = ts_utils.in_mathzone

-- local is_math = ts_utils.in_mathzone
-- local function is_math()
--   return vim.api.nvim_eval 'vimtex#syntax#in_mathzone()' == 1
-- end

return {
  -- Python code block
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

  -- LaTeX bmatrix

  s('mat', {
    t { '\\begin{bmatrix}', '\t' },
    i(1),
    t { '', '\\end{bmatrix}' },
  }, {
    show_condition = is_math_show,
    condition = is_math,
  }),

  -- s('mat', {
  --   t { '\\begin{bmatrix}', '\t' },
  --   i(1),
  --   t { '', '\\end{bmatrix}' },
  -- }, {
  --   {
  --     show_condition = function()
  --       return false
  --     end,
  --   },
  -- }),
  --
  --postfixes for vectors, hats, etc. The match pattern is '\\' plus the default (so that hats get put on greek letters,e.g.)
  postfix(
    { trig = 'hat', match_pattern = [[[\\%w%.%_%-%"%']+$]], snippetType = 'autosnippet', dscr = 'postfix hat when in math mode' },
    { l('\\hat{' .. l.POSTFIX_MATCH .. '}') },
    { condition = is_math }
  ),
  postfix(
    { trig = 'vec', match_pattern = [[[\\%w%.%_%-%"%']+$]], snippetType = 'autosnippet', dscr = 'postfix vec when in math mode' },
    { l('\\vec{' .. l.POSTFIX_MATCH .. '}') },
    { condition = is_math }
  ),
}

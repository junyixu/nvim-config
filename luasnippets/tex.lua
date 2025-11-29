---@diagnostic disable: undefined-global

local ls = require 'luasnip'
local ts_utils = require 'luasnip-latex-snippets.util.ts_utils'
local is_math = ts_utils.in_mathzone

local parse = ls.parser.parse_snippet
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet
-- local math_iA = require 'luasnip-latex-snippets.math_iA'
--
local utils = require 'luasnip-latex-snippets.util.utils'
local pipe, no_backslash = utils.pipe, utils.no_backslash

local decorator = {
  wordTrig = false,
  hidden = true,
  condition = pipe { is_math, no_backslash },
}

local parse_snippet = ls.extend_decorator.apply(ls.parser.parse_snippet, decorator) --[[@as function]]
local maths = ls.extend_decorator.apply(ls.snippet, decorator) --[[@as function]]

local function paren_fraction(_, snip)
  local stripped = snip.captures[1] or ''
  if stripped == '' then
    return sn(nil, t '')
  end

  local depth = 0
  local idx = #stripped

  while idx > 0 do
    local char = stripped:sub(idx, idx)
    if char == ')' then
      depth = depth + 1
    elseif char == '(' then
      depth = depth - 1
    end

    if depth == 0 then
      break
    end

    idx = idx - 1
  end

  if idx <= 0 then
    return sn(nil, t(stripped))
  end

  local prefix = stripped:sub(1, idx - 1)
  local numerator = stripped:sub(idx + 1, #stripped - 1)

  return sn(nil, {
    t(prefix .. '\\frac{' .. numerator .. '}{'),
    i(1),
    t '}',
    i(0),
  })
end

local math_snipets = {
  -- parse({ trig = 'beg', name = 'begin...end' }, '\\begin{${1:env}}\n$0\n\\end{$1}'),
  s(
    { trig = 'beg', name = 'begin...end' },
    fmta(
      [[
\begin{<>}
<>
\end{<>}
]],
      { i(1, 'env'), i(0), rep(1) }
    )
  ),
}

for _, snip in ipairs(math_snipets) do
  snip.condition = is_math
  snip.show_condition = is_math
end

origin_snippets = {
  maths(
    { trig = '([^%s]+)t', regTrig = true, priority = 1 },
    fmta('(<>)^(<>) <> hello', { f(function(_, snip)
      return snip.captures[1]
    end), i(1), i(2) })
  ),
  s({ trig = 'mat', priority = 100, name = 'bmatrix' }, {
    t { '\\begin{bmatrix}', '' },
    i(1),
    t { '', '\\end{bmatrix}' },
  }, {
    condition = is_math,
    show_condition = is_math,
  }),
  -- Transform (...)/ into \frac{...}{•} in math zones
  s({
    trig = '(^.*\\))/',
    name = '() frac',
    regTrig = true,
    trigEngine = 'ecma',
    snippetType = 'autosnippet',
    hidden = true,
  }, {
    d(1, paren_fraction),
  }, {
    condition = is_math,
    show_condition = is_math,
  }),

  -- Transform symbols or digits before / into \frac{symbol}{•}
  s({
    trig = [[((\d+)|(\d*)(\\)?([A-Za-z]+)((\^|_)(\{\d+\}|\d))*)/]],
    name = 'sym frac',
    regTrig = true,
    trigEngine = 'ecma',
    snippetType = 'autosnippet',
    hidden = true,
  }, {
    t '\\frac{',
    f(function(_, snip)
      return snip.captures[1] or ''
    end),
    t '}{',
    i(1),
    t '}',
    i(0),
  }, { condition = is_math }),
}

return vim.list_extend(math_snipets, origin_snippets)

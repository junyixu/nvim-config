local ls = require 'luasnip'
local ts_utils = require 'luasnip-latex-snippets.util.ts_utils'
local is_math = ts_utils.in_mathzone

local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

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

local snip_table = {
  s('mat', {
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

return snip_table

---@diagnostic disable: undefined-global

local ls = require 'luasnip'
local parse = ls.parser.parse_snippet
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

local utils = require 'util.utils'
-- true 表示走 treesitter；如果想让 vimtex 判定就改成 false
local is_math = utils.with_opts(utils.is_math, true)
local not_math = utils.with_opts(utils.not_math, true)
local pipe, no_backslash = utils.pipe, utils.no_backslash
in_mathzone = is_math
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

local function cap(idx)
  return f(function(_, snip)
    return snip.captures[idx] or ''
  end)
end

local greeks_snipets = {
  parse({ trig = ',a', name = 'alpha', snippetType = 'autosnippet' }, '\\alpha'),
  -- parse({ trig = ',a', name = 'alpha' }, '\\alpha'),
  parse({ trig = ',b', name = 'beta', snippetType = 'autosnippet' }, '\\beta'),
  parse({ trig = ',g', name = 'gamma', snippetType = 'autosnippet' }, '\\gamma'),
  parse({ trig = ',G', name = 'Gamma', snippetType = 'autosnippet' }, '\\Gamma'),
  parse({ trig = ',d', name = 'delta', snippetType = 'autosnippet' }, '\\delta'),
  parse({ trig = ',D', name = 'Delta', snippetType = 'autosnippet' }, '\\Delta'),
  parse({ trig = ',r', name = 'rho', snippetType = 'autosnippet' }, '\\rho'),
  parse({ trig = ',c', name = 'chi', snippetType = 'autosnippet' }, '\\chi'),
  parse({ trig = ',x', name = 'xi', snippetType = 'autosnippet' }, '\\xi'),
  parse({ trig = ',z', name = 'zeta', snippetType = 'autosnippet' }, '\\zeta'),
  parse({ trig = ',s', name = 'sigma', snippetType = 'autosnippet' }, '\\sigma'),
  parse({ trig = ',S', name = 'Sigma', snippetType = 'autosnippet' }, '\\Sigma'),
  parse({ trig = ',t', name = 'tau', snippetType = 'autosnippet' }, '\\tau'),
  parse({ trig = ',o', name = 'omega', snippetType = 'autosnippet' }, '\\omega'),
  parse({ trig = ',O', name = 'Omega', snippetType = 'autosnippet' }, '\\Omega'),
  parse({ trig = ',m', name = 'mu', snippetType = 'autosnippet' }, '\\mu'),
  parse({ trig = ',n', name = 'nu', snippetType = 'autosnippet' }, '\\nu'),
  parse({ trig = ',q', name = 'theta', snippetType = 'autosnippet' }, '\\theta'),
  parse({ trig = ',f', name = 'varphi', snippetType = 'autosnippet' }, '\\varphi'),
  parse({ trig = ',F', name = 'Phi', snippetType = 'autosnippet' }, '\\Phi'),
  parse({ trig = ',e', name = 'epsilon', snippetType = 'autosnippet' }, '\\epsilon'),
  parse({ trig = ',,f', name = 'phi', snippetType = 'autosnippet', priority = 1001 }, '\\phi'),
  parse({ trig = ',e', name = 'varepsilon', snippetType = 'autosnippet' }, '\\varepsilon'),
  parse({ trig = ',,e', name = 'epsilon', snippetType = 'autosnippet', priority = 1001 }, '\\epsilon'),
  parse({ trig = ',l', name = 'lambda', snippetType = 'autosnippet' }, '\\lambda'),
  parse({ trig = ',L', name = 'Lambda', snippetType = 'autosnippet' }, '\\Lambda'),
  parse({ trig = ',p', name = 'pi', snippetType = 'autosnippet' }, '\\pi'),
  parse({ trig = ',k', name = 'kappa', snippetType = 'autosnippet' }, '\\kappa'),
  parse({ trig = ',y', name = 'psi', snippetType = 'autosnippet' }, '\\psi'),
}

for _, snippet in ipairs(greeks_snipets) do
  snippet.wordTrig = false
end

local math_snipets = {
  s(
    {
      -- trig 是正则表达式
      -- (.+) 捕获前面所有的字符
      -- <C-/> 在这里假设你直接输入该字符，或通过 mapping 触发
      -- 注意：如果你的终端将 <C-/> 发送为特定字符，请替换下方触发词
      trig = '(%S+)//',
      priority = 1,
      regTrig = true,
      wordTrig = false,
      snippetType = 'autosnippet', -- 推荐使用自动触发
    },
    fmta([[ \frac{<>}{<>}<> ]], {
      cap(1), -- 填入第一个捕获组的内容，即 \sqrt{3}
      i(1), -- 分母位置
      i(0), -- 退出位置
    })
  ),
  -- a1 -> a_1
  s({ trig = '([%a])(%d)', name = 'automatic subscript', regTrig = true, priority = 500, snippetType = 'autosnippet' }, fmta('<>_<>', { cap(1), cap(2) })),
  -- \alpha1 -> \alpha_1
  s({ trig = '(\\%a-)(%d)', name = 'automatic subscript', regTrig = true, priority = 500, snippetType = 'autosnippet' }, fmta('<>_<>', { cap(1), cap(2) })),

  parse(
    { trig = 'beg', name = 'begin...end' },
    [[
  \begin{${1:env}}
  $0
  \end{$1}
  ]]
  ),
  --   s(
  --     { trig = 'beg', name = 'begin...end' },
  --     fmta(
  --       [[
  -- \begin{<>}
  -- <>
  -- \end{<>}
  -- ]],
  --       { i(1, 'env'), i(0), rep(1) }
  --     )
  --   ),

  s({ trig = 'pdv', name = 'partial derivative' }, fmta('\\frac{\\partial <>}{\\partial <>}', { i(1, 'y'), i(2, 'x') })),
  s({ trig = 'dv', name = 'derivative', priority = 100 }, fmta('\\frac{\\mathrm{d} <>}{\\mathrm{d} <>}', { i(1, 'y'), i(2, 'x') })),
  parse({ trig = 'lap', name = 'laplace', snippetType = 'autosnippet' }, '\\nabla^2 '),
  parse({ trig = 'grad', snippetType = 'autosnippet' }, '\\boldsymbol{\\nabla}'),
  parse({ trig = 'curl', snippetType = 'autosnippet' }, '\\boldsymbol{\\nabla} \\times '),
  parse({ trig = 'div', snippetType = 'autosnippet' }, '\\boldsymbol{\\nabla} \\cdot '),
  -- \alpha,. -> \boldsymbol{\alpha}
  s({ trig = '(\\?%a+),%.', regTrig = true, snippetType = 'autosnippet', desc = 'Vector postfix' }, fmta('\\boldsymbol{<>}', { cap(1) })),
  s({ trig = '(\\?%a+)%.,', regTrig = true, snippetType = 'autosnippet', desc = 'Vector postfix' }, fmta('\\boldsymbol{<>}', { cap(1) })),

  parse({ trig = 'op', name = 'operator' }, '\\operatorname{$1}'),

  parse({ trig = 'OO', snippetType = 'autosnippet', name = 'emptyset' }, '\\O'),
  parse({ trig = 'RR', snippetType = 'autosnippet', name = 'R' }, '\\mathbb{R}'),
  parse({ trig = 'QQ', snippetType = 'autosnippet', name = 'Q' }, '\\mathbb{Q}'),
  parse({ trig = 'ZZ', snippetType = 'autosnippet', name = 'Z' }, '\\mathbb{Z}'),
  parse({ trig = 'NN', snippetType = 'autosnippet', name = 'N' }, '\\mathbb{N}'),

  parse({ trig = 'UU', snippetType = 'autosnippet', name = 'cup' }, '\\cup '),

  parse({ trig = '==', snippetType = 'autosnippet', name = 'equals' }, [[&= $1 \\\\]]),
  parse({ trig = '!=', snippetType = 'autosnippet', name = 'not equals' }, '\\neq '),
  parse({ trig = '~=', name = 'approximate', snippetType = 'autosnippet' }, '\\approx '),
  parse({ trig = '~~', snippetType = 'autosnippet', name = '~' }, '\\sim '),

  parse({ trig = '__', snippetType = 'autosnippet', name = 'subscript' }, '_{$1}$0'),

  parse({ trig = '=>', snippetType = 'autosnippet', name = 'implies' }, '\\implies'),
  parse({ trig = '=<', snippetType = 'autosnippet', name = 'implied by' }, '\\impliedby'),

  parse({ trig = '<<', snippetType = 'autosnippet', name = '<<' }, '\\ll'),
  parse({ trig = '>>', snippetType = 'autosnippet', name = '<<' }, '\\gg'),

  parse({ trig = '<=', snippetType = 'autosnippet', name = 'less equal' }, '\\leq '),
  parse({ trig = '>=', snippetType = 'autosnippet', name = 'greater equal' }, '\\geq '),

  s({ trig = '(\\?%a+)-', regTrig = true }, fmta('\\bar{<>}', { cap(1) })),
  -- trig = "(%a+)hat",
  s({ trig = '(%a)hat', regTrig = true, snippetType = 'autosnippet' }, fmta('\\hat{<>}', { cap(1) })),
  s({ trig = '(\\%a+)hat', regTrig = true, snippetType = 'autosnippet' }, fmta('\\hat{<>}', { cap(1) })),
  parse({ trig = 'EE', name = 'exists', snippetType = 'autosnippet' }, '\\exists '),
  parse({ trig = 'AA', name = 'forall', snippetType = 'autosnippet' }, '\\forall '),

  parse({ trig = 'cc', name = 'subset', snippetType = 'autosnippet' }, '\\subset '),
  parse({ trig = 'ooo', name = '\\infty', snippetType = 'autosnippet' }, '\\infty'),

  parse({ trig = '<!', name = 'normal', snippetType = 'autosnippet' }, '\\triangleleft '),

  parse({ trig = '->', name = 'to', priority = 100, snippetType = 'autosnippet' }, '\\to '),
  parse({ trig = '-->', name = 'long to', priority = 200, snippetType = 'autosnippet' }, '\\longrightarrow '),

  parse({ trig = 'cb', wordTrig = false, snippetType = 'autosnippet', name = 'Cube ^3' }, '^3'),
  parse({ trig = 'sr', wordTrig = false, snippetType = 'autosnippet', name = 'Square ^2' }, '^2'),
  parse({ trig = 'td', wordTrig = false, snippetType = 'autosnippet', name = 'to the ... power ^{}' }, '^{$1}$0 '),
  parse({ trig = 'rd', wordTrig = false, snippetType = 'autosnippet', name = 'to the ... power ^{()}' }, '^{($1)}$0 '),

  parse({ trig = 'iff', snippetType = 'autosnippet', name = 'iff' }, '\\iff '),
  parse({ trig = 'stt', snippetType = 'autosnippet', name = 'text subscript' }, '_\\text{$1} $0'),
  parse({ trig = 'tt', snippetType = 'autosnippet', name = 'text' }, '\\text{$1}$0'),

  parse({ trig = '...', desc = '\\dots: \\ldots or \\cdots', name = 'dots', snippetType = 'autosnippet', wordTrig = false }, '\\dots '),

  parse({ trig = '.', name = 'dot product' }, '\\cdot '),
  parse({ trig = '**', snippetType = 'autosnippet', name = 'dot product', priority = 100 }, '\\cdot '),
  parse_snippet({ trig = 'xx', snippetType = 'autosnippet', name = 'cross product' }, '\\times '),
  parse_snippet({ trig = ':=', snippetType = 'autosnippet', name = 'colon equals (lhs defined as rhs)' }, '\\coloneqq '),

  -- 用 \pu (physics unit) 代替 siunitx
  -- https://forum.obsidian.md/t/question-about-superscripts-and-subscripts/25941/8
  -- context "isMath()"
  -- snippet '([\de\.]+)si' "unit" r
  -- \pu{`!p snip.rv=match.group(1)` $1}
  -- endsnippet
  -- s({ trig = '([%de%.]+)si', name = 'physics unit', regTrig = true, snippetType = 'autosnippet' }, fmta('\\pu{<>}', { cap(1) })),
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

  -- s({
  --   trig = '<([a-zA-Z]-)|',
  --   regTrig = true,
  --   trigEngine = 'pattern',
  --   wordTrig = false,
  --   snippetType = 'autosnippet',
  --   condition = is_math,
  -- }, fmta('\\bra{<>}', { cap(1) })),
  --
  -- s({
  --   trig = '<(\\[a-zA-Z]-)|',
  --   regTrig = true,
  --   trigEngine = 'pattern',
  --   wordTrig = false,
  --   snippetType = 'autosnippet',
  --   condition = is_math,
  -- }, fmta('\\bra{<>}', { cap(1) })),

  s({
    trig = '<(.-)|',
    regTrig = true,
    trigEngine = 'pattern',
    priority = 100,
    wordTrig = false,
    snippetType = 'autosnippet',
    condition = is_math,
  }, fmta('\\Bra{<>}', { cap(1) })),

  -- s({
  --   trig = '|(%a-)>',
  --   regTrig = true,
  --   priority = 100,
  --   trigEngine = 'pattern',
  --   wordTrig = false,
  --   snippetType = 'autosnippet',
  --   condition = in_mathzone,
  -- }, fmta('\\Ket{<>}', { cap(1) })),
  --
  -- s({
  --   trig = '|(\\%a-)>',
  --   regTrig = true,
  --   priority = 200,
  --   trigEngine = 'pattern',
  --   wordTrig = false,
  --   snippetType = 'autosnippet',
  --   condition = in_mathzone,
  -- }, fmta('\\Ket{<>}', { cap(1) })),

  s({
    trig = '|(\\?%a-)>',
    regTrig = true,
    priority = 2000,
    trigEngine = 'pattern',
    wordTrig = false,
    snippetType = 'autosnippet',
    condition = in_mathzone,
  }, fmta('\\Ket{<>}', { cap(1) })),

  s({
    trig = '<(.-)>',
    regTrig = true,
    trigEngine = 'pattern',
    priority = 0,
    wordTrig = false,
    snippetType = 'autosnippet',
    condition = in_mathzone,
  }, fmta('\\Braket{<>}', { cap(1) })),

  s({
    trig = '\\Bra{(.-)}([^|]-)>',
    regTrig = true,
    priority = 2000,
    trigEngine = 'pattern',
    wordTrig = false,
    snippetType = 'autosnippet',
    condition = in_mathzone,
  }, fmta('\\Braket{<>|<>}', { cap(1), cap(2) })),

  s(
    { trig = 'mat', priority = 100, name = 'bmatrix' },
    fmta(
      [[
\begin{bmatrix}
<>
\end{bmatrix}
]],
      { i(0) }
    ),
    {
      condition = is_math,
      show_condition = is_math,
    }
  ),
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

math_snipets = vim.list_extend(greeks_snipets, math_snipets)
return vim.list_extend(math_snipets, origin_snippets)

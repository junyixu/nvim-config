---@diagnostic disable: undefined-global

local ls = require 'luasnip'
local parse = ls.parser.parse_snippet
local i = ls.insert_node
local t = ls.text_node
local f = ls.function_node
local s = ls.snippet
local fmta = require('luasnip.extras.fmt').fmta

-- typst 数学环境检测: 走 treesitter，查找 `math` 节点祖先
-- inline math: $E = m c^2$;  display math: $ E = m c^2 $
local function in_typst_math()
  local node = vim.treesitter.get_node { ignore_injections = false }
  while node do
    if node:type() == 'math' then
      return true
    end
    node = node:parent()
  end
  return false
end

local is_math = in_typst_math
in_mathzone = is_math

local decorator = {
  wordTrig = false,
  hidden = true,
  condition = is_math,
}

local parse_math = ls.extend_decorator.apply(ls.parser.parse_snippet, decorator) --[[@as function]]
local maths = ls.extend_decorator.apply(ls.snippet, decorator) --[[@as function]]

local function cap(idx)
  return f(function(_, snip)
    return snip.captures[idx] or ''
  end)
end

local greeks_snippets = {
  parse_math({ trig = ',a', name = 'alpha', snippetType = 'autosnippet' }, 'alpha'),
  parse_math({ trig = ',b', name = 'beta', snippetType = 'autosnippet' }, 'beta'),
  parse_math({ trig = ',g', name = 'gamma', snippetType = 'autosnippet' }, 'gamma'),
  parse_math({ trig = ',G', name = 'Gamma', snippetType = 'autosnippet' }, 'Gamma'),
  parse_math({ trig = ',d', name = 'delta', snippetType = 'autosnippet' }, 'delta'),
  parse_math({ trig = ',D', name = 'Delta', snippetType = 'autosnippet' }, 'Delta'),
  parse_math({ trig = ',r', name = 'rho', snippetType = 'autosnippet' }, 'rho'),
  parse_math({ trig = ',c', name = 'chi', snippetType = 'autosnippet' }, 'chi'),
  parse_math({ trig = ',x', name = 'xi', snippetType = 'autosnippet' }, 'xi'),
  parse_math({ trig = ',z', name = 'zeta', snippetType = 'autosnippet' }, 'zeta'),
  parse_math({ trig = ',s', name = 'sigma', snippetType = 'autosnippet' }, 'sigma'),
  parse_math({ trig = ',S', name = 'Sigma', snippetType = 'autosnippet' }, 'Sigma'),
  parse_math({ trig = ',t', name = 'tau', snippetType = 'autosnippet' }, 'tau'),
  parse_math({ trig = ',o', name = 'omega', snippetType = 'autosnippet' }, 'omega'),
  parse_math({ trig = ',O', name = 'Omega', snippetType = 'autosnippet' }, 'Omega'),
  parse_math({ trig = ',m', name = 'mu', snippetType = 'autosnippet' }, 'mu'),
  parse_math({ trig = ',n', name = 'nu', snippetType = 'autosnippet' }, 'nu'),
  parse_math({ trig = ',q', name = 'theta', snippetType = 'autosnippet' }, 'theta'),
  -- typst: phi=ϕ, phi.alt=φ；对应 LaTeX 的 \phi 与 \varphi
  parse_math({ trig = ',f', name = 'phi.alt (varphi)', snippetType = 'autosnippet' }, 'phi.alt'),
  parse_math({ trig = ',F', name = 'Phi', snippetType = 'autosnippet' }, 'Phi'),
  parse_math({ trig = ',,f', name = 'phi', snippetType = 'autosnippet', priority = 1001 }, 'phi'),
  -- typst: epsilon=ε, epsilon.alt=ϵ；对应 LaTeX 的 \varepsilon 与 \epsilon
  parse_math({ trig = ',e', name = 'epsilon (varepsilon)', snippetType = 'autosnippet' }, 'epsilon'),
  parse_math({ trig = ',,e', name = 'epsilon.alt', snippetType = 'autosnippet', priority = 1001 }, 'epsilon.alt'),
  parse_math({ trig = ',l', name = 'lambda', snippetType = 'autosnippet' }, 'lambda'),
  parse_math({ trig = ',L', name = 'Lambda', snippetType = 'autosnippet' }, 'Lambda'),
  parse_math({ trig = ',p', name = 'pi', snippetType = 'autosnippet' }, 'pi'),
  parse_math({ trig = ',k', name = 'kappa', snippetType = 'autosnippet' }, 'kappa'),
  parse_math({ trig = ',y', name = 'psi', snippetType = 'autosnippet' }, 'psi'),
  parse_math({ trig = ',6', name = 'diff (partial)', snippetType = 'autosnippet' }, 'diff'),
  parse_math({ trig = ',8', name = 'infinity', snippetType = 'autosnippet' }, 'oo'),
}

local math_snippets = {
  -- a1 -> a_1
  maths({ trig = '([%a])(%d)', name = 'automatic subscript', regTrig = true, priority = 500, snippetType = 'autosnippet' }, fmta('<>_<>', { cap(1), cap(2) })),
  -- alpha1 -> alpha_1  (typst 无 `\` 前缀, 希腊字母即普通标识符)
  maths(
    { trig = '(%a+)(%d)', name = 'automatic subscript (word)', regTrig = true, priority = 600, snippetType = 'autosnippet' },
    fmta('<>_<>', { cap(1), cap(2) })
  ),

  -- display math (单行):  $ ... $
  parse({ trig = 'dm', name = 'display math', snippetType = 'autosnippet' }, [[$ $1 $$0]]),

  -- inline math:  $...$
  parse({ trig = 'mk', name = 'inline math', snippetType = 'autosnippet' }, [[$$1$$0]]),

  -- alpha,. -> vb(alpha)
  maths({ trig = '(%a+),%.', regTrig = true, snippetType = 'autosnippet', desc = 'Vector postfix' }, fmta('vb(<>)', { cap(1) })),
  maths({ trig = '(%a+)%.,', regTrig = true, snippetType = 'autosnippet', desc = 'Vector postfix' }, fmta('vb(<>)', { cap(1) })),

  parse_math({ trig = 'op', name = 'operator' }, 'op("$1")$0'),

  parse_math({ trig = 'OO', snippetType = 'autosnippet', name = 'emptyset' }, 'nothing'),
  parse_math({ trig = 'UU', snippetType = 'autosnippet', name = 'cup' }, 'union '),

  parse_math({ trig = '==', snippetType = 'autosnippet', name = 'align equals' }, [[&= $1 \]]),
  parse_math({ trig = '~=', name = 'approximate', snippetType = 'autosnippet' }, 'approx '),
  parse_math({ trig = '~~', snippetType = 'autosnippet', name = 'sim' }, 'tilde.op '),

  parse_math({ trig = '__', wordTrig = false, snippetType = 'autosnippet', name = 'subscript' }, '_($1)$0'),

  parse_math({ trig = 'o', name = 'circle' }, 'compose'),

  -- overline:  alpha- -> overline(alpha)
  maths({ trig = '(%a+)-', regTrig = true }, fmta('overline(<>)', { cap(1) })),
  -- hat
  maths({ trig = '(%a)hat', regTrig = true, snippetType = 'autosnippet' }, fmta('hat(<>)', { cap(1) })),
  maths({ trig = '(%a+)hat', regTrig = true, snippetType = 'autosnippet' }, fmta('hat(<>)', { cap(1) })),

  parse_math({ trig = 'EE', name = 'exists', snippetType = 'autosnippet' }, 'exists '),
  parse_math({ trig = 'AA', name = 'forall', snippetType = 'autosnippet' }, 'forall '),

  parse_math({ trig = 'cc', name = 'subset', snippetType = 'autosnippet' }, 'subset '),
  parse_math({ trig = 'ooo', name = 'infinity', snippetType = 'autosnippet' }, 'infinity'),

  parse_math({ trig = '<!', name = 'triangleleft', snippetType = 'autosnippet' }, 'lt.tri '),

  parse_math({ trig = 'cb', wordTrig = false, snippetType = 'autosnippet', name = 'Cube ^3' }, '^3'),
  parse_math({ trig = 'sr', wordTrig = false, snippetType = 'autosnippet', name = 'Square ^2' }, '^2'),
  parse_math({ trig = 'td', wordTrig = false, snippetType = 'autosnippet', name = 'to the ... power ^()' }, '^($1)$0 '),
  parse_math({ trig = 'rd', wordTrig = false, snippetType = 'autosnippet', name = 'to the ... power ^(())' }, '^(($1))$0 '),

  -- typst 数学内文本直接用 "..."
  parse_math({ trig = 'stt', snippetType = 'autosnippet', name = 'text subscript' }, '_"$1" $0'),
  parse_math({ trig = 'tt', snippetType = 'autosnippet', name = 'text' }, '"$1"$0'),

  parse_math({ trig = '.', name = 'dot product' }, 'dot '),
  parse_math({ trig = '**', snippetType = 'autosnippet', name = 'dot product', priority = 100 }, 'dot '),
  parse_math({ trig = 'xx', snippetType = 'autosnippet', name = 'cross product' }, 'times '),
}

origin_snippets = {
  -- diffx -> diff_x  (typst `diff` 即 ∂)
  s({
    trig = 'diff(%a)',
    regTrig = true,
    trigEngine = 'pattern',
    wordTrig = false,
    snippetType = 'autosnippet',
    condition = in_mathzone,
  }, fmta('diff_<>', { cap(1) })),

  -- 方括号矩阵
  s(
    { trig = 'mat', priority = 100, name = 'bmatrix' },
    fmta(
      [[
mat(
  delim: "[",
  <>;
)]],
      { i(0) }
    ),
    {
      condition = is_math,
      show_condition = is_math,
    }
  ),
  parse({ trig = 'link', name = 'link' }, '#link("$1")[$0]'),
  --------------------------------
  --------------------------------
  -- figures
  -- (biggest waste of time ever)
  -- (supposedly advanced snippet practice)
  --------------------------------
  --------------------------------
  s(
    { trig = 'fig(%a?)', regTrig = true, desc = 'create a figure' },
    fmt(
      [[
	#figure(
	  {content}
	  caption: [{caption}],
	) <{label}>
	]],
      {
        caption = i(2, 'Caption'),
        label = i(1, 'label'),
        content = d(3, function(args, snip)
          if not snip.captures[1] or snip.captures[1] == '' then
            -- regular figure
            return sn(
              nil,
              fmt(
                [[
					image("{path}.{ext}"),
					]],
                {
                  path = f(function()
                    return 'fig/' .. vim.fn.expand '%:r' .. '/' .. (args[1][1] or nil)
                  end),
                  ext = c(1, { t 'svg', t 'jpg', t 'png' }),
                }
              )
            )
          elseif snip.captures[1] == 't' then
            return sn(
              nil,
              fmt(
                [[
					tablef(
					    columns: {cols},
					    table.header{head},
					    {content}
					  ),
					]],
                {
                  head = i(1, '[Header][Header]'),
                  content = i(2, '[Content], [Content],'),
                  cols = f(function(largs)
                    -- the number of columns is the number of left brackets [ in the header
                    local _, cnt = string.gsub(largs[1][1], '%[', '')
                    -- the error for not converting to string was cryptic
                    -- wasted 10 minutes on this :(
                    return tostring(cnt)
                  end, { 1 }),
                }
              )
            )
          end
        end, { 1 }),
      }
    )
  ),

  --------------------------------
  --------------------------------
  -- document templates
  --------------------------------
  --------------------------------

  -- this template is deprecated
  s(
    { trig = 'general', desc = 'General document template' },
    fmt(
      [[
	#import "/templates/general.typ": template, lref
	#import "/templates/libs.typ": *
	#show: template.with(
	  title: "{}",
	  prefix: "{}",
	  suffix: "{}",
	)

	]],
      { i(1), i(2), i(3) }
    )
  ),

  -- this template is deprecated
  s(
    { trig = 'problem', desc = 'Problem write-up template' },
    fmt(
      [[
	#import "/templates/problems.typ": template, source_code, status, lref
	#import "/templates/libs.typ": *
	#show: template.with(
	  problem_url: "{}",
	  title: "{}",
	  stat: "{}",
	)

	]],
      { i(1), i(2), t 'incomplete' }
    )
  ),

  s(
    { trig = 'book', desc = 'New notes template' },
    fmt(
      [[
	#import "@local/mousse-notes:0.6.2": *
	#set page(paper: "us-letter")
	#show: book.with(
	  title: [{}],
	  subtitle: {},
	  subsubtitle: {},
	  subsubsubtitle: {},
	  author: {},
	)


	]],
      { i(1), i(2, 'none'), i(3, 'none'), i(4, 'none'), i(5, 'none') }
    )
  ),
}

return vim.list_extend(math_snippets, origin_snippets), greeks_snippets

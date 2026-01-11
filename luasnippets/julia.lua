local ls = require 'luasnip'

local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet
local parse = ls.parser.parse_snippet
local conds = require 'luasnip.extras.conditions'
local fmt = require('luasnip.extras.fmt').fmt

-- Unicode autosnippets for LaTeX commands
local unicode_snippets = {
  -- Greek letters (lowercase)
  { name = 'alpha ', unicode = 'α' },
  { name = 'beta ', unicode = 'β' },
  { name = 'gamma ', unicode = 'γ' },
  { name = 'delta ', unicode = 'δ' },
  { name = 'epsilon ', unicode = 'ε' },
  { name = 'varepsilon ', unicode = 'ε' },
  { name = 'zeta ', unicode = 'ζ' },
  { name = 'eta ', unicode = 'η' },
  { name = 'theta ', unicode = 'θ' },
  { name = 'vartheta ', unicode = 'ϑ' },
  { name = 'iota ', unicode = 'ι' },
  { name = 'kappa ', unicode = 'κ' },
  { name = 'lambda ', unicode = 'λ' },
  { name = 'mu ', unicode = 'μ' },
  { name = 'nu ', unicode = 'ν' },
  { name = 'xi ', unicode = 'ξ' },
  { name = 'pi ', unicode = 'π' },
  { name = 'rho ', unicode = 'ρ' },
  { name = 'sigma ', unicode = 'σ' },
  { name = 'tau ', unicode = 'τ' },
  { name = 'upsilon ', unicode = 'υ' },
  { name = 'phi ', unicode = 'φ' },
  { name = 'varphi ', unicode = 'φ' },
  { name = 'chi ', unicode = 'χ' },
  { name = 'psi ', unicode = 'ψ' },
  { name = 'omega ', unicode = 'ω' },

  -- Greek letters (uppercase)
  { name = 'Gamma ', unicode = 'Γ' },
  { name = 'Delta ', unicode = 'Δ' },
  { name = 'Theta ', unicode = 'Θ' },
  { name = 'Lambda ', unicode = 'Λ' },
  { name = 'Xi ', unicode = 'Ξ' },
  { name = 'Pi ', unicode = 'Π' },
  { name = 'Sigma ', unicode = 'Σ' },
  { name = 'Upsilon ', unicode = 'Υ' },
  { name = 'Phi ', unicode = 'Φ' },
  { name = 'Psi ', unicode = 'Ψ' },
  { name = 'Omega ', unicode = 'Ω' },

  -- Math symbols
  { name = 'infty ', unicode = '∞' },
  { name = 'partial ', unicode = '∂' },
  { name = 'nabla ', unicode = '∇' },
  { name = 'pm ', unicode = '±' },
  { name = 'mp ', unicode = '∓' },
  { name = 'times ', unicode = '×' },
  { name = 'div ', unicode = '÷' },
  { name = 'cdot ', unicode = '·' },
  { name = 'circ ', unicode = '∘' },
  { name = 'oplus ', unicode = '⊕' },
  { name = 'otimes ', unicode = '⊗' },
  { name = 'odot ', unicode = '⊙' },

  -- Relations
  { name = 'leq ', unicode = '≤' },
  { name = 'geq ', unicode = '≥' },
  { name = 'neq ', unicode = '≠' },
  { name = 'approx ', unicode = '≈' },
  { name = 'equiv ', unicode = '≡' },
  { name = 'sim ', unicode = '∼' },
  { name = 'simeq ', unicode = '≃' },
  { name = 'cong ', unicode = '≅' },
  { name = 'propto ', unicode = '∝' },

  -- Set theory
  { name = 'in ', unicode = '∈' },
  { name = 'notin ', unicode = '∉' },
  { name = 'subset ', unicode = '⊂' },
  { name = 'subseteq ', unicode = '⊆' },
  { name = 'supset ', unicode = '⊃' },
  { name = 'supseteq ', unicode = '⊇' },
  { name = 'cup ', unicode = '∪' },
  { name = 'cap ', unicode = '∩' },
  { name = 'emptyset ', unicode = '∅' },
  { name = 'varnothing ', unicode = '∅' },

  -- Logic
  { name = 'forall ', unicode = '∀' },
  { name = 'exists ', unicode = '∃' },
  { name = 'neg ', unicode = '¬' },
  { name = 'land ', unicode = '∧' },
  { name = 'lor ', unicode = '∨' },
  { name = 'implies ', unicode = '⇒' },
  { name = 'iff ', unicode = '⇔' },

  -- Arrows
  { name = 'rightarrow ', unicode = '→' },
  { name = 'leftarrow ', unicode = '←' },
  { name = 'leftrightarrow ', unicode = '↔' },
  { name = 'Rightarrow ', unicode = '⇒' },
  { name = 'Leftarrow ', unicode = '⇐' },
  { name = 'Leftrightarrow ', unicode = '⇔' },
  { name = 'mapsto ', unicode = '↦' },
  { name = 'to ', unicode = '→' },

  -- Summation and integration
  { name = 'sum ', unicode = '∑' },
  { name = 'prod ', unicode = '∏' },
  { name = 'int ', unicode = '∫' },
  { name = 'oint ', unicode = '∮' },

  -- Parentheses and brackets
  { name = 'langle ', unicode = '⟨' },
  { name = 'rangle ', unicode = '⟩' },
  { name = 'lceil ', unicode = '⌈' },
  { name = 'rceil ', unicode = '⌉' },
  { name = 'lfloor ', unicode = '⌊' },
  { name = 'rfloor ', unicode = '⌋' },

  -- Other symbols
  { name = 'sqrt ', unicode = '√' },
  { name = 'angle ', unicode = '∠' },
  { name = 'perp ', unicode = '⊥' },
  { name = 'parallel ', unicode = '∥' },
  { name = 'prime ', unicode = '′' },
  { name = 'degree ', unicode = '°' },
}

-- Convert unicode_snippets table to actual snippets with autosnippet type
local result = {
  parse({ trig = '.', desc = 'dot product' }, '⋅'),
  parse({ trig = 'ox', desc = 'tensor product' }, '⊗'),
  parse({ trig = 'o', desc = 'composition operator' }, '·'),
  parse({ trig = 'x', desc = 'cross product' }, '×'),
  parse({ trig = 'mkdir', condition = conds.line_begin }, [[!isdir("./figures") && mkpath("./figures")]]),
  s(
    {
      trig = 'module',
      condition = conds.line_begin,
    },
    fmt(
      [[
        module {}
        {}
        end
      ]],
      {
        f(function()
          return vim.fn.expand '%:t:r'
        end),
        i(0),
      }
    )
  ),
  parse(
    { trig = 'mouse', desc = 'Makie mouse position tracker', condition = conds.line_begin },
    [[
# 1. 创建一个用于显示坐标的 Label
# 设置 tellwidth=false 以便将其放置在 layout 上方而不影响 axis
pos_text = Label(
    fig[1, 1],
    "Position: (0, 0)";
    halign=:left,
    valign=:top,
    padding=(10, 10, 10, 10),
    tellwidth=false,
    tellheight=false,
)

# 2. Listen to the mouseposition event
on(events(ax.scene).mouseposition) do mp
    # Convert pixel coordinates to Data Space coordinates
    data_pos = mouseposition(ax.scene)

    # Format the string and update the Label's text attribute
    x, y = round.(data_pos, digits=2)
    pos_text.text = "Position: ($x, $y)"
end
  ]]
  ),
  -- Original snippets
  parse(
    'fn',
    [[
      function $1($2)
          $0
      end
    ]]
  ),
  parse({ trig = 'dark', desc = 'Makie dark theme', condition = conds.line_begin }, 'set_theme!(theme_dark())'),
  parse({
    trig = '#!',
    name = 'shebang',
    desc = 'Julia shebang',
    snippetType = 'autosnippet',
    condition = function(line_to_cursor, matched_trigger, captures)
      return vim.fn.line '.' == 1 and line_to_cursor == matched_trigger
    end,
  }, '#! /usr/bin/env -S julia --color=yes --startup-file=no'),

  -- 如果输入的 `#!` 在 buf 的第 1 行, 则自动展开 (autosnippet)

  s('bg', {
    f(function(args, snip)
      local env = snip.env
      local selected_lines = env.LS_SELECT_RAW

      -- 如果是字符串（说明在生成docstring）或者没有选中内容
      if type(selected_lines) == 'string' or not selected_lines then
        return { 'begin', 'end' }
      end

      local result = { 'begin' }
      -- 遍历表格中的所有行
      for _, line in ipairs(selected_lines) do
        table.insert(result, '    ' .. line)
      end
      table.insert(result, 'end')
      return result
    end, {}),
  }),
}

-- Add unicode snippets using for loop
for _, item in ipairs(unicode_snippets) do
  local clean_name = item.name:gsub(' ', '') -- Remove trailing space

  -- Autosnippet for space trigger: \pi
  table.insert(
    result,
    s({
      trig = '\\' .. clean_name .. ' ', -- \pi followed by space
      name = clean_name,
      snippetType = 'autosnippet',
      hidden = true, -- Hide from completion engine
    }, { t(item.unicode .. ' ') })
  ) -- Output unicode with trailing space

  -- Autosnippet for any non-alphanumeric character: \pi followed by [^a-zA-Z0-9]
  table.insert(
    result,
    s({
      trig = '\\' .. clean_name .. '([^a-zA-Z0-9])', -- \pi followed by non-alphanumeric
      regTrig = true, -- Enable regex
      name = clean_name,
      snippetType = 'autosnippet',
      hidden = true, -- Hide from completion engine
    }, { f(function(args, snip)
      return item.unicode .. (snip.captures[1] or '')
    end, {}) })
  ) -- Output unicode + captured punctuation

  -- Regular snippet for manual expansion: \pi (for Enter key)
  table.insert(
    result,
    s({
      trig = '\\' .. clean_name, -- \pi
      name = clean_name,
      snippetType = 'snippet', -- Regular snippet
      hidden = true, -- Hide from completion engine
    }, { t(item.unicode) })
  ) -- Output unicode without trailing space
end

return result

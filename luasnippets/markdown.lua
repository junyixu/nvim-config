---@diagnostic disable: undefined-global

local ls = require 'luasnip'

local parse = ls.parser.parse_snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

local function list_concat(...)
  local out = {}
  for _, tbl in ipairs { ... } do
    vim.list_extend(out, tbl)
  end
  return out
end

local snip_table = {
  s(
    { trig = 'ali', name = 'begin{aligned}...end{aligned}', condition = conds.line_begin },
    fmta(
      [[$$
\begin{aligned}
<>
\end{aligned}
$$]],
      { i(0) }
    )
  ),
  s('paren_change', {
    c(1, {
      sn(nil, { t '(', r(1, 'user_text'), t ')' }),
      sn(nil, { t '[', r(1, 'user_text'), t ']' }),
      sn(nil, { t '{', r(1, 'user_text'), t '}' }),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['user_text'] = i(1, 'default_text'),
    },
  }),

  -- 高级示例：插入包含选中文本的完整结构
  s('bold', {
    f(function(args, snip)
      local selected_text = snip.env.LS_SELECT_RAW
      local text = selected_text[1] or '' -- 获取选中的文本内容

      return {
        '**' .. text .. '**', -- 粗体文本
        '', -- 空行
      }
    end, {}),
  }),
  -- test
  s('trig', { i(1), t 'test', i(2), t 'text again' }),
  s(
    { trig = '``', name = 'code block' },
    fmt(
      [[
        ```{}
        ```
      ]],
      { i(0) }
    )
  ),

  -- s(
  --   { trig = '```', name = 'code block', snippetType = 'autosnippet' },
  --   fmt(
  --     [[
  --       ```{}
  --       ```
  --     ]],
  --     { i(0) }
  --   )
  -- ),
  s({
    trig = '-',
    name = 'todo list',
    condition = conds.line_begin,
  }, {
    t '- [ ] ',
  }),

  -- Current time in %H:%M format
  s({ trig = 't', name = 'Current Time', condition = conds.line_begin }, {
    f(function()
      return os.date '%H:%M' .. '\t'
    end, {}),
  }),

  -- Current time in %H:%M format
  s({ trig = 'time', name = 'Current Time' }, {
    f(function()
      return os.date '%H:%M'
    end, {}),
  }),
}

local code_block = {
  -- python code block
  s('py', {
    t { '```{python}', '' },
    i(0),
    t { '', '```' },
  }),

  -- Julia code block
  s('jl', {
    t { '```{julia}', '' },
    i(0),
    t { '', '```' },
  }),
}

local math_blocks = {
  parse({ trig = 'mk', name = 'Inline Math', snippetType = 'autosnippet' }, '\\$${1:${TM_SELECTED_TEXT}}\\$$0'),

  parse(
    { trig = 'dm', name = 'Block Math', priority = 1, condition = conds.line_begin, snippetType = 'autosnippet' },
    '\\$\\$\n${0:${TM_SELECTED_TEXT}}\n\\$\\$'
  ),
}

local obsidian_callouts = {
  s({ trig = 'note', name = 'Obsidian Callouts: note', condition = conds.line_begin }, {
    t { '> [!note]', '> ' },
    i(0),
  }),
  s({ trig = 'info', name = 'Obsidian Callouts: info', condition = conds.line_begin }, {
    t { '> [!info]', '> ' },
    i(0),
  }),
  s({ trig = 'tip', name = 'Obsidian Callouts: tip', condition = conds.line_begin }, {
    t { '> [!tip]', '> ' },
    i(0),
  }),
  s({ trig = 'faq', name = 'Obsidian Callouts: faq', condition = conds.line_begin }, {
    t { '> [!faq]', '> ' },
    i(0),
  }),
  s({ trig = 'warning', name = 'Obsidian Callouts: warning', condition = conds.line_begin }, {
    t { '> [!warning]', '> ' },
    i(0),
  }),
  s({ trig = 'question', name = 'Obsidian Callouts: question', condition = conds.line_begin }, {
    t { '> [!question]', '> ' },
    i(0),
  }),
  s({ trig = 'example', name = 'Obsidian Callouts: example', condition = conds.line_begin }, {
    t { '> [!example]', '> ' },
    i(0),
  }),
}

return list_concat(snip_table, obsidian_callouts, math_blocks, code_block)

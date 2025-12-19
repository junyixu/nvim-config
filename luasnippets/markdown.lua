---@diagnostic disable: undefined-global

local ls = require 'luasnip'

local parse = ls.parser.parse_snippet
local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

-- local inline_math = ls.parser.parse_snippet({ trig = 'mk', name = 'Math', priority = 10, snippetType = 'autosnippet' }, '$ ${1:${TM_SELECTED_TEXT}} $$0')

local snip_table = {
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

  s({ trig = '``' }, {
    fmta(
      [[```
      <>
      ```]],
      { i(1) }
    ),
  }),

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

  parse({ trig = 'mk', name = 'Inline Math', snippetType = 'autosnippet' }, '\\$${1:${TM_SELECTED_TEXT}}\\$$0'),

  parse(
    { trig = 'dm', name = 'Block Math', priority = 1, condition = conds.line_begin, snippetType = 'autosnippet' },
    '\\$\\$\n${0:${TM_SELECTED_TEXT}}\n\\$\\$'
  ),
}

return snip_table

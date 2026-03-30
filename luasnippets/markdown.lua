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

---@param str string
local function parse_time(str)
  local h, m = str:match '(%d+):(%d+)'
  if h then
    return tonumber(h) * 60 + tonumber(m)
  end
  return nil
end

---@param diff number
local function format_duration(diff)
  if diff < 0 then
    diff = diff + 24 * 60
  end
  local h, m = math.floor(diff / 60), diff % 60
  if h == 0 then
    return m .. '分钟'
  elseif m == 0 then
    return h .. '小时'
  else
    return h .. '小时' .. m .. '分钟'
  end
end

local function calc_duration()
  local line = vim.api.nvim_get_current_line()
  local cells = {}
  for cell in line:gmatch '|([^|]+)' do
    cells[#cells + 1] = vim.trim(cell)
  end
  -- | Start Time | Activity | End Time | Duration |
  --   cells[1]     cells[2]   cells[3]   cells[4]
  local s = parse_time(cells[1] or '')
  local e = parse_time(cells[3] or '')
  if s and e then
    return format_duration(e - s)
  end
  return ''
end

local function prev_end_time()
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  if row < 2 then
    return ''
  end
  local prev = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1]
  if not prev then
    return ''
  end
  local cells = {}
  for cell in prev:gmatch '|([^|]+)' do
    cells[#cells + 1] = vim.trim(cell)
  end
  return cells[3] and cells[3]:match '%d+:%d+' or ''
end

local snip_table = {
  s({ trig = '|', name = 'time-tracking next row', wordTrig = false, condition = conds.line_begin }, {
    t '| ',
    f(function()
      return prev_end_time()
    end), -- 自动填上一行的 End Time
    t ' | ',
    i(0),
  }),
  s({
    trig = '(|%s*%d%d:%d%d%s*|[^|]+|)',
    regTrig = true,
    wordTrig = false,
    name = 'time-tracking row',
    dscr = 'Complete a time-tracking table row: append end time and computed duration',
  }, {
    d(1, function(_, snip)
      local matched = snip.captures[1]
      local start_str = matched:match '%d%d:%d%d'
      local end_time = os.date '%H:%M'
      local duration = format_duration(parse_time(end_time) - parse_time(start_str))
      return sn(nil, {
        t(matched .. ' ' .. end_time .. ' | ' .. duration .. ' '),
      })
    end),
    i(0), -- 外层 exit，文本位置在 | 之前
    t ' |',
  }),
  s({
    trig = '(|%s*%d%d:%d%d%s*|[^|]+|%s*%d%d:%d%d%s*|)',
    regTrig = true,
    wordTrig = false,
    name = 'time-tracking duration',
    dscr = 'Append computed duration after start + end time columns',
  }, {
    d(1, function(_, snip)
      local matched = snip.captures[1]
      local times = {}
      for t in matched:gmatch '%d%d:%d%d' do
        times[#times + 1] = t
      end
      local duration = ''
      if times[1] and times[2] then
        duration = format_duration(parse_time(times[2]) - parse_time(times[1]))
      end
      return sn(nil, {
        t(matched .. ' ' .. duration),
      })
    end),
    i(0),
    t ' |',
  }),
  s('dur', { f(calc_duration) }),
  parse(
    { trig = 'tt', name = 'time tracking', condition = conds.line_begin },
    [[
| Start Time | Activity          | End Time | Duration |
| :--------- | :---------------- | :------- | :------- |
|   $0   |          |          |          |
]]
  ),
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

  parse({ trig = 'dm', name = 'Block Math', priority = 1, condition = conds.line_begin, snippetType = 'autosnippet' }, '\\$\\$${0:${TM_SELECTED_TEXT}}\\$\\$'),
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

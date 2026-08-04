local M = {}

-- local s = ls.snippet
-- local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
-- local t = ls.text_node
-- local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node
-- local events = require("luasnip.util.events")
-- local r = require("luasnip.extras").rep
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta

M.pipe = function(fns)
  return function(...)
    for _, fn in ipairs(fns) do
      if not fn(...) then
        return false
      end
    end

    return true
  end
end

M.no_backslash = function(line_to_cursor, matched_trigger)
  return not line_to_cursor:find('\\%a+$', -#line_to_cursor)
end

-- 逗号触发的 snippet: 前一个字符若是操作数结尾（字母/数字/闭括号/点/引号），
-- 说明这个逗号是列表分隔符（`f(x,y)`、`(2,6)`），不展开。
-- 允许: 行首、空白、开括号、`^` `_` `/` 等运算符、以及 `,` 本身（双逗号 snippet）。
M.not_after_operand = function(line_to_cursor, matched_trigger)
  local before = line_to_cursor:sub(1, #line_to_cursor - #matched_trigger)
  local char = before:sub(-1)
  return char == '' or char:match [==[[%w%)%]%}%.'"]]==] == nil
end

local ts_utils = require 'util.ts_utils'
M.is_math = function(treesitter)
  if treesitter then
    return ts_utils.in_mathzone()
  end

  return vim.fn['vimtex#syntax#in_mathzone']() == 1
end

M.not_math = function(treesitter)
  if treesitter then
    return ts_utils.in_text(true)
  end

  return not M.is_math()
end

M.comment = function()
  return vim.fn['vimtex#syntax#in_comment']() == 1
end

M.env = function(name)
  local x, y = unpack(vim.fn['vimtex#env#is_inside'](name))
  return x ~= '0' and y ~= '0'
end

M.with_priority = function(snip, priority)
  snip.priority = priority
  return snip
end

M.with_opts = function(fn, opts)
  return function()
    return fn(opts)
  end
end

return M

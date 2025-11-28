local ls = require 'luasnip'

local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet
local ps = ls.parser.parse_snippet

return {
  ps(
    'fn',
    [[
      function $1($2)
        $0
      end
    ]]
  ),
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

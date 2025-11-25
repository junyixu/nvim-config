local ls = require 'luasnip'

local t = ls.text_node
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

return {
  s('bg', {
    f(function(args, snip)
      local env = snip.env
      local selected_lines = env.LS_SELECT_RAW

      if not selected_lines then
        return {
          'begin',
          'end',
        }
      end

      local result = { 'begin' }

      -- 处理不同类型：table 或 string
      if type(selected_lines) == 'table' then
        -- 如果是表格，遍历所有行
        for _, line in ipairs(selected_lines) do
          table.insert(result, '    ' .. line)
        end
      elseif type(selected_lines) == 'string' then
        -- 如果是字符串，分割为行
        for line in selected_lines:gmatch '[^\n]+' do
          table.insert(result, '    ' .. line)
        end
      end

      table.insert(result, 'end')

      return result
    end, {}),
  }),
}

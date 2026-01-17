---@diagnostic disable: undefined-global
---@global s

local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local f = ls.function_node
local d = ls.dynamic_node
local parse = ls.parser.parse_snippet
local rep = require('luasnip.extras').rep
local fmt = require('luasnip.extras.fmt').fmt

local get_test_result = function(position)
  return d(position, function()
    local nodes = {}
    table.insert(nodes, t ' ')
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for _, line in ipairs(lines) do
      if line:match 'anyhow::Result' then
        table.insert(nodes, t ' -> Result<()>')
        -- print(vim.inspect(lines))
        break
      end
    end
    return sn(nil, c(1, { t 'example 1', t 'example 2', t 'final' }))
  end, {})
end

return {
  s(
    'test',
    fmt(
      [[
        #[test]
        fn {}(){}{{
            {}
        }}
      ]],
      {
        i(1, 'testname'),
        get_test_result(2),
        i(0),
      }
    )
  ),
}

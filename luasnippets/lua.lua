---@diagnostic disable: undefined-global
---@global s

local ls = require 'luasnip'
local s = ls.snippet
local f = ls.function_node
local d = ls.dynamic_node
local parse = ls.parser.parse_snippet
local rep = require('luasnip.extras').rep
local fmt = require('luasnip.extras.fmt').fmt

local same = function(index)
  return f(function(arg)
    print(vim.inspect(arg))
    return arg[1]
  end, { index, index })
end

return {
  -- https://youtu.be/KtQZRAkgLqo?t=808
  s(
    'req',
    fmt([[local {} = require("{}")]], {
      f(function(import_name)
        local line = vim.api.nvim_buf_set_lines(0, 0, -1, false)
        -- import_name: { {'abc'}, {'abc'} }
        -- import_name[1]: {'abc'}
        -- import_name[1][1]: 'abc'
        local str = import_name[1][1]
        local parts = vim.split(str, '.', { plain = true })
        return parts[#parts] or ''
      end, { 1 }),
      i(1),
    })
  ),
  s('sametest', fmt([[example: {}, function {}]], { i(1), same(1) })),
  parse(
    'lf',
    [[
      local $1 = function($2)
        $0
      end
    ]]
  ),
  -- s('req', fmt("local {} = require('{}')", { i(1, 'default'), rep(1) })),
}

---@diagnostic disable: undefined-global
---@global s

local ls = require 'luasnip'
local s = ls.snippet
local ps = ls.parser.parse_snippet
-- local rep = require('luasnip.extras').rep
local fmt = require('luasnip.extras.fmt').fmt

return {
  ps(
    'lf',
    [[local $1 = function($2)
  $0
end]]
  ),
  s('req', fmt("local {} = require('{}')", { i(1, 'default'), rep(1) })),
}

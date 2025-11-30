local ls = require 'luasnip'

local fmt = require('luasnip.extras.fmt').fmt
local ps = ls.parser.parse_snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local f = ls.function_node
local s = ls.snippet

return {
  s(
    '---',
    fmt(
      [[
---
title: "{}"
format:
  html:
    code-fold: true
engine: {}
---

{}]],
      { i(1, 'Document Title'), c(2, { t 'julia', t 'jupyter' }), i(0) }
    )
  ),
}

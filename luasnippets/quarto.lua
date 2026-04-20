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
  -- YAML Front Matter
  -- YAML 前置元数据）或简称 Front Matter。
  -- 它的作用是定义文档的元数据和配置选项，
  -- 告诉渲染引擎如何处理这个文档。
  s(
    { trig = '---', name = 'YAML Front Matter', dscr = 'Insert YAML Front Matter for Quarto document' },
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

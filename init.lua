require 'essentials'
require 'lazy_nvim'
vim.lsp.enable 'julials'

-- local ls = require 'luasnip'
-- ls.add_snippets('markdown', require 'luasnippets.markdown')
-- ls.add_snippets('markdown', require('luasnip-latex-snippets.math_iA').retrieve())
-- ls.add_snippets('tex', require 'luasnippets.markdown')
--
-- local utils = require 'luasnip-latex-snippets.util.utils'
-- is_math = utils.with_opts(utils.is_math, true) -- true to use treesitter
-- not_math = utils.with_opts(utils.not_math, true) -- true to use treesitter
--
-- -- set a higher priority (defaults to 0 for most snippets)
-- local snip = ls.parser.parse_snippet({ trig = 'mk', name = 'Math', condition = utils.pipe { not_math }, priority = 10 }, '$ ${1:${TM_SELECTED_TEXT}} $$0')
--
-- ls.add_snippets('markdown', { snip }, {
--   type = 'autosnippets',
-- })

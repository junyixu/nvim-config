require 'essentials'
require 'lazy_nvim'
vim.lsp.enable 'julials'

local ls = require 'luasnip'
ls.add_snippets('markdown', require 'luasnippets.markdown')
ls.add_snippets('tex', require 'luasnippets.markdown')

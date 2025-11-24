require 'essentials'
require 'lazy_nvim'
vim.lsp.enable 'julials'
local ts_utils = require 'luasnip-latex-snippets.util.ts_utils'
is_math = ts_utils.in_mathzone

local ls = require 'luasnip'
-- ls.add_snippets('markdown', {'/home/junyi/.config/nvim/luasnippets/markdown.lua'})
-- require("dotfiles.luasnip.c")

local ls = require 'luasnip'

local t = ls.text_node
local i = ls.insert_node
local s = ls.snippet

local abcd = {
  s('mat', {
    t { '\\begin{bmatrix}', '\t' },
    i(1),
    t { '', '\\end{bmatrix}' },
  }, {
    condition = function()
      local val = is_math()
      print('mark', val)
      return val
    end,
    show_condition = function()
      local val = is_math()
      print('mark2', val)
      return val
    end,
  }),
}

ls.add_snippets('markdown', abcd)
ls.add_snippets('tex', abcd)

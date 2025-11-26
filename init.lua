require 'essentials'
require 'lazy_nvim'
vim.lsp.enable 'julials'

local fcitx = require 'fcitx'
if fcitx.loaded then
  local group = vim.api.nvim_create_augroup('FcitxToggle', { clear = true })
  local function guard(fn)
    return function()
      if vim.fn.reg_executing() == '' then
        fn()
      end
    end
  end
  local leave_event = vim.fn.exists '##InsertLeavePre' == 1 and 'InsertLeavePre' or 'InsertLeave'

  vim.api.nvim_create_autocmd(leave_event, {
    group = group,
    callback = guard(fcitx.fcitx2en),
  })
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = guard(fcitx.fcitx2zh),
  })
end

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

local julia_term = require 'custom.julia_term'

vim.keymap.set('n', '<leader>st', julia_term.open, { buffer = true, desc = 'open julia term' })
vim.keymap.set('n', '<leader>tt', julia_term.toggle, { buffer = true, desc = 'toggle julia term' })

local julia_ctags = require 'custom.julia_ctags'
julia_ctags.attach(0)

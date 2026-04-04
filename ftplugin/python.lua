local python_term = require 'custom.python_term'

vim.keymap.set('n', '<leader>st', python_term.open, { buffer = true, desc = 'open python term' })
vim.keymap.set('n', '<leader>tt', python_term.toggle, { buffer = true, desc = 'toggle python term' })

local julia_term = require 'custom.julia_term'

vim.keymap.set('n', '<space>st', julia_term.open, { buffer = true, desc = 'open julia term' })
vim.keymap.set('n', '<leader>tt', julia_term.toggle, { buffer = true, desc = 'toggle julia term' })

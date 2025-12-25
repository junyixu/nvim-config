local julia_term = require 'custom.julia_term'

vim.keymap.set('n', '<leader>st', julia_term.open, { buffer = true, desc = 'open julia term' })
vim.keymap.set('n', '<leader>tt', julia_term.toggle, { buffer = true, desc = 'toggle julia term' })
-- Keymap for toggling slime target
vim.keymap.set('n', '<localleader>st', julia_term.toggle_slime_target, { buffer = true, desc = 'toggle slime target between kitty/neovim' })

local julia_ctags = require 'custom.julia_ctags'
julia_ctags.attach(0)

local julia_gtags = require 'custom.julia_gtags'
julia_gtags.attach(0)

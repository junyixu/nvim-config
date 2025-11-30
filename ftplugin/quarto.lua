-- Quarto filetype specific keymaps

local slime_term = require 'custom.slime_term'
slime_term.ensure()

local julia_term = require 'custom.julia_term'
local runner = require 'quarto.runner'

-- Run cell with Ctrl+Enter
vim.keymap.set('n', '<C-CR>', runner.run_cell, { buffer = true, desc = 'run cell', silent = true })

-- Run line with Enter
vim.keymap.set('n', '<CR>', runner.run_line, { buffer = true, desc = 'run line', silent = true })

-- Run operations with localleader
vim.keymap.set('n', '<localleader>rc', runner.run_cell, { buffer = true, desc = 'run cell', silent = true })
vim.keymap.set('n', '<M-CR>', runner.run_cell, { buffer = true, desc = 'run cell', silent = true })
vim.keymap.set('n', '<S-CR>', runner.run_cell, { buffer = true, desc = 'run cell', silent = true })
vim.keymap.set('n', '<localleader>ra', runner.run_above, { buffer = true, desc = 'run cell and above', silent = true })
vim.keymap.set('n', '<localleader>rA', runner.run_all, { buffer = true, desc = 'run all cells', silent = true })
vim.keymap.set('v', '<localleader>r', runner.run_range, { buffer = true, desc = 'run visual range', silent = true })
vim.keymap.set('n', '<localleader>RA', function()
  runner.run_all(true)
end, { buffer = true, desc = 'run all cells of all languages', silent = true })

vim.keymap.set('n', '<space>st', julia_term.open, { buffer = true, desc = 'open julia term' })
vim.keymap.set('n', '<M-=>', julia_term.toggle, { buffer = true, desc = 'toggle julia term' })

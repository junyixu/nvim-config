-- Keymaps configuration

--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>qf', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- `clipboard=autoselect` is not implemented yet
-- https://github.com/neovim/neovim/issues/2325.
-- You may find this workaround to be useful:
vim.keymap.set('v', '<LeftRelease>', '"*ygv', { desc = 'Yank selection to primary clipboard' })
vim.keymap.set('v', '<2-LeftRelease>', '"*ygv', { desc = 'Yank selection to primary  clipboard' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
-- vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<M-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<M-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<M-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<M-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<M-w>', '<C-w>', { remap = true, desc = 'Enter window command mode' })
vim.keymap.set('n', '<M-w><M-w>', '<C-w>p', { desc = 'back to the last window' })
vim.keymap.set('n', '<M-w><M-t>', '<C-w>T', { desc = 'Move window to new tab' })
vim.keymap.set('n', '<M-w>p', '<C-w>P', { desc = 'Move to previous window' })
-- vim.keymap.set('n', '<C-]>', '<C-w>}', { desc = 'Show definition in preview window' })
vim.keymap.set('n', 'ss', '<C-w><C-s>', { desc = 'Split the window horizontally' })
vim.keymap.set('n', 'sp', '<C-w>p', { desc = 'back to the last window' })
vim.keymap.set('n', 's=', '<C-w>=', { desc = 'Window equal size' })
vim.keymap.set('n', 'sT', '<C-w>T', { desc = 'Move window to new tab' })
vim.keymap.set('n', 'sv', '<C-w><C-v>', { desc = 'Split the window vertically' })
vim.keymap.set('n', 'so', '<C-w>o', { desc = 'Window [o]nly' })
vim.keymap.set('n', 'sO', '<CMD>tab split<CR>', { desc = 'Split the window in a new tab' })
vim.keymap.set('n', '<M-q>', '<CMD>q<CR>', { desc = 'Quit the current window' })
vim.keymap.set('n', '<M-Q>', '<CMD>tabc<CR>', { desc = 'Close the current tab' })
vim.keymap.set('n', 'sq', '<CMD>q<CR>', { desc = 'Quit the current window' })
vim.keymap.set('n', '<M-z>', '<CMD>wq<CR>', { desc = 'Save and quit the current window' })

vim.keymap.set('n', '<C-n>', '<CMD>cnext<CR>', { desc = 'cnext' })
vim.keymap.set('n', '<C-p>', '<CMD>cprev<CR>', { desc = 'cnext' })

vim.keymap.set('n', 'cd', ':tcd %:h<CR>', { desc = 'cd for current tab' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
vim.keymap.set('n', 'M-H>', '<C-w>H', { desc = 'Move window to the left' })
vim.keymap.set('n', '<M-L>', '<C-w>L', { desc = 'Move window to the right' })
vim.keymap.set('n', '<M-J>', '<C-w>J', { desc = 'Move window to the lower' })
vim.keymap.set('n', '<M-K>', '<C-w>K', { desc = 'Move window to the upper' })
vim.keymap.set('t', '<M-n>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
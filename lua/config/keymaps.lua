-- Keymaps configuration
-- See `:help vim.keymap.set()`

-- Helper function for normal mode keymaps (nnoremap equivalent)
local function nnoremap(lhs, rhs, opts)
  local defaults = { noremap = true, silent = true }
  local options = vim.tbl_extend('force', defaults, opts or {})
  vim.keymap.set('n', lhs, rhs, options)
end

local function nmap(lhs, rhs, opts)
  local defaults = { noremap = false, silent = true }
  local options = vim.tbl_extend('force', defaults, opts or {})
  vim.keymap.set('n', lhs, rhs, options)
end

-- Helper function for visual mode keymaps (vnoremap equivalent)
local function vnoremap(lhs, rhs, opts)
  local defaults = { noremap = true, silent = true }
  local options = vim.tbl_extend('force', defaults, opts or {})
  vim.keymap.set('v', lhs, rhs, options)
end

local function vmap(lhs, rhs, opts)
  local defaults = { noremap = false, silent = true }
  local options = vim.tbl_extend('force', defaults, opts or {})
  vim.keymap.set('v', lhs, rhs, options)
end

--  See `:help hlsearch`
nnoremap('<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
nnoremap('<leader>qf', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- `clipboard=autoselect` is not implemented yet
-- https://github.com/neovim/neovim/issues/2325.
-- You may find this workaround to be useful:
vnoremap('<LeftRelease>', '"*ygv', { desc = 'Yank selection to primary clipboard' })
vnoremap('<2-LeftRelease>', '"*ygv', { desc = 'Yank selection to primary  clipboard' })

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
nnoremap('<M-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
nnoremap('<M-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
nnoremap('<M-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
nnoremap('<M-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
nnoremap('<M-H>', '<C-w>H', { desc = 'Move window to the left' })
nnoremap('<M-L>', '<C-w>L', { desc = 'Move window to the right' })
nnoremap('<M-J>', '<C-w>J', { desc = 'Move window to the lower' })
nnoremap('<M-K>', '<C-w>K', { desc = 'Move window to the upper' })
nnoremap('<M-w>', '<C-w>', { desc = 'Enter window command mode' })
nnoremap('<M-w><M-w>', '<C-w>p', { desc = 'back to the last window' })
nnoremap('<M-w><M-t>', '<C-w>T', { desc = 'Move window to new tab' })
-- nnoremap('<C-]>', '<C-w>}', { desc = 'Show definition in preview window' })
nnoremap('<M-w>O', '<CMD>tab split<CR>', { desc = 'Split the window in a new tab' })
nnoremap('<M-q>', '<CMD>q<CR>', { desc = 'Quit the current window' })
nnoremap('<M-Q>', '<CMD>tabc<CR>', { desc = 'Close the current tab' })
nnoremap('<M-z>', '<CMD>wq<CR>', { desc = 'Save and quit the current window' })
nnoremap('<C-s>', '<CMD>w<CR>', { desc = 'Save current buffer' })

-- Switch tabs quickly with Alt+number (matches the tabline prefix "1.", "2.", ...).
for i = 1, 9 do
  nnoremap(string.format('<M-%d>', i), string.format('%dgt', i), { desc = string.format('Go to tab %d', i) })
end

nnoremap('<C-n>', '<CMD>cnext<CR>', { desc = 'cnext' })
nnoremap('<C-p>', '<CMD>cprev<CR>', { desc = 'cnext' })

nnoremap('j', 'gj')
nnoremap('k', 'gk')
nnoremap('gj', 'j')
nnoremap('gk', 'k')
vnoremap('j', 'gj')
vnoremap('k', 'gk')
vnoremap('gj', 'j')
vnoremap('gk', 'k')

nnoremap('cd', ':tcd %:h<CR>', { desc = 'cd for current tab' })
-- cmap  expand("")<left><left>
vim.keymap.set('c', '<C-->', 'expand("")<left><left>', { desc = 'Insert word under cursor' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
vim.keymap.set('t', '<M-n>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('v', '<M-f>', function()
  vim.lsp.buf.format()
  vim.cmd.normal() -- 回到 normal 模式
end, {
  silent = true,
  desc = 'Format selection',
})

local git_merge = require 'util.gitmerge'
vim.keymap.set('n', '<leader>gh', function()
  git_merge.smart_diffget(2)
end, { desc = 'Get LOCAL and clean markers' })
vim.keymap.set('n', '<leader>gl', function()
  git_merge.smart_diffget(3)
end, { desc = 'Get REMOTE and clean markers' })

vim.keymap.set('n', '<leader>*', function()
  local cword = vim.fn.expand '<cword>'
  local ext = vim.fn.expand '%:e'
  local target = (ext ~= '') and ('**/*.' .. ext) or '*'
  -- 构造完整的命令字符串; 使用 <kbd> 控制符让命令出现在 command line 但不立即执行
  local cmd = string.format(':vimgrep /%s/ %s', cword, target)
  -- 将命令喂给命令行模式 (feedkeys)
  -- 'n' 表示不递归映射，true 表示转义内容
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), 'n', false)
end, { desc = 'Vimgrep word under cursor with current extension' })

-- resize windwos
-- Alt + < (即 Alt + Shift + ,)
vim.keymap.set('n', '<M-S-,>', '10<C-w><', { desc = 'Decrease window width' })
-- Alt + > (即 Alt + Shift + .)
vim.keymap.set('n', '<M-S-.>', '10<C-w>>', { desc = 'Increase window width' })
-- Alt + Shift + =
vim.keymap.set('n', '<M-S-=>', '<C-w>+<C-w>+<C-w>+<C-w>+<C-w>-')
-- Alt + Shift + -
vim.keymap.set('n', '<M-S-->', '<C-w>-<C-w>-<C-w>-<C-w>-<C-w>+')

vim.cmd [[nnoremap <leader>gdv :Gvdiffsplit<cr>
nnoremap <leader>gds :Ghdiffsplit<cr>
]]
-- if vim.env.TERM == 'xterm-kitty' then
--   local term = vim.api.nvim_replace_termcodes
--   vim.keymap.set({ 'n', 'i', 'v' }, term('<Esc>[9;2u', true, true, true), 'j', { noremap = true })
--   vim.keymap.set({ 'n', 'i', 'v' }, term('<Esc>[9002;1u', true, true, true), '<M-S-CR>', { noremap = true })
--   --   -- vim.keymap.set({ 'n', 'i', 'v' }, term('<Esc>[9;2u', true, true, true), '<Tab>', { noremap = true })
--   --   vim.keymap.set({ 'n', 'i', 'v' }, term('<Esc>[105;5u', true, true, true), '<C-i>', { noremap = true })
--   --   vim.keymap.set({ 'n', 'i', 'v' }, term('<Esc>[13;2u', true, true, true), '<CR>', { noremap = true })
--   --   vim.keymap.set({ 'n', 'i', 'v' }, term('<Esc>[109;5u', true, true, true), '<C-m>', { noremap = true })
--   -- vim.cmd [[
--   -- nnoremap <silent> <M-CR> :tabnew<CR>
--   -- nnoremap <silent> <M-S-CR> :tabclose<CR>
--   -- ]]
-- end
-- vim.cmd [[
-- let &t_TI = "\<Esc>[>4;2m"
-- let &t_TE = "\<Esc>[>4;m"
-- "nnoremap <Tab>f :tabnext<CR>
-- "nnoremap <C-I>f :tabprev<CR>
-- ]]
--
-- Clear highlights on search when pressing <Esc> in normal mode
-- Keymaps moved to config/keymaps.lua

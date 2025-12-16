--[[
What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ','
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
--  我希望同步 * 剪贴板，而不是 + 剪贴板
vim.schedule(function()
  vim.o.clipboard = 'unnamed'
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

--  设置 diffopt 选项，确保包含 'vertical'
-- 'vertical' 告诉 Vim 在 diff 模式下优先使用垂直分屏 (vsplit)
vim.opt.diffopt:append 'vertical'

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
-- vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- `/` 搜索完整个文档，就从头搜索; wrapping back to the start of the file
vim.o.wrapscan = true

-- [[ Basic Keymaps ]]
-- See `:help vim.keymap.set()`

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

-- command! -nargs=1 -complete=file E execute 'edit' split(<q-args>, ':')[0] | execute split(<q-args>, ':')[1]
vim.api.nvim_create_user_command('E', function(opts)
  local parts = vim.split(opts.args, ':', { plain = true })
  local file = parts[1] or ''
  local cmd = parts[2]

  if file:sub(1, 1) == '@' then
    file = file:sub(2)
  end
  if file == '' then
    vim.notify('E command expects {file}:{cmd}', vim.log.levels.ERROR)
    return
  end

  vim.cmd.tabedit(file)
  if cmd and cmd ~= '' then
    vim.cmd(cmd)
  end
end, { nargs = 1, complete = 'file' })

vim.keymap.set('v', '<M-f>', function()
  vim.lsp.buf.format()
  vim.cmd.normal() -- 回到 normal 模式
end, {
  silent = true,
  desc = 'Format selection',
})

-- vim.keymap.set('n', '-', '<CMD>Explore %:h<CR>', { desc = 'Netrw pwd; minic vinegar and oil' })
-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})
-- 等价于
--  augroup kickstart-highlight-yank
--     autocmd!
--     autocmd TextYankPost * silent! lua vim.hl.on_yank()
--  augroup END

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

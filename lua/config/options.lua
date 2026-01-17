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
  if vim.g.has_wl_copy then
    if vim.g.is_wsl then
      vim.o.clipboard = 'unnamedplus'
      return
    end
    vim.o.clipboard = 'unnamed'
  end
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
vim.o.timeoutlen = 500

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

vim.opt.previewheight = 12

-- Minimal number of screen lines to keep above and below the cursor.
-- vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- `/` 搜索完整个文档，就从头搜索; wrapping back to the start of the file
vim.o.wrapscan = true

-- NOTE:
-- --vimgrep 是一个复合参数。根据官方文档，使用 --vimgrep 时，它会自动开启（隐含）以下选项：
--    --column (输出列号)
--    --line-number (输出行号)
--    --no-heading (不按文件分组，每行都重复文件名)
--    --with-filename (即 -H，显示文件名)
--    --color never (禁用颜色，方便 Vim 解析)
-- NOTE:
-- 可以手动加
-- -S, --smart-case 选项，让 rg 支持智能大小写搜索
-- -i, --ignore-case 选项，让 rg 忽略大小写搜索
-- -s, --case-sensitive 选项，让 rg 区分大小写搜索
-- -w 选项，匹配一个完整的单词

if vim.fn.executable 'rg' == 1 then
  -- 去掉官方加的 -uu，让 rg 尊重 .gitignore 并且不搜索隐藏文件
  vim.opt.grepprg = 'rg --vimgrep'
  -- vim.opt.grepprg = 'rg --vimgrep --follow' -- follow 选项让 rg 跟随符号链接
  vim.opt.grepformat = '%f:%l:%c:%m'
end

-- 补充一个常见坑（你输出里出现了 2>&1| tee ...）：因为你 shellpipe 用了
-- tee，在 zsh 里默认会把管道退出码变成 tee 的退出码，v:shell_error 常常
-- 会变成 0（即使 julia 失败）。如果你有依赖退出码的自动逻辑（比如只在失
-- 败时自动打开 loclist），可以在 init.lua 里加：
vim.opt.shellcmdflag = '-o pipefail -c'

-- Tabline: prefix each tab with its index (1., 2., ...) and keep window count suffix.
require('custom.tabline').setup()

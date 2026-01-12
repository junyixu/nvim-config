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
-- nnoremap('<C-]>', '<C-w>}', { desc = 'Show definition in preview window' })
nnoremap('<M-w>O', '<CMD>tab split<CR>', { desc = 'Split the window in a new tab' })
nnoremap('<M-q>', '<CMD>q<CR>', { desc = 'Quit the current window' })
nnoremap('<M-Q>', '<CMD>tabc<CR>', { desc = 'Close the current tab' })
nnoremap('<M-z>', '<CMD>wq<CR>', { desc = 'Save and quit the current window' })
nnoremap('<C-s>', '<CMD>w<CR>', { desc = 'Save current buffer' })

vim.keymap.set('n', '%', function()
  -- 1. 获取当前 buffer 的 parser 和光标下的 node
  local bufnr = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node { bufnr = bufnr, ignore_injections = false }

  if not node then
    return '%'
  end

  -- 2. 定义 Julia 中具有 "end" 的容器节点类型
  -- Julia 的 AST 中，function_definition, if_statement 等通常包含 'end' 符号
  local container_types = {
    'function_definition',
    'if_statement',
    'for_statement',
    'while_statement',
    'struct_definition',
    'module_definition',
    'quote_expression',
    'let_statement',
    'do_clause',
    'try_statement',
  }

  -- 3. 向上寻找最近的容器节点
  local parent = node
  while parent do
    local p_type = parent:type()
    local is_container = false
    for _, t in ipairs(container_types) do
      if p_type == t then
        is_container = true
        break
      end
    end
    if is_container then
      break
    end
    parent = parent:parent()
  end

  if not parent then
    return vim.api.nvim_feedkeys('%', 'n', true)
  end

  -- 4. 获取该容器的起始位置和结束位置 (end 关键字)
  local start_row, start_col = parent:start()
  local end_row, end_col = parent:end_()

  -- 5. 获取当前光标位置 (0-indexed)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row, cur_col = cursor[1] - 1, cursor[2]

  -- 6. 跳转逻辑：如果在开头则跳到末尾，否则跳回开头
  -- 注意：Julia 的 end 通常占据最后一行，我们要跳到 'end' 这个词上
  if cur_row == start_row then
    -- 跳到末尾的 'end' (通常是 end_row, end_col 前面 3 个字符)
    vim.api.nvim_win_set_cursor(0, { end_row + 1, math.max(0, end_col - 3) })
  else
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
end, { desc = 'TS 原生跳转 (Julia function/end)' })

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

vim.keymap.set('n', '<leader>*', require('util.search').search_cword_in_buffers, {
  desc = 'Search cword in all open buffers',
})
-- NOTE:
-- 如何清空 qf
--  :cexpr []
--  or
--  :cex []

-- Visual Mode: 搜索选中的文本
vim.keymap.set('x', '<leader>*', function()
  -- 1. 获取选中的文本
  local region = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
  local text = table.concat(region, '\n')

  -- 2. 处理转义：使用 shellescape 替代手动 escape
  local pattern = vim.fn.shellescape(text)

  -- 3. 确定范围
  local ext = vim.fn.expand '%:e'
  local target = (ext ~= '') and ('**/*.' .. ext) or '*'

  -- 4. 构造命令
  local cmd = string.format(':silent grep %s %s', pattern, target)

  -- 5. 执行 feedkeys，先 Esc 退出 visual mode
  local keys = vim.api.nvim_replace_termcodes('<Esc>' .. cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end, { desc = 'Grep selection with current extension' })

-- resize windwos
-- Alt + < (即 Alt + Shift + ,)
vim.keymap.set('n', '<M-S-,>', '10<C-w><', { desc = 'Decrease window width' })
-- Alt + > (即 Alt + Shift + .)
vim.keymap.set('n', '<M-S-.>', '10<C-w>>', { desc = 'Increase window width' })
-- Alt + Shift + =
vim.keymap.set('n', '<M-S-=>', '<C-w>+<C-w>+<C-w>+<C-w>+<C-w>-')
-- Alt + Shift + -
vim.keymap.set('n', '<M-S-->', '<C-w>-<C-w>-<C-w>-<C-w>-<C-w>+')

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  group = vim.api.nvim_create_augroup('QuickFixCustomMappings', { clear = true }),
  callback = function()
    local opts = { buffer = true, silent = true }

    -- 垂直分割打开 (Vertical Split)
    vim.keymap.set('n', '<C-v>', function()
      local qf_idx = vim.fn.line '.' -- 获取当前 quickfix 列表的索引
      vim.cmd 'wincmd p' -- 返回跳转前的上一个窗口 (previous window)
      vim.cmd 'vsplit' -- 在主编辑区开启垂直分割
      vim.cmd(qf_idx .. 'cc') -- 跳转到该索引对应的 quickfix 条目
    end, opts)

    -- 水平分割打开 (Horizontal Split)
    vim.keymap.set('n', '<C-s>', function()
      local qf_idx = vim.fn.line '.'
      vim.cmd 'wincmd p'
      vim.cmd 'split'
      vim.cmd(qf_idx .. 'cc')
    end, opts)

    -- 新标签页打开 (New Tab)
    vim.keymap.set('n', '<C-t>', function()
      local qf_idx = vim.fn.line '.'
      vim.cmd 'tabnew' -- 先开新标签页
      vim.cmd(qf_idx .. 'cc') -- 在新标签页里跳转
    end, opts)
  end,
})

vim.keymap.set('v', 'gy', function()
  -- 使用 nvim_feedkeys 模拟真实的按键操作
  -- 'x' 模式表示同步执行，这样后续的代码能立刻拿到寄存器内容
  local keys = vim.api.nvim_replace_termcodes('"ay', true, false, true)
  vim.api.nvim_feedkeys(keys, 'x', false)

  -- 2. 使用原生 API 获取寄存器 a 的内容
  local content = vim.fn.getreg 'a'

  -- 3. OSC 52 的 copy 函数要求输入是一个 table（每一行是一个元素）
  -- 我们使用 vim.split 将获取到的内容按换行符切割
  local lines = vim.split(content, '\n', { plain = true })

  -- 4. 调用内置 OSC 52 handler 发送到 '*'
  -- 注意：require('...').copy('*') 返回的是一个处理函数，所以后面要再跟一个 ()
  require('vim.ui.clipboard.osc52').copy '*'(lines)

  -- 可选：在命令行显示提示
  print "已同步到寄存器 'a' 和本地 Primary (*)"
end, { desc = 'Copy selection to reg a and send via OSC 52 to *' })

vim.keymap.set('n', '<leader>cf', function()
  if vim.fn.exists ':Cfilter' == 2 then
    return ':Cfilter! //<Left>'
  else
    -- 先加载 cfilter，然后执行命令，最后左移一格让光标停在 // 中间
    return ':packadd cfilter | Cfilter! //<Left>'
  end
end, { expr = true, desc = 'Quickfix filter (exclude)' })
-- NOTE:
-- 如果过滤错了，执行一次 :colder 就能退回上一步。

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

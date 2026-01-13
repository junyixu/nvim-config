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

-- 先检查光标下的字符是否为括号（parentheses, brackets, or braces）。如果是，则直接触发 do_fallback()，让原本的 matchit 插件来处理成对跳转。
local function ts_matchit_jump()
  local bufnr = vim.api.nvim_get_current_buf()
  local mode = vim.api.nvim_get_mode().mode

  -- 1. 定义 Fallback 映射表
  local fallback_map = {
    n = '<Plug>(MatchitNormalForward)',
    v = '<Plug>(MatchitVisualForward)',
    V = '<Plug>(MatchitVisualForward)',
    ['\22'] = '<Plug>(MatchitVisualForward)', -- CTRL-V
    o = '<Plug>(MatchitOperationForward)',
  }

  local fallback_key = fallback_map[mode:sub(1, 1)] or fallback_map['n']

  local function do_fallback()
    local key = vim.api.nvim_replace_termcodes(fallback_key, true, false, true)
    vim.api.nvim_feedkeys(key, 'm', false)
  end

  -- --- 新增逻辑：检查光标下是否为括号 ---
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  -- 获取光标下的字符 (注意 Lua 索引从 1 开始)
  local char = line:sub(col + 1, col + 1)

  -- 如果光标下是常见的配对符号，直接使用 matchit
  if char:find '[%%(%)%[%]{}]' then
    return do_fallback()
  end
  -- ------------------------------------

  -- 2. 检查 Tree-sitter 可用性
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return do_fallback()
  end

  local node = vim.treesitter.get_node { bufnr = bufnr, ignore_injections = false }
  if not node then
    return do_fallback()
  end

  -- 3. Julia 块容器类型
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
    'macro_definition',
  }

  -- 4. 向上寻找最近的容器节点
  local parent = node
  while parent do
    local p_type = parent:type()
    local found = false
    for _, t in ipairs(container_types) do
      if p_type == t then
        found = true
        break
      end
    end
    if found then
      break
    end
    parent = parent:parent()
  end

  if not parent then
    return do_fallback()
  end

  -- 5. 计算跳转位置
  local start_row, start_col = parent:start()
  local end_row, end_col = parent:end_()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cur_row = cursor[1] - 1

  if cur_row == start_row then
    -- 跳到末尾 end 关键字
    -- 这里减 3 是为了粗略对准 'end' 的位置，matchit 通常能更精确
    vim.api.nvim_win_set_cursor(0, { end_row + 1, math.max(0, end_col - 3) })
  else
    -- 跳到起始关键字 (function, if, 等)
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  end
end

-- 6. 绑定键位映射
-- n: 普通模式, x: 可视化模式 (不含 Select), o: 操作符等待模式
vim.keymap.set({ 'n', 'x', 'o' }, '%', ts_matchit_jump, { desc = 'TS Jump with Matchit Fallback' })
vim.keymap.set({ 'n', 'x', 'o' }, 'g%', '<Plug>(MatchitNormalBackward)')

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

vim.keymap.set('n', '<space>qo', ':copen<CR>', { desc = 'Open [Q]uickfix' })
vim.keymap.set('n', '<space>qc', ':cclose<CR>', { desc = 'Close [Q]uickfix' })
-- Diagnostic keymaps
nnoremap('<space>qf', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- resize windwos
-- Alt + < (即 Alt + Shift + ,)
vim.keymap.set('n', '<M-S-,>', '10<C-w><', { desc = 'Decrease window width' })
-- Alt + > (即 Alt + Shift + .)
vim.keymap.set('n', '<M-S-.>', '10<C-w>>', { desc = 'Increase window width' })
-- Alt + Shift + =
vim.keymap.set('n', '<M-S-=>', '<C-w>+<C-w>+<C-w>+<C-w>+<C-w>-')
-- Alt + Shift + -
vim.keymap.set('n', '<M-S-->', '<C-w>-<C-w>-<C-w>-<C-w>-<C-w>+')

-- 1. 封装底层的预览逻辑 (Shared Preview Logic)
local function qf_preview_logic(entry)
  if not (entry and entry.bufnr > 0) then
    return
  end

  local filename = vim.api.nvim_buf_get_name(entry.bufnr)
  -- 使用 noautocmd 防止激活 LSP
  vim.cmd('noautocmd pedit +' .. entry.lnum .. ' ' .. vim.fn.fnameescape(filename))

  -- 设置预览 Buffer 属性
  vim.api.nvim_set_option_value('buflisted', false, { buf = entry.bufnr })
  local ft = vim.filetype.match { filename = filename }
  if ft then
    vim.api.nvim_set_option_value('syntax', ft, { buf = entry.bufnr })
  end
end

-- 2. 封装全局导航逻辑 (Global Navigation & Preview)
local function qf_nav_and_preview(direction)
  local qf_info = vim.fn.getqflist { idx = 0, items = 0 }
  local items = qf_info.items
  local cur_idx = qf_info.idx

  if #items == 0 then
    print 'QuickFix list is empty'
    return
  end

  -- 计算新索引 (循环跳转)
  local new_idx
  if direction == 'next' then
    new_idx = cur_idx < #items and cur_idx + 1 or 1
  else
    new_idx = cur_idx > 1 and cur_idx - 1 or #items
  end

  -- 更新 QuickFix 列表的当前指向 (不移动焦点)
  vim.fn.setqflist({}, 'a', { idx = new_idx })

  -- 执行预览
  qf_preview_logic(items[new_idx])

  -- 同步：如果 QuickFix 窗口可见，移动其光标
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == 'quickfix' then
      vim.api.nvim_win_set_cursor(win, { new_idx, 0 })
    end
  end
end

-- 3. 设置全局快捷键 (Global Mappings)
vim.keymap.set('n', '<M-n>', function()
  qf_nav_and_preview 'next'
end, { desc = 'Next QF Entry & Preview' })
vim.keymap.set('n', '<M-p>', function()
  qf_nav_and_preview 'prev'
end, { desc = 'Prev QF Entry & Preview' })

-- 4. QuickFix 窗口内部的专用快捷键 (Buffer-local Mappings)
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  group = vim.api.nvim_create_augroup('QuickFixCustomMappings', { clear = true }),
  callback = function()
    local opts = { buffer = true, silent = true }

    -- 跳转到主窗口的逻辑 (显式寻找非 QF, 非 Preview 窗口)
    local function jump_to_main(split_cmd)
      local qf_idx = vim.fn.line '.'
      vim.cmd 'pclose'

      local target_win = nil
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not vim.bo[vim.api.nvim_win_get_buf(win)].buftype == 'quickfix' and not vim.wo[win].previewwindow then
          target_win = win
          break
        end
      end

      if target_win then
        vim.api.nvim_set_current_win(target_win)
      else
        vim.cmd 'wincmd k'
      end

      if split_cmd then
        vim.cmd(split_cmd)
      end
      vim.cmd(qf_idx .. 'cc')
    end

    -- 仅在 QF 窗口内生效的快捷键
    vim.keymap.set('n', 'p', function()
      local qf_idx = vim.fn.line '.'
      local items = vim.fn.getqflist()
      qf_preview_logic(items[qf_idx])
    end, opts)

    vim.keymap.set('n', '<C-v>', function()
      jump_to_main 'vsplit'
    end, opts)
    vim.keymap.set('n', '<C-s>', function()
      jump_to_main 'split'
    end, opts)
    vim.keymap.set('n', '<CR>', function()
      jump_to_main()
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

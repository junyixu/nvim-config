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

local qf = require 'util.quickfix'
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = vim.api.nvim_create_augroup('QuickfixEnhanced', { clear = true }),
  -- 包含 add 变体
  pattern = { 'vimgrep', 'vimgrepadd', 'grep', 'grepadd' },
  callback = function(args)
    -- 1. 先关闭旧的窗口，确保高度能重新计算
    vim.cmd 'cclose'

    -- 2. 获取命令并同步 Search Register
    local full_cmd = vim.fn.histget(':', -1)
    if full_cmd ~= '' then
      local raw_pattern = qf.extract_pattern(full_cmd)
      -- 只要是 vimgrep 家族，is_vimgrep 就为 true
      local is_vimgrep = args.match:find 'vimgrep' ~= nil
      local vim_pattern = qf.query_to_vim_regexp(raw_pattern, is_vimgrep)
      qf.sync_to_search_register(vim_pattern)
    end

    -- 3. 获取合并后的总条目数
    local qf_items = vim.fn.getqflist()
    if #qf_items > 0 then
      -- 动态计算高度，最大限制为 15 行
      local height = math.min(#qf_items, 15)
      -- cwindow 会自动根据 height 打开窗口，如果 list 为空则不打开
      vim.cmd('cwindow ' .. height)
    end

    -- 4. 针对外部 grep 命令执行 redraw
    if args.match:find 'grep' and not args.match:find 'vimgrep' then
      vim.cmd 'redraw!'
    end
  end,
})

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = vim.api.nvim_create_augroup('GrepRedraw', { clear = true }),
  pattern = { 'grep', 'grepadd' }, -- 仅针对 :grep 命令
  callback = function()
    vim.cmd 'redraw!'
  end,
})

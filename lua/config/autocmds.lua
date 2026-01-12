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
  pattern = { 'vimgrep', 'grep' },
  callback = function(args)
    -- 1. 获取刚刚执行的命令
    local full_cmd = vim.fn.histget(':', -1)
    if full_cmd == '' then
      return
    end

    -- 2. 提取并转换 Pattern
    local raw_pattern = qf.extract_pattern(full_cmd)
    local is_vimgrep = args.match == 'vimgrep'
    local vim_pattern = qf.query_to_vim_regexp(raw_pattern, is_vimgrep)

    -- 3. 同步寄存器
    qf.sync_to_search_register(vim_pattern)

    -- 4. 调整窗口高度
    local qf_items = vim.fn.getqflist()
    if #qf_items > 0 then
      local height = math.min(#qf_items, 15)
      vim.cmd('cwindow ' .. height)
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

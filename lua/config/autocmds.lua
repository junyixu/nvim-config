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
  -- 匹配所有 grep 相关命令
  pattern = { 'vimgrep', 'vimgrepadd', 'grep', 'grepadd' },
  callback = function(args)
    -- 1. 获取最终生成的 Quickfix 列表内容
    local qf_items = vim.fn.getqflist()
    local count = #qf_items

    -- 2. 同步 Search Register (保持你原有的 Pattern 提取逻辑)
    local full_cmd = vim.fn.histget(':', -1)
    if full_cmd ~= '' then
      local raw_pattern = qf.extract_pattern(full_cmd)
      local is_vimgrep = args.match:find 'vimgrep' ~= nil
      local vim_pattern = qf.query_to_vim_regexp(raw_pattern, is_vimgrep)
      qf.sync_to_search_register(vim_pattern)
    end

    -- 3. 动态设置高度并打开窗口
    if count > 0 then
      -- 强制关闭旧窗口以确保重新计算布局（可选，但能解决很多高度刷新不及时的问题）
      vim.cmd 'cclose'

      local height = math.min(count, 15)
      -- 使用 botright copen 确保窗口在底部打开并强制设置高度
      vim.cmd('botright copen ' .. height)

      -- 如果你不希望焦点跳到 Quickfix 窗口，可以执行 wincmd p 回到原窗口
      -- vim.cmd 'wincmd p'
    else
      -- 如果列表为空，确保关闭窗口
      vim.cmd 'cclose'
    end

    -- 4. 针对外部 grep (非 vimgrep) 强制重绘，解决外部进程输出导致的残影
    if args.match:find 'grep' and not args.match:find 'vimgrep' then
      vim.cmd 'redraw!'
    end
  end,
})

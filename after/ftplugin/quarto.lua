local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- 定义一个辅助函数，用于执行静默搜索跳转
local function jump_to_header(flags)
  -- 1. 手动添加当前位置到 jumplist
  -- 这样你跳转后，可以用 Ctrl-o 跳回原来的位置
  vim.cmd "normal! m'"

  -- 2. 使用 vim.fn.search 进行跳转
  -- 参数1: 正则表达式 '^#\\+\\s' (匹配标题)
  -- 参数2: flags ('W' 表示不循环搜索，'b' 表示向后)
  vim.fn.search('^#\\+\\s', flags)
end

-- [[ 向前跳转 (Backwards)
map('n', '[[', function()
  jump_to_header 'bW'
end, opts)

-- ]] 向后跳转 (Forwards)
map('n', ']]', function()
  jump_to_header 'W'
end, opts)

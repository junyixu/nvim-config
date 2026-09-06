-- gO: 通过 snacks picker 跳转 typst 标题 (tinymist 文档符号)
vim.keymap.set('n', 'gO', function()
  require('snacks').picker.lsp_symbols {
    layout = 'dropdown',
    tree = true,
  }
end, { buffer = 0, desc = 'Typst headings (snacks)' })

-- gP: 基于 ripgrep 扫描标题行, 不依赖 LSP 索引, 天然跨 #include 文件
-- (原打算用 gH, 但 gitsigns.lua 的全局 gHH/gHgh reset_hunk 会抢前缀, 改用 gP 避免冲突)
vim.keymap.set('n', 'gP', function()
  require('snacks').picker.grep {
    regex = true,
    live = false,
    glob = '*.typ',
    search = [[^\s*=+\s]],
    title = 'Typst Headings (rg)',
  }
end, { buffer = 0, desc = 'Typst headings across files (rg)' })

local tw = require 'junyi/typst_watch'

vim.api.nvim_buf_create_user_command(0, 'TypstWatch', tw.start, {})
vim.api.nvim_buf_create_user_command(0, 'TypstWatchStop', tw.stop, {})
vim.api.nvim_buf_create_user_command(0, 'TypstWatchToggle', tw.toggle, {})
vim.api.nvim_buf_create_user_command(0, 'TypstLog', tw.open_log, {})

vim.keymap.set('n', '<leader>tw', tw.toggle, { buffer = true, desc = 'Typst: toggle watch + zathura' })

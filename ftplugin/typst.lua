-- gO: 通过 snacks picker 跳转 typst 标题 (tinymist 文档符号)
vim.keymap.set('n', 'gO', function()
  require('snacks').picker.lsp_symbols {
    layout = 'dropdown',
    tree = true,
  }
end, { buffer = 0, desc = 'Typst headings (snacks)' })

local tw = require("junyi/typst_watch")

vim.api.nvim_buf_create_user_command(0, "TypstWatch",     tw.start,  {})
vim.api.nvim_buf_create_user_command(0, "TypstWatchStop", tw.stop,   {})
vim.api.nvim_buf_create_user_command(0, "TypstWatchToggle", tw.toggle, {})

vim.keymap.set("n", "<leader>tw", tw.toggle,
  { buffer = true, desc = "Typst: toggle watch + zathura" })

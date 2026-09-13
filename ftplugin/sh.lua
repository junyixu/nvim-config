-- 设置格式化时制表符占用空格数
vim.bo.shiftwidth = 2
-- 让 vim 把连续数量的空格视为一个制表符
vim.bo.softtabstop = 2
-- 设置编辑时制表符占用空格数
vim.bo.tabstop = 2

-- ===================== slime ======================
-- sh/bash 直接用 kitty 作为发送目标，不走内建终端（避免 "Terminal not found"）
vim.b.slime_target = 'kitty'

vim.keymap.set('n', '<CR>', '<Plug>SlimeLineSend', { buffer = true, silent = true, remap = true })
vim.keymap.set('x', '<CR>', '<Plug>SlimeRegionSend', { buffer = true, silent = true, remap = true })
vim.keymap.set('n', '<space><space>', '<Plug>SlimeParagraphSend', { buffer = true, silent = true, remap = true })
-- ===================== end slime ======================

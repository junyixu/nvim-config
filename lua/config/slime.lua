-- lua/config/slime.lua

-- 1. 设置 Slime 的目标会话类型 (Target)
-- 对于 NeoVim 内置终端，我们使用 'nvim'
vim.g.slime_target = 'nvim'

-- 2. 设置 Slime 的传输机制 (Transport)
-- 对于 NeoVim 内置终端，我们使用 'socket' (这是 nvim 目标默认使用的，但明确设置更好)
-- vim.g.slime_transport = 'socket' -- 实际上对于 target='nvim' 来说，这是默认行为，可以省略。

-- 3. 配置目标终端的名称 (Session Name)
-- 这是 Slime 识别目标终端的关键。
-- 默认情况下，Slime 会寻找一个名为 'v:term' 的终端缓冲区。
-- 如果你希望使用自定义名称，可以设置：
-- vim.g.slime_session = 'my_repl_session'

-- 4. 优化发送行为 (可选)
-- 自动发送回车键 (CR)
-- vim.g.slime_dont_ask_for_session = 1
vim.g.slime_autocall_CR = 1

-- 5. 映射快捷键 (可选，但强烈推荐)
-- Slime 默认使用 Leader s 和 Leader c，但如果你喜欢自定义，可以这样做：
vim.keymap.set('n', '<Leader>ss', '<Plug>SlimeParagraph', { desc = 'Slime: Send Paragraph' })
vim.keymap.set('v', '<Leader>ss', '<Plug>SlimeRegion', { desc = 'Slime: Send Region' })
vim.keymap.set('n', '<Leader>sc', '<Plug>SlimeConfig', { desc = 'Slime: Configure Target' })

-- 针对特定文件类型配置 (例如 Python)
-- 如果你希望 Python 文件默认发送到特定的 REPL (例如 ipython)
-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = 'python',
--   callback = function()
--     vim.g.slime_target = 'nvim'
--     vim.g.slime_session = 'ipython_repl'
--   end
-- })

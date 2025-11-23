-- lua/config/slime.lua
-- 注意: 此文件当前未被使用，配置已移至 lua/plugins/quarto_nvim.lua
-- 保留此文件作为参考

-- vim-slime 针对 NeoVim 内置终端的正确配置
-- 参考文档: https://github.com/jpalardy/vim-slime/blob/main/assets/doc/targets/neovim.md

-- 1. 设置 Slime 的目标类型 (必须在插件加载前设置)
-- 注意: 正确的值是 'neovim' 而不是 'nvim'
-- vim.g.slime_target = 'neovim'

-- 2. 可选配置
-- 自动建议最近打开的终端作为默认值
-- vim.g.slime_suggest_default = true

-- 使用菜单选择终端 (设为 true 可以从列表中选择)
-- vim.g.slime_menu_config = false

-- 使用 PID 而不是 job ID (默认使用 job ID)
-- vim.g.slime_input_pid = false

-- 忽略未列出的终端缓冲区
-- vim.g.slime_neovim_ignore_unlisted = false

-- bracketed-paste 模式 (某些 REPL 需要，但可能与 ipython 冲突)
-- vim.g.slime_bracketed_paste = 1

-- 3. 推荐的键映射
-- 发送 motion/textobject
-- vim.keymap.set('n', '<Leader>s', '<Plug>SlimeMotionSend', { remap = true, desc = 'Slime: Send Motion' })
-- 发送当前行
-- vim.keymap.set('n', '<Leader>ss', '<Plug>SlimeLineSend', { remap = true, desc = 'Slime: Send Line' })
-- 发送段落
-- vim.keymap.set('n', '<Leader>sp', '<Plug>SlimeParagraphSend', { remap = true, desc = 'Slime: Send Paragraph' })
-- 发送选中区域
-- vim.keymap.set('v', '<Leader>s', '<Plug>SlimeRegionSend', { remap = true, desc = 'Slime: Send Region' })
-- 配置目标终端
-- vim.keymap.set('n', '<Leader>sc', '<Plug>SlimeConfig', { remap = true, desc = 'Slime: Configure Target' })

-- 4. 自动配置函数 (高级用法)
-- 可以定义一个 Lua 函数来自动查找并配置终端
-- vim.g.slime_get_jobid = function()
--   for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
--     if vim.api.nvim_get_option_value('buftype', {buf = bufnr}) == "terminal" then
--       local chan = vim.api.nvim_get_option_value("channel", {buf = bufnr})
--       if chan and chan > 0 then
--         return chan
--       end
--     end
--   end
--   return nil
-- end

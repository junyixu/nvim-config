local julia_term = require 'custom.julia_term'

vim.keymap.set('n', '<leader>st', julia_term.open, { buffer = true, desc = 'open julia term' })
vim.keymap.set('n', '<leader>tt', julia_term.toggle, { buffer = true, desc = 'toggle julia term' })
-- Keymap for toggling slime target
vim.keymap.set('n', '<localleader>st', julia_term.toggle_slime_target, { buffer = true, desc = 'toggle slime target between kitty/neovim' })

local julia_ctags = require 'custom.julia_ctags'
julia_ctags.attach(0)

local julia_gtags = require 'custom.julia_gtags'
julia_gtags.attach(0)

-- vim.opt_local.makeprg = 'julia --project=@. %'
--
-- -- 优化后的匹配逻辑：
-- -- 1. %E: 匹配 ERROR: LoadError 开始
-- -- 2. %C: 继续匹配，捕获错误描述
-- -- 3. %Z: 匹配以 @ 开头的行，提取文件名 (%f) 和行号 (%l)
-- -- 4. %-G: 忽略不相关的行（如 "Closest candidates", "Stacktrace" 等）
--
-- vim.opt_local.errorformat =
--   -- 匹配堆栈中的具体位置： @ Main path/file.jl:123
--   [[%Z%*\\s@ %*\\S %f:%l,]]
--   -- 匹配简化的位置： @ path/file.jl:123
--   .. [[%Z%*\\s@ %f:%l,]]
--   -- 匹配错误起始行，忽略 LoadError 这种中间前缀，直接取后面的核心错误信息
--   .. [[%E%.%#ERROR:\ LoadError:\ %m,]]
--   -- 匹配错误详情行（通常是 MethodError...）
--   .. [[%C%m,]]
--   -- 忽略掉一些干扰行
--   .. [[%-G%.%#]]
--
-- vim.opt_local.errorformat = [=[%E%.%#ERROR: LoadError: %m,%C%*\\s[%*\\d] %m,%Z%*\\s@ %\\S%# %f:%l,%Z%*\\s@ %f:%l,%-G%.%#]=]
--
vim.opt_local.makeprg = 'julia --color=no --project=@. %'

vim.opt_local.errorformat = table.concat({
  -- 主错误：把 “ERROR:” 作为起点，用第一个 “@ ... file:line” 作为跳转位置
  [[%E%.%#ERROR:%m]],

  -- Stacktrace：把每一帧 “[n] func()” + 下一行 “@ file:line” 解析成单独条目
  -- 注意：这里需要单个反斜线（\s / \ ）；在 Lua 的 [[...]] 里不要写成 \\s / \\ 
  [[%E%*\s[%n]\ %m]],

  -- 结束行（用于主错误、也用于每个 stack frame）
  [[%Z%*[^@]@ %*[^ ] %f:%l%.%#]],
  [[%Z%*[^@]@ %f:%l%.%#]],
  [[%Zin expression starting at %f:%l]],

  -- continuation（放在后面，避免吞掉 “[n] func()” 的起始行）
  [[%C%.%#]],
  [[%-G%.%#]],
}, ',')

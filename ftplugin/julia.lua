vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldmethod = "expr"

local julia_term = require 'custom.julia_term'
vim.api.nvim_create_user_command('JuliaTerm', function() julia_term.open() end, {})

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

-- [D]elete [s]urround Julia bloc[k] wrapper (`begin...end` / `let...end`) around cursor.
-- Intended usage: `dsk`
vim.keymap.set('n', 'dsk', function()
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = 0, ignore_injections = false })
  if not ok or not node then
    return
  end

  local target = nil
  while node do
    local t = node:type()
    if t == 'compound_statement' or t == 'let_statement' then
      target = node
      break
    end
    node = node:parent()
  end
  if not target then
    return
  end

  local kind = target:type()
  local start_line = select(1, target:start()) + 1
  local end_line = select(1, target:end_()) + 1
  if end_line <= start_line then
    return
  end

  local keyword = (kind == 'let_statement') and 'let' or 'begin'

  local buf = 0
  local getline = function(ln)
    return vim.api.nvim_buf_get_lines(buf, ln - 1, ln, true)[1] or ''
  end
  local setline = function(ln, text)
    vim.api.nvim_buf_set_lines(buf, ln - 1, ln, true, { text })
  end
  local delline = function(ln)
    vim.api.nvim_buf_set_lines(buf, ln - 1, ln, true, {})
  end

  local is_keyword_only = function(ln, kw)
    local text = getline(ln)
    if text:match('^%s*' .. kw .. '($|[%s;#])') == nil then
      return false
    end

    local _, rest = text:match('^(%s*)' .. kw .. '(.*)$')
    rest = rest or ''
    return rest:match '^%s*;?%s*$' ~= nil or rest:match '^%s*;?%s*#.*$' ~= nil
  end

  local delete_or_strip_prefix_keyword = function(ln, kw)
    local text = getline(ln)
    local indent, rest = text:match('^(%s*)' .. kw .. '%s*(.*)$')
    if not indent then
      return false
    end
    rest = rest or ''
    -- If keyword was the only meaningful content (maybe with ';' and/or comment),
    -- delete the whole line to behave like `dd` (no leftover empty line).
    if rest:match '^%s*;?%s*$' ~= nil or rest:match '^%s*;?%s*#.*$' ~= nil then
      delline(ln)
      return true
    end

    setline(ln, indent .. rest)
    return true
  end

  local linewise = is_keyword_only(start_line, keyword) and is_keyword_only(end_line, 'end')
  if linewise then
    local inner_from, inner_to = start_line + 1, end_line - 1
    if inner_from <= inner_to then
      vim.cmd(('silent %d,%d<'):format(inner_from, inner_to))
    end
  end

  delete_or_strip_prefix_keyword(end_line, 'end')
  delete_or_strip_prefix_keyword(start_line, keyword)

  vim.api.nvim_win_set_cursor(0, { start_line, 0 })
end, { buffer = true, desc = 'Delete Julia begin/let wrapper' })

vim.keymap.set('n', 'tsk', function()
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = 0, ignore_injections = false })
  if not ok or not node then
    return
  end

  local container_types = {
    'compound_statement',
    'let_statement',
  }

  local target = nil
  while node do
    local t = node:type()
    for _, ct in ipairs(container_types) do
      if t == ct then
        target = node
        break
      end
    end
    if target then
      break
    end
    node = node:parent()
  end
  if not target then
    return
  end

  local end_line = select(1, target:end_()) + 1
  local buf = 0
  local line = vim.api.nvim_buf_get_lines(buf, end_line - 1, end_line, true)[1] or ''

  local indent, rest = line:match '^(%s*)end(.*)$'
  if not indent then
    return
  end

  local comment_start = rest:find('#', 1, true)
  local before_comment = comment_start and rest:sub(1, comment_start - 1) or rest
  local comment = comment_start and rest:sub(comment_start) or ''

  local trimmed = before_comment:gsub('%s+', '')
  if trimmed ~= '' and trimmed ~= ';' then
    return
  end

  local has_semicolon = trimmed == ';'
  local comment_clean = comment:gsub('^%s+', '')
  local space_before_comment = comment_clean ~= '' and ' ' or ''
  local new_line = indent .. 'end' .. (has_semicolon and '' or ';') .. space_before_comment .. comment_clean
  vim.api.nvim_buf_set_lines(buf, end_line - 1, end_line, true, { new_line })
end, { buffer = true, desc = 'Toggle end; for surrounding block' })

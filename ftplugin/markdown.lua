vim.b.completion = true
-- vim.opt_local.list = false
--
---@return boolean
local function in_markdown_table()
  local node = vim.treesitter.get_node()
  while node do
    if node:type() == 'pipe_table' then
      return true
    end
    node = node:parent()
  end
  return false
end

local function new_table_row()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  -- count pipes in current row
  local pipe_count = select(2, line:gsub('|', '|'))
  -- build new row: pipe_count pipes, each cell is two spaces
  local new_line = ('|  '):rep(pipe_count - 1) .. '|'
  vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
  -- land on first cell (after "| ")
  vim.api.nvim_win_set_cursor(0, { row + 1, 2 })
end

local function table_next_cell()
  local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- find next | on the same line, after cursor
  local rel = line:sub(cur_col + 2):find '|'
  if not rel then
    -- already past all pipes on this line, jump to next row's first |
    vim.fn.search('|', 'W')
    return
  end

  local pipe_col = cur_col + rel -- 0-indexed col of found |

  -- is this the last | on the line?
  if line:sub(pipe_col + 2):match '^%s*$' then
    new_table_row()
    return
  end

  -- normal jump: land one position past |, skip leading space
  local land = pipe_col + 1
  if line:sub(land + 1, land + 1) == ' ' then
    land = land + 1
  end
  vim.api.nvim_win_set_cursor(0, { cur_row, land })
end

-- @/home/junyi/.config/nvim/plugin/luasnip.vim:15-17
vim.keymap.set('i', '<Tab>', function()
  local ls = require 'luasnip'
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
    return
  end

  if in_markdown_table() then
    table_next_cell()
    return
  end
  -- 注意: copilot 行内补全不在这条链上, 它归 <F13> (物理 <C-i>),
  -- 见 lua/plugins/copilot-lsp.lua

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
end, { buffer = true, noremap = true, silent = true })

-- ===================== send to claude (kitty) ======================
-- 键位同 python/julia 的 slime，但目标是 kitty 里的 Claude Code，见 lua/custom/claude_kitty.lua
-- LSP hover 等浮窗也是 markdown filetype，只给普通文件 buffer 加
if vim.bo.buftype == '' then
  local function op(motion)
    return function()
      return require('custom.claude_kitty').operator() .. (motion or '')
    end
  end
  local function send_visual()
    require('custom.claude_kitty').send_visual()
  end

  vim.keymap.set('n', '<CR>', op '_', { buffer = true, expr = true, desc = 'Claude: Send Line' })
  vim.keymap.set('x', '<CR>', send_visual, { buffer = true, desc = 'Claude: Send Region' })
  vim.keymap.set('n', '<space><space>', op 'ip', { buffer = true, expr = true, desc = 'Claude: Send Paragraph' })
  vim.keymap.set('n', '<space>fp', op 'ip', { buffer = true, expr = true, desc = 'Claude: Send Paragraph' })
  vim.keymap.set('n', '<space>f', op(), { buffer = true, expr = true, desc = 'Claude: Send Motion' })
  vim.keymap.set('x', '<space>f', send_visual, { buffer = true, desc = 'Claude: Send Region' })
  vim.keymap.set('n', '<space>fc', function()
    require('custom.claude_kitty').window(true, function(id)
      vim.notify('claude_kitty: target window ' .. id)
    end)
  end, { buffer = true, desc = 'Claude: Pick Kitty Window' })
end
-- ===================== end send to claude ======================

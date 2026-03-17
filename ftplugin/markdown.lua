vim.b.completion = true
-- vim.opt_local.list = false
--
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

local function table_next_cell()
  local found = vim.fn.search('|', 'W')
  if found == 0 then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_col = col + 1
  if line:sub(new_col + 1, new_col + 1) == ' ' then
    new_col = new_col + 1
  end
  vim.api.nvim_win_set_cursor(0, { row, new_col })
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
  -- copilot fallback
  -- 我装的是 github/copilot.vim，用 vim.fn 调它的 vimscript API：
  if vim.fn['copilot#GetDisplayedSuggestion']().text ~= '' then
    vim.fn['copilot#Accept'] '\t'
    return
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
end, { buffer = true, noremap = true, silent = true })

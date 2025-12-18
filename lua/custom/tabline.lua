-- Simple tabline: show tab index prefix (for <M-1..9> muscle memory)
-- and keep the per-tab window count suffix.

local M = {}

local function tab_title(tabpage)
  local winid = vim.api.nvim_tabpage_get_win(tabpage)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  if bufname == '' then
    return '[No Name]'
  end
  return vim.fn.fnamemodify(bufname, ':t')
end

local function tab_win_status_suffix(tabpage)
  local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
  local current_win = vim.fn.tabpagewinnr(tabnr)
  local total_wins = vim.fn.tabpagewinnr(tabnr, '$')
  if total_wins <= 1 then
    return ''
  end
  return string.format(' [%d/%d]', current_win, total_wins)
end

function M.render()
  local parts = {}
  local current = vim.api.nvim_get_current_tabpage()

  for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local hl = tabpage == current and '%#TabLineSel#' or '%#TabLine#'
    local label = string.format('%d. %s%s', i, tab_title(tabpage), tab_win_status_suffix(tabpage))
    table.insert(parts, string.format('%%%dT%s %s ', i, hl, label))
  end

  table.insert(parts, '%#TabLineFill#%=%T')
  return table.concat(parts)
end

function M.setup()
  -- Only show tabline when there are at least 2 tabpages.
  vim.o.showtabline = 1
  vim.o.tabline = "%{%v:lua.require('custom.tabline').render()%}"
end

return M

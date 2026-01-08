local M = {}

local QUICKFIX_MAX_HEIGHT = 15

function M.adjust_quickfix_height(item_count)
  local height = math.min(item_count, QUICKFIX_MAX_HEIGHT)

  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  if qf_win ~= 0 then
    vim.api.nvim_win_set_height(qf_win, height)
  end
end

return M

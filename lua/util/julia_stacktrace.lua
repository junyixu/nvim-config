local M = {}

---@param line string
---@return string? path, integer? lnum
local function parse_location(line)
  line = (line or ''):gsub('\r', '')

  -- Common Julia stacktrace formats:
  --   @ Main ~/WorkSpace/foo.jl:91
  --   @ ~/WorkSpace/foo.jl:91 [inlined]
  --   @ Contour ~/.julia/packages/Contour/src/Contour.jl:74
  local path, lnum = line:match '@%s+[^%s]+%s+([^%s]+):(%d+)'
  if not path then
    path, lnum = line:match '@%s+([^%s]+):(%d+)'
  end
  if not path then
    -- e.g. "in expression starting at /home/user/foo.jl:129"
    path, lnum = line:match 'in expression starting at%s+([^%s]+):(%d+)'
  end
  if not path or not lnum then
    return nil, nil
  end

  if path:sub(1, 1) == '@' then
    path = path:sub(2)
  end

  path = vim.fn.expand(path)
  return path, tonumber(lnum)
end

---@param line string
---@return string? path, integer? lnum
function M.parse_location(line)
  return parse_location(line)
end

---@param winid integer
---@return boolean
local function is_normal_target_window(winid)
  if not (winid and winid ~= 0 and vim.api.nvim_win_is_valid(winid)) then
    return false
  end

  local cfg = vim.api.nvim_win_get_config(winid)
  if cfg and cfg.zindex ~= nil then
    return false
  end

  local bufnr = vim.api.nvim_win_get_buf(winid)
  return vim.bo[bufnr].buftype == ''
end

---@return integer? winid
local function pick_target_window()
  local cur = vim.api.nvim_get_current_win()

  -- Prefer "alternate window" (like flatten's default behavior for terminal workflows).
  local alt = vim.fn.win_getid(vim.fn.winnr '#')
  if alt ~= cur and is_normal_target_window(alt) then
    return alt
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= cur and is_normal_target_window(win) then
      return win
    end
  end

  return nil
end

---@param path string
---@param lnum integer
---@param opts? { open?: "alternate" | "vsplit" | "split" | "current" }
---@return boolean handled
local function open_location(path, lnum, opts)
  opts = opts or {}

  local target = nil
  local open = opts.open or 'alternate'
  if open == 'current' or open == 'current_split' or open == 'current_vsplit' then
    target = vim.api.nvim_get_current_win()
  else
    target = pick_target_window()
  end

  if not target then
    -- If we're in a lone terminal window, split first so we don't lose it.
    if open == 'split' then
      vim.cmd.split()
    else
      vim.cmd.vsplit()
    end
    target = vim.api.nvim_get_current_win()
  end

  if vim.uv.fs_stat(path) == nil then
    vim.notify(('File not found: %s'):format(path), vim.log.levels.WARN)
    return true
  end

  vim.api.nvim_set_current_win(target)
  if open == 'alternate_split' or open == 'current_split' then
    vim.cmd.split()
  elseif open == 'alternate_vsplit' or open == 'current_vsplit' then
    vim.cmd.vsplit()
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd.normal { args = { 'zvzz' }, bang = true }
  return true
end

---@param opts? { line?: string, open?: "alternate" | "vsplit" | "split" | "current" }
---@return boolean handled
function M.try_open_at_cursor(opts)
  opts = opts or {}
  local line = opts.line or vim.api.nvim_get_current_line()
  local path, lnum = parse_location(line)
  if not path or not lnum then
    return false
  end
  return open_location(path, lnum, opts)
end

---@param opts? { line?: string, open?: "alternate" | "vsplit" | "split" | "current" }
function M.open_at_cursor(opts)
  local handled = M.try_open_at_cursor(opts)
  if not handled then
    vim.notify('No Julia file:line found on this line', vim.log.levels.WARN)
  end
end

return M

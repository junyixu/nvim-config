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

---@param path string
---@param lnum integer
---@return boolean handled
local function open_location_alternate_split(path, lnum)
  if vim.uv.fs_stat(path) == nil then
    vim.notify(('File not found: %s'):format(path), vim.log.levels.WARN)
    return true
  end

  local cur = vim.api.nvim_get_current_win()
  local target = nil

  local function is_normal_window(winid)
    if not (winid and winid ~= 0 and vim.api.nvim_win_is_valid(winid)) then
      return false
    end
    local cfg = vim.api.nvim_win_get_config(winid)
    if cfg and cfg.relative ~= '' then
      return false
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    return vim.bo[bufnr].buftype == ''
  end

  local alt = vim.fn.win_getid(vim.fn.winnr '#')
  if alt ~= cur and is_normal_window(alt) then
    target = alt
  else
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if win ~= cur and is_normal_window(win) then
        target = win
        break
      end
    end
  end

  if target then
    vim.api.nvim_set_current_win(target)
  end

  vim.cmd.split()

  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd.normal { args = { 'zvzz' }, bang = true }
  return true
end

---@param opts? { line?: string }
---@return boolean handled
function M.try_open_at_cursor(opts)
  opts = opts or {}
  local line = opts.line or vim.api.nvim_get_current_line()
  local path, lnum = parse_location(line)
  if not path or not lnum then
    return false
  end
  return open_location_alternate_split(path, lnum)
end

return M

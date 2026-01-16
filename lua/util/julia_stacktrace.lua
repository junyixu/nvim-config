local M = {}

---@param line string
---@return string? path, integer? lnum
local function normalize_location(path, lnum)
  if not path or not lnum then
    return nil, nil
  end

  if path:sub(1, 1) == '@' then
    path = path:sub(2)
  end

  path = vim.fn.expand(path)
  return path, tonumber(lnum)
end

local function strip_wrapping(token)
  if not token or token == '' then
    return token
  end
  token = token:gsub('^[`\'"({%[]+', '')
  token = token:gsub('[`\'"),:;.%]%}%>]+$', '')
  return token
end

--- Parse common Julia stacktrace locations that start with "@".
---@param line string
---@return string? path, integer? lnum
function M.parse_location_stacktrace(line)
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
  return normalize_location(path, lnum)
end

--- Parse a plain "path:line" (no leading "@"), e.g. "/a/b/c.jl:123" or "~/.julia/x.jl:9".
---@param line string
---@return string? path, integer? lnum
function M.parse_location_plain_path(line)
  line = (line or ''):gsub('\r', '')
  for token in line:gmatch('%S+') do
    token = strip_wrapping(token)
    local path, lnum = token:match '^([~/.][^%s:]+):(%d+)$'
    if path and lnum then
      return normalize_location(path, lnum)
    end
  end
  return nil, nil
end

--- Parse either stacktrace "@ ... path:line" or a plain "path:line".
---@param line string
---@return string? path, integer? lnum
function M.parse_location_stacktrace_or_plain(line)
  line = (line or ''):gsub('\r', '')
  local path, lnum = line:match '([%w%._/%~\\%-]+):(%d+)'
  return normalize_location(path, lnum)
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

---@param opts? { line?: string, parse_location?: fun(line: string): (string?, integer?) }
---@return boolean handled
function M.try_open_at_cursor(opts)
  opts = opts or {}
  local line = opts.line or vim.api.nvim_get_current_line()
  local parse_location = opts.parse_location or M.parse_location_stacktrace
  local path, lnum = parse_location(line)
  if not path or not lnum then
    return false
  end
  return open_location_alternate_split(path, lnum)
end

return M

local M = {}

local adjust_quickfix_height = require('util.quickfix').adjust_quickfix_height

local function echo(msg, hl)
  vim.api.nvim_echo({ { msg, hl or 'None' } }, true, {})
end

local function parse_global_ctags_mod(out)
  local items = {}
  for _, line in ipairs(vim.split(out, '\n', { trimempty = true })) do
    local filename, lnum, text = line:match '^(.-)\t(%d+)\t(.*)$'
    if not filename then
      filename, lnum, text = line:match '^(.-)%s+(%d+)%s+(.*)$'
    end
    if filename and lnum and text then
      table.insert(items, { filename = filename, lnum = tonumber(lnum), text = text })
    end
  end
  return items
end

local function run_global(option, pattern, action, title_prefix)
  local query = pattern
  if query == '' then
    query = vim.fn.input('Gtags for pattern: ', vim.fn.expand '<cword>')
  end
  if query == '' then
    echo((title_prefix or 'Gtags') .. ': pattern not specified.', 'ErrorMsg')
    return
  end

  -- Always pass `-e` so patterns starting with '-' are treated as a pattern.
  local cmd = 'global --path-style=absolute --result=ctags-mod -q ' .. option .. ' -e ' .. vim.fn.shellescape(query)
  local out = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    echo(((title_prefix or 'Gtags') .. ': global failed (%d)'):format(vim.v.shell_error), 'ErrorMsg')
    echo(cmd)
    return
  end

  if out == '' then
    echo((title_prefix or 'Gtags') .. ': not found: ' .. query, 'WarningMsg')
    if action == 'r' then
      vim.fn.setqflist({}, 'r', { title = (title_prefix or 'Gtags') .. ': ' .. query, items = {} })
      vim.cmd.cclose()
    end
    return
  end

  local items = parse_global_ctags_mod(out)
  if action == 'a' then
    -- Append to the current quickfix list and keep cursor position.
    vim.fn.setqflist(items, 'a')
    vim.cmd 'botright copen'
    adjust_quickfix_height(#items)
    return
  end

  -- Replace the current quickfix list and jump to the first match.
  vim.fn.setqflist({}, 'r', { title = (title_prefix or 'Gtags') .. ': ' .. query, items = items })
  vim.cmd 'botright copen'
  adjust_quickfix_height(#items)
  pcall(vim.cmd.cfirst)
end

local function parse_args(qargs)
  local argline = qargs or ''
  local opt, pat = '', argline

  local trimmed = vim.trim(argline)
  if vim.startswith(trimmed, '-r ') or trimmed == '-r' then
    opt = '-r'
    pat = vim.trim(trimmed:sub(3))
  elseif vim.startswith(trimmed, '-s ') or trimmed == '-s' then
    opt = '-s'
    pat = vim.trim(trimmed:sub(3))
  elseif vim.startswith(trimmed, '-d ') or trimmed == '-d' then
    opt = '-d'
    pat = vim.trim(trimmed:sub(3))
  end

  return opt, pat
end

local function gtags(qargs)
  local opt, pat = parse_args(qargs)
  run_global(opt, pat, 'r', 'Gtags')
end

local function gtagsa(qargs)
  local opt, pat = parse_args(qargs)
  run_global(opt, pat, 'a', 'Gtagsa')
end

M.gtags = gtags
M.gtagsa = gtagsa

function M.setup(opts)
  opts = opts or {}
end

return M

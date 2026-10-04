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

local function resolve_query(pattern, title_prefix)
  local query = pattern
  if query == nil or query == '' then
    query = vim.fn.input('Gtags for pattern: ', vim.fn.expand '<cword>')
  end
  if query == '' then
    echo((title_prefix or 'Gtags') .. ': pattern not specified.', 'ErrorMsg')
    return nil
  end
  return query
end

-- Run `global` and return the parsed items: nil when the query itself failed
-- (no GTAGS, no `global`, ...), an empty table when it simply matched nothing.
-- Both are echoed unless `silent` -- callers with a further fallback stay quiet.
local function query_global(option, query, title_prefix, silent)
  -- Always pass `-e` so patterns starting with '-' are treated as a pattern.
  local cmd = 'global --path-style=absolute --result=ctags-mod -q ' .. option .. ' -e ' .. vim.fn.shellescape(query)
  local out = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    if not silent then
      echo(((title_prefix or 'Gtags') .. ': global failed (%d)'):format(vim.v.shell_error), 'ErrorMsg')
      echo(cmd)
    end
    return nil
  end

  if out == '' then
    if not silent then
      echo((title_prefix or 'Gtags') .. ': not found: ' .. query, 'WarningMsg')
    end
    return {}
  end

  return parse_global_ctags_mod(out)
end

local function fill_quickfix(items, title, action)
  if action == 'a' then
    -- Append to the current quickfix list and keep cursor position.
    vim.fn.setqflist(items, 'a')
    vim.cmd 'botright copen'
    adjust_quickfix_height(#items)
    return
  end

  -- Replace the current quickfix list and jump to the first match.
  vim.fn.setqflist({}, 'r', { title = title, items = items })
  vim.cmd 'botright copen'
  adjust_quickfix_height(#items)
  pcall(vim.cmd.cfirst)
end

local function run_global(option, pattern, action, title_prefix)
  local query = resolve_query(pattern, title_prefix)
  if not query then
    return
  end

  local items = query_global(option, query, title_prefix)
  if not items then
    return
  end

  if #items == 0 then
    if action == 'r' then
      vim.fn.setqflist({}, 'r', { title = (title_prefix or 'Gtags') .. ': ' .. query, items = {} })
      vim.cmd.cclose()
    end
    return
  end

  fill_quickfix(items, (title_prefix or 'Gtags') .. ': ' .. query, action)
end

--- LSP-`grr`-style lookup: jump straight to a lone match, or fuzzy-pick when
--- there are several. Either way the pre-jump position goes on the tag stack,
--- so `<C-t>` comes back (`:help tagstack`).
--- @param option string `global` flag, e.g. '-r' for references
--- @param pattern string|nil pattern; prompts with <cword> when empty
--- @param title_prefix string|nil
--- @param opts { silent?: boolean }|nil `silent` mutes the "not found" /
---   "global failed" messages, for callers that fall back to something else
--- @return boolean handled false when `global` is unusable or found nothing
function M.jump_or_pick(option, pattern, title_prefix, opts)
  opts = opts or {}

  local query = resolve_query(pattern, title_prefix)
  if not query then
    return false
  end

  local items = query_global(option, query, title_prefix, opts.silent)
  if not items or #items == 0 then
    return false
  end

  local title = (title_prefix or 'Gtags') .. ': ' .. query

  if #items == 1 then
    local item = items[1]
    local win = vim.api.nvim_get_current_win()
    local from = { vim.fn.bufnr '%', vim.fn.line '.', vim.fn.col '.', 0 }

    -- Mirror what the built-in LSP single-location jump does: jumplist first,
    -- then tag stack, then land on the match.
    vim.cmd.normal { "m'", bang = true }
    vim.fn.settagstack(win, { items = { { tagname = query, from = from } } }, 't')
    vim.cmd.edit(vim.fn.fnameescape(item.filename))
    vim.api.nvim_win_set_cursor(win, { item.lnum, 0 })
    vim.cmd.normal { 'zv', bang = true }
    return true
  end

  local ok, snacks = pcall(require, 'snacks')
  if not ok or not snacks.picker then
    fill_quickfix(items, title, 'r')
    return true
  end

  snacks.picker {
    title = title,
    items = vim.tbl_map(function(item)
      return {
        file = item.filename,
        pos = { item.lnum, 0 },
        line = item.text,
        -- what the fuzzy matcher sees: path plus the matched line
        text = item.filename .. ' ' .. item.text,
      }
    end, items),
    format = 'file',
    -- snacks pushes the pre-jump position onto the tag stack itself
    jump = { tagstack = true, reuse_win = true },
  }

  return true
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

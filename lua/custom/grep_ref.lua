-- Grep-based reference search: the last fallback of Julia's `grr` for when
-- neither LSP nor GNU Global can answer. Unlike a plain grep picker this drops
-- the match the cursor already sits on, so when a single other match remains it
-- can be jumped to straight away -- the same shape as the two steps above it.
local M = {}

local adjust_quickfix_height = require('util.quickfix').adjust_quickfix_height

--- Matches for `word` as `{ filename, lnum, col, text }` items; nil when `rg`
--- is missing or failed, so the caller can degrade to `grepprg`.
--- @param word string
--- @return table[]|nil
local function query_rg(word)
  if vim.fn.executable 'rg' ~= 1 then
    return nil
  end

  local cmd = { 'rg', '--vimgrep', '--fixed-strings' }
  -- `-w` wraps the pattern in \b assertions, which can never match when the
  -- word itself begins or ends with a non-word char -- and Julia's `iskeyword`
  -- pulls `@` and `!` into <cword> (`@inbounds`, `compute_collision!`). Those
  -- literals already delimit themselves, so just leave `-w` off for them.
  if word:match '^[%w_]+$' then
    table.insert(cmd, '--word-regexp')
  end
  vim.list_extend(cmd, { '--', word })

  local out = vim.fn.systemlist(cmd)
  -- rg: 0 = matched, 1 = matched nothing, >1 = actually broken
  if vim.v.shell_error > 1 then
    return nil
  end

  local items = {}
  for _, line in ipairs(out) do
    local filename, lnum, col, text = line:match '^(.-):(%d+):(%d+):(.*)$'
    if filename then
      table.insert(items, { filename = filename, lnum = tonumber(lnum), col = tonumber(col), text = text })
    end
  end
  return items
end

--- Drop the match under the cursor: same file, same line, and a column span
--- covering the cursor. Byte columns throughout (`rg --vimgrep`, `col()` and
--- `#word` all agree), so multi-byte text needs no special casing.
local function without_cursor_match(items, word)
  local cur = vim.api.nvim_buf_get_name(0)
  if cur == '' then
    return items
  end
  cur = vim.fn.fnamemodify(cur, ':p')

  local lnum, ccol, width = vim.fn.line '.', vim.fn.col '.', #word

  return vim.tbl_filter(function(item)
    if item.lnum ~= lnum or vim.fn.fnamemodify(item.filename, ':p') ~= cur then
      return true
    end
    return not (item.col <= ccol and ccol < item.col + width)
  end, items)
end

local function jump_to(item, tagname)
  local win = vim.api.nvim_get_current_win()
  local from = { vim.fn.bufnr '%', vim.fn.line '.', vim.fn.col '.', 0 }

  -- Mirror the built-in LSP single-location jump: jumplist first, then tag
  -- stack, then land on the match, so `<C-t>` comes back (`:help tagstack`).
  vim.cmd.normal { "m'", bang = true }
  vim.fn.settagstack(win, { items = { { tagname = tagname, from = from } } }, 't')
  vim.cmd.edit(vim.fn.fnameescape(item.filename))
  vim.api.nvim_win_set_cursor(win, { item.lnum, math.max(item.col - 1, 0) })
  vim.cmd.normal { 'zv', bang = true }
end

--- Grep for `word`, ignoring the match under the cursor: jump straight to a
--- lone remaining match, fuzzy-pick when there are several.
--- @param word string non-empty search word, normally <cword>
--- @return boolean handled false when `rg` is unusable, for callers that fall
---   back to something else
function M.jump_or_pick(word)
  local items = query_rg(word)
  if not items then
    return false
  end

  items = without_cursor_match(items, word)
  local title = 'Grep: ' .. word

  if #items == 0 then
    vim.api.nvim_echo({ { title .. ': no other match', 'WarningMsg' } }, true, {})
    return true
  end

  if #items == 1 then
    jump_to(items[1], word)
    return true
  end

  local ok, snacks = pcall(require, 'snacks')
  if not ok or not snacks.picker then
    vim.fn.setqflist({}, 'r', { title = title, items = items })
    vim.cmd 'botright copen'
    adjust_quickfix_height(#items)
    pcall(vim.cmd.cfirst)
    return true
  end

  snacks.picker {
    title = title,
    items = vim.tbl_map(function(item)
      return {
        file = item.filename,
        pos = { item.lnum, math.max(item.col - 1, 0) },
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

return M

local M = {}

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

-- Smart <CR> for Markdown:
-- - Continues blockquotes ("> ")
-- - Continues list items ("- ", "- [ ] ")
-- - Clears Tree-sitter "hanging indent" to avoid accidental nesting
function M.smart_cr()
  local line = vim.api.nvim_get_current_line()
  local _, col0 = unpack(vim.api.nvim_win_get_cursor(0)) -- 0-based byte index

  -- Only special-case end-of-line; keep default in the middle of a line.
  if col0 ~= #line then
    return termcodes '<CR>'
  end

  -- With indentexpr (e.g. Tree-sitter), <CR> may insert a "hanging" indent
  -- (e.g. after "- [ ] "). Clear whatever was auto-inserted on the new line
  -- before inserting our own prefix.
  local function cr_clear_indent()
    return termcodes '<CR><C-o>0<C-o>"_D'
  end

  local indent = line:match '^%s*' or ''
  local idx = #indent + 1

  -- Parse nested quote leaders.
  local quote_leader = ''
  while line:sub(idx, idx) == '>' do
    quote_leader = quote_leader .. '>'
    idx = idx + 1
    while line:sub(idx, idx) == ' ' do
      quote_leader = quote_leader .. ' '
      idx = idx + 1
    end
  end

  -- Preserve extra whitespace after quote leaders (so `>   - item` keeps it).
  local after_quote_ws = ''
  if quote_leader ~= '' then
    after_quote_ws = (line:sub(idx):match '^%s*' or '')
    idx = idx + #after_quote_ws
  end

  local rest = line:sub(idx)

  local is_quote_only_line = quote_leader ~= '' and rest:match '^%s*$' ~= nil
  -- If the current line is an "empty" blockquote line like `> `, trim the
  -- trailing whitespace before creating the next line so it becomes `>`.
  local trim_quote_blank = ''
  if is_quote_only_line and line:match '%s$' then
    trim_quote_blank = termcodes '<C-o>:s/\\s\\+$//e<CR>'
  end

  -- Checkbox list item.
  local bullet = rest:match '^([-*+])%s+%[[ xX]%]%s+'
  if bullet then
    return cr_clear_indent() .. indent .. quote_leader .. after_quote_ws .. bullet .. ' [ ] '
  end

  -- Regular list item.
  local bullet2 = rest:match '^([-*+])%s+'
  if bullet2 then
    return cr_clear_indent() .. indent .. quote_leader .. after_quote_ws .. bullet2 .. ' '
  end

  -- Plain blockquote.
  if quote_leader ~= '' then
    local quote_for_next_line = quote_leader
    if quote_for_next_line:sub(-1) ~= ' ' then
      quote_for_next_line = quote_for_next_line .. ' '
    end
    return trim_quote_blank .. cr_clear_indent() .. indent .. quote_for_next_line
  end

  return termcodes '<CR>'
end

return M

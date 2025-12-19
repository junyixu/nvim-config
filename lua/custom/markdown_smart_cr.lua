local M = {}

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function default_cr()
  return termcodes '<CR>'
end

local function at_eol(line)
  local _, col0 = unpack(vim.api.nvim_win_get_cursor(0)) -- 0-based byte index
  return col0 == #line
end

-- With indentexpr (e.g. Tree-sitter), <CR> may insert a "hanging" indent.
-- Clear whatever was auto-inserted on the new line before inserting our prefix.
local function cr_clear_indent()
  return termcodes '<CR><C-o>0<C-o>"_D'
end

local function ensure_trailing_space(s)
  if s == '' then
    return s
  end
  if s:sub(-1) == ' ' then
    return s
  end
  return s .. ' '
end

local function parse_quote_context(line)
  local indent = line:match '^%s*' or ''
  local idx = #indent + 1

  local quote_leader = ''
  while line:sub(idx, idx) == '>' do
    quote_leader = quote_leader .. '>'
    idx = idx + 1
    while line:sub(idx, idx) == ' ' do
      quote_leader = quote_leader .. ' '
      idx = idx + 1
    end
  end

  local after_quote_ws = ''
  if quote_leader ~= '' then
    after_quote_ws = (line:sub(idx):match '^%s*' or '')
    idx = idx + #after_quote_ws
  end

  return {
    indent = indent,
    quote_leader = quote_leader,
    after_quote_ws = after_quote_ws,
    rest = line:sub(idx),
  }
end

local function trim_trailing_ws_current_line_cmd()
  return termcodes '<C-o>:s/\\s\\+$//e<CR>'
end

local function quote_blank_trim_cmd(ctx, line)
  if ctx.quote_leader == '' then
    return ''
  end
  if ctx.rest:match '^%s*$' == nil then
    return ''
  end
  if line:match '%s$' == nil then
    return ''
  end
  return trim_trailing_ws_current_line_cmd()
end

-- Smart <CR> for Markdown:
-- - Continues blockquotes ("> ")
-- - Continues list items ("- ", "- [ ] ")
-- - Clears Tree-sitter "hanging indent" to avoid accidental nesting
function M.smart_cr()
  local line = vim.api.nvim_get_current_line()
  if not at_eol(line) then
    return default_cr()
  end

  local ctx = parse_quote_context(line)
  local trim_quote_blank = quote_blank_trim_cmd(ctx, line)

  -- Checkbox list item.
  local bullet = ctx.rest:match '^([-*+])%s+%[[ xX]%]%s+'
  if bullet then
    return cr_clear_indent() .. ctx.indent .. ctx.quote_leader .. ctx.after_quote_ws .. bullet .. ' [ ] '
  end

  -- Regular list item.
  local bullet2 = ctx.rest:match '^([-*+])%s+'
  if bullet2 then
    return cr_clear_indent() .. ctx.indent .. ctx.quote_leader .. ctx.after_quote_ws .. bullet2 .. ' '
  end

  -- Plain blockquote.
  if ctx.quote_leader ~= '' then
    return trim_quote_blank .. cr_clear_indent() .. ctx.indent .. ensure_trailing_space(ctx.quote_leader)
  end

  return default_cr()
end

return M

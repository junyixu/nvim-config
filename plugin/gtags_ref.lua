if vim.g.loaded_gtags_ref_lua == 1 then
  return
end
vim.g.loaded_gtags_ref_lua = 1

-- Minimal GNU Global (gtags) integration for Neovim.
--
-- Commands:
--   :Gtags  [options] {pattern}
--   :Gtagsa [options] {pattern}  (append to current quickfix)
--
-- Supported options:
--   -r  find references
--   -s  find other symbols
--
-- Output:
--   We call `global` with `--result=ctags-mod` and parse the output into quickfix
--   items. `ctags-mod` is typically: {file}\t{line}\t{text}.
--
local function echo(msg, hl)
  vim.api.nvim_echo({ { msg, hl or 'None' } }, true, {})
end

-- Parse `global --result=ctags-mod` output into quickfix items.
-- Also supports the space-aligned output some setups display.
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
    return
  end

  -- Replace the current quickfix list and jump to the first match.
  vim.fn.setqflist({}, 'r', { title = (title_prefix or 'Gtags') .. ': ' .. query, items = items })
  vim.cmd 'botright copen'
  pcall(vim.cmd.cfirst)
end

-- Parse a small subset of `:Gtags` options, keeping it intentionally simple.
-- Accepted forms:
--   -r {pat}   / -r
--   -s {pat}   / -s
-- Otherwise treat the whole argline as the pattern.
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

vim.api.nvim_create_user_command('Gtags', function(opts)
  gtags(opts.args)
end, { nargs = '*' })

vim.api.nvim_create_user_command('Gtagsa', function(opts)
  gtagsa(opts.args)
end, { nargs = '*' })

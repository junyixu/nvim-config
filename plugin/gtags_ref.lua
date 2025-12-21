if vim.g.loaded_gtags_ref_lua == 1 then
  return
end
vim.g.loaded_gtags_ref_lua = 1

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

local function run_global(option, pattern)
  local query = pattern
  if query == '' then
    query = vim.fn.input('Gtags for pattern: ', vim.fn.expand '<cword>')
  end
  if query == '' then
    echo('Gtags: pattern not specified.', 'ErrorMsg')
    return
  end

  local cmd = 'global --path-style=absolute --result=ctags-mod -q ' .. option .. ' -e ' .. vim.fn.shellescape(query)
  local out = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    echo(('Gtags: global failed (%d)'):format(vim.v.shell_error), 'ErrorMsg')
    echo(cmd)
    return
  end

  if out == '' then
    echo('Gtags: not found: ' .. query, 'WarningMsg')
    vim.fn.setqflist({}, 'r', { title = 'Gtags: ' .. query, items = {} })
    vim.cmd.cclose()
    return
  end

  local items = parse_global_ctags_mod(out)
  vim.fn.setqflist({}, 'r', { title = 'Gtags: ' .. query, items = items })
  vim.cmd 'botright copen'
  pcall(vim.cmd.cfirst)
end

local function gtags(qargs)
  local argline = qargs or ''
  local opt, pat = '', argline

  local trimmed = vim.trim(argline)
  if vim.startswith(trimmed, '-r ') or trimmed == '-r' then
    opt = '-r'
    pat = vim.trim(trimmed:sub(3))
  end

  run_global(opt, pat)
end

vim.api.nvim_create_user_command('Gtags', function(opts)
  gtags(opts.args)
end, { nargs = '*' })

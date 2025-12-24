vim.api.nvim_create_user_command('E', function(opts)
  local parts = vim.split(opts.args, ':', { plain = true })
  local file = parts[1] or ''
  local cmd = parts[2]

  if file:sub(1, 1) == '@' then
    file = file:sub(2)
  end
  if file == '' then
    vim.notify('E command expects {file}:{cmd}', vim.log.levels.ERROR)
    return
  end

  vim.cmd.tabedit(file)
  if cmd and cmd ~= '' then
    vim.cmd(cmd)
  end
end, { nargs = 1, complete = 'file' })

do
  local gtags_ref = require 'custom.gtags_ref'
  gtags_ref.setup {
    quickfix_max_height = 10,
  }

  pcall(vim.api.nvim_del_user_command, 'Gtags')
  vim.api.nvim_create_user_command('Gtags', function(opts)
    gtags_ref.gtags(opts.args)
  end, { nargs = '*' })

  pcall(vim.api.nvim_del_user_command, 'Gtagsa')
  vim.api.nvim_create_user_command('Gtagsa', function(opts)
    gtags_ref.gtagsa(opts.args)
  end, { nargs = '*' })

  vim.cmd [[
    cabbrev gr Gtags -r
    cabbrev gs Gtags -s
    cabbrev gd Gtags -d
  ]]
end



do
  local GPTCommit = require 'custom.GPTCommit'

  pcall(vim.api.nvim_del_user_command, 'GptCommit')
  vim.api.nvim_create_user_command('GptCommit', function(opts)
    GPTCommit.cmd(opts.args)
  end, { nargs = '?', complete = 'file' })
end

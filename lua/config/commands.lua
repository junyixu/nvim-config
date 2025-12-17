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


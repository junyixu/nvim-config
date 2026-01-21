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

pcall(vim.api.nvim_del_user_command, 'JuliaStackOpen')
vim.api.nvim_create_user_command('JuliaStackOpen', function()
  local handled = require('util.julia_stacktrace').try_open_at_cursor()
  if not handled then
    vim.notify('No Julia file:line found on this line', vim.log.levels.WARN)
  end
end, { desc = 'Open Julia stacktrace location under cursor (from @ file:line)' })

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
    cabbrev ttr Gtags -r
    cabbrev tts Gtags -s
    cabbrev ttd Gtags -d
    cabbrev rg sil grep
  ]]
end

do
  local GPTCommit = require 'custom.GPTCommit'

  pcall(vim.api.nvim_del_user_command, 'GptCommit')
  vim.api.nvim_create_user_command('GptCommit', function(opts)
    GPTCommit.cmd(opts.args)
  end, { nargs = '?', complete = 'file' })
end

-- 自定义远程对比命令
-- eg: :DiffRemote
-- :DiffRemote 192.168.1.100
-- :vertical diffsplit oil-ssh://junyi@100.85.19.60//home/junyi/.claude/CLAUDE.md
vim.api.nvim_create_user_command('DiffRemote', function(opts)
  -- 1. 获取当前文件的绝对路径
  local local_path = vim.fn.expand '%:p'

  -- 2. 设置默认的远程信息 (你可以根据需求修改这些默认值)
  local user = 'junyi'
  local host = opts.args ~= '' and opts.args or '100.85.19.60'

  -- 3. 构造 oil-ssh 路径
  -- 注意：这里假设远程路径与本地路径完全一致
  local remote_url = string.format('oil-ssh://%s@%s/%s', user, host, local_path)

  -- 4. 执行垂直分屏对比
  vim.cmd('vertical diffsplit ' .. remote_url)
end, {
  nargs = '?', -- 接受 0 或 1 个参数（远程 IP/Host）
  desc = 'Compare current file with its remote counterpart using oil-ssh',
})

vim.api.nvim_create_user_command(
  'DiffRemotePicker',
  require('junyi.telescope_tailscale').diff,
  { desc = 'Pick a Tailscale node to diff the current file against' }
)

vim.api.nvim_create_user_command('FixMath', require('util.re').fix_markdown_latex, { desc = 'Convert LaTeX delimiters to $ and $$ with strict spacing' })

vim.api.nvim_create_user_command('Make', require('junyi.make').async_make, {})
vim.api.nvim_create_user_command('LMake', require('junyi.make').async_lmake, {})

vim.cmd [[
command! BufOnly execute '%bdelete|edit #|normal `"'
cabbrev cc CodeCompanion
cabbrev make Make
cabbrev mak Make
cabbrev lmak LMake
cabbrev lmake LMake
]]

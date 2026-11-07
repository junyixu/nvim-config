-- trixi-sync entry points. Only stubs live here; the implementation in
-- lua/junyi/trixi_sync.lua is required on first use.

if vim.g.loaded_trixi_sync then
  return
end
vim.g.loaded_trixi_sync = true

local function sync(...)
  local args = { ... }
  return function()
    require('junyi.trixi_sync').run(args)
  end
end

vim.api.nvim_create_user_command('TrixiSync', function(opts)
  require('junyi.trixi_sync').run(opts.fargs)
end, {
  nargs = '*',
  desc = 'Sync TrixiReactant.jl with the remote (status/pull/push/logs/init/reset)',
  complete = function(arglead, cmdline)
    return require('junyi.trixi_sync').complete(arglead, cmdline)
  end,
})

-- push 是异步的，必须等它成功后再 restore，否则会丢掉没推上去的改动
vim.keymap.set('n', '<leader>sl', function()
  require('junyi.trixi_sync').run({ 'push' }, function()
    vim.cmd 'Git restore . | Git pull'
  end)
end, { desc = 'trixi-sync push, then git restore and pull' })
vim.keymap.set('n', '<leader>sp', sync 'push', { desc = 'trixi-sync push' })
vim.keymap.set('n', '<leader>sL', sync 'logs', { desc = 'trixi-sync logs' })
vim.keymap.set('n', '<leader>ss', sync 'status', { desc = 'trixi-sync status' })

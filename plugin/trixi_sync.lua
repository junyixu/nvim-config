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

-- :Git 按当前 buffer 找仓库，`.` 按工作目录算，两者都要在 push 的目录里
local function in_repo(dir)
  for _, source in ipairs { 0, vim.fn.getcwd() } do
    local root = vim.fs.root(source, '.git')
    if not root or vim.uv.fs_realpath(root) ~= vim.uv.fs_realpath(dir) then
      return false
    end
  end
  return true
end

-- push 是异步的，必须等它成功后再 restore，否则会丢掉没推上去的改动；
-- 等待期间可能切走 buffer，所以 restore 前再查一次
vim.keymap.set('n', '<leader>sl', function()
  local trixi = require 'junyi.trixi_sync'
  local dir = trixi.local_dir()
  local function check()
    if in_repo(dir) then
      return true
    end
    vim.notify(('trixi-sync: 当前 buffer 或工作目录不在 %s，不执行 git restore/pull'):format(dir), vim.log.levels.WARN)
    return false
  end

  if check() then
    trixi.run({ 'push' }, function()
      if check() then
        vim.cmd 'Git restore . | Git pull'
      end
    end)
  end
end, { desc = 'trixi-sync push, then git restore and pull' })
vim.keymap.set('n', '<leader>sp', sync 'push', { desc = 'trixi-sync push' })
vim.keymap.set('n', '<leader>sL', sync 'logs', { desc = 'trixi-sync logs' })
vim.keymap.set('n', '<leader>ss', sync 'status', { desc = 'trixi-sync status' })

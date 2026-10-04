-- ~/.config/nvim/after/lsp/julials.lua
-- Environment lookup (sysimage / lsp<ver> env) lives in `util.julials`; see `:JuliaInstallLSP`.
local julials = require 'util.julials'
local root_files = { 'Project.toml', 'JuliaProject.toml' }

-- 定义 activate_env 函数，否则下面 nvim_buf_create_user_command 会报错
local function activate_env(path)
  local bufnr = vim.api.nvim_get_current_buf()
  local julials_clients = vim.lsp.get_clients { bufnr = bufnr, name = 'julials' }
  if #julials_clients == 0 then
    vim.notify('No active julials client found', vim.log.levels.WARN)
    return
  end

  local function _activate_env(environment)
    if environment then
      for _, client in ipairs(julials_clients) do
        client:notify('julia/activateenvironment', { envPath = environment })
      end
      vim.notify('Julia environment activated: ' .. environment, vim.log.levels.INFO)
    end
  end

  if path then
    _activate_env(vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(path), ':p')))
  else
    -- 简化的选择逻辑，你可以根据需要保留原来的复杂逻辑
    local environments = vim.fs.find(root_files, { type = 'file', upward = true, limit = math.huge })
    environments = vim.tbl_map(vim.fs.dirname, environments)
    vim.ui.select(environments, { prompt = 'Select a Julia environment' }, _activate_env)
  end
end

return {
  -- Resolved when the server starts, so `:JuliaInstallLSP` takes effect without restarting nvim.
  cmd = function(dispatchers, config)
    local info = assert(julials.resolve(config.root_dir), 'no Julia LSP environment')
    return vim.lsp.rpc.start(julials.cmd(info), dispatchers, { cwd = config.cmd_cwd, env = config.cmd_env, detached = config.detached })
  end,
  filetypes = { 'julia' },
  -- Only start when an LSP environment exists; otherwise point at `:JuliaInstallLSP` once.
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, root_files)
    if julials.resolve(root) then
      on_dir(root)
    elseif not julials.warned then
      julials.warned = true
      vim.notify(
        ('No Julia LSP environment found (%s/lsp<major.minor>); run :JuliaInstallLSP'):format(julials.environments_dir()),
        vim.log.levels.WARN
      )
    end
  end,
  settings = {
    julia = {
      lint = {
        missingrefs = 'none',
        -- options:
        -- 'none'
        -- 'symbols'
        -- 'all'
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspJuliaActivateEnv', function(opts)
      activate_env(opts.args ~= '' and opts.args or nil)
    end, {
      desc = 'Activate a Julia environment',
      nargs = '?',
      complete = 'file',
    })
  end,
}

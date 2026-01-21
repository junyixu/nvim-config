-- ~/.config/nvim/after/lsp/julials.lua

local env_path = vim.fn.expand '~/.julia/environments/nvim-lspconfig/'
local sysimage_path = env_path .. 'julials.so'
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

local cmd = {
  'julia',
  '--project=' .. env_path,
  '--startup-file=no',
  '--history-file=no',
  '--sysimage=' .. sysimage_path,
  '--sysimage-native-code=yes',
  '-e',
  [[
      using LanguageServer, SymbolServer, StaticLint
      depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
      project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
      server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path);
      server.runlinter = true;
      run(server);
    ]],
}

return {
  cmd = cmd,
  filetypes = { 'julia' },
  root_markers = root_files,
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

    -- 立即在该 buffer 中禁用 diagnostics
    vim.diagnostic.enable(false, { bufnr = bufnr })

    -- 设置 15 秒延迟启动
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.diagnostic.enable(true, { bufnr = bufnr })
      end
    end, 15000)
  end,
}

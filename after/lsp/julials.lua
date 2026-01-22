-- ~/.config/nvim/after/lsp/julials.lua

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function get_julia_env()
  -- 定义默认的 fallback 路径
  local default_path = vim.fn.expand('~/.julia/environments/nvim-lspconfig/')
  local manifest_path = vim.fn.getcwd() .. '/Manifest.toml'

  if exists(manifest_path) then
    -- 使用 io.lines 逐行读取，对大文件更友好
    for line in io.lines(manifest_path) do
      -- 使用 Lua Pattern 提取 major.minor 版本号 (例如 "1.12")
      local version = string.match(line, '^julia_version%s*=%s*"(%d+%.%d+)')
      
      if version then
        local lsp_path = vim.fn.expand('~/.julia/environments/lsp' .. version .. '/')
        -- 检查该版本的环境路径是否存在
        if exists(lsp_path) then
          return lsp_path
        end
        -- 如果找到了版本但对应的路径不存在，则跳出循环使用默认路径
        break
      end
    end
  end

  return default_path
end

-- 最终得到的路径
local env_path = get_julia_env()
local sysimage_path = env_path .. 'julials.so'

-- 1. 定义基础命令（所有情况通用的部分）
local final_cmd = {
  'julia',
  '--project=' .. env_path,
  '--startup-file=no',
  '--history-file=no',
}

-- 2. 如果 sysimage 存在，动态插入 flags
-- 注意：这里使用之前定义的 exists 函数（返回 boolean）
if exists(sysimage_path) then
  vim.list_extend(final_cmd, {
    '--sysimage=' .. sysimage_path,
    '--sysimage-native-code=yes',
  })
end

-- 3. 最后拼接执行脚本的部分
vim.list_extend(final_cmd, {
  '-e',
  [[
    using LanguageServer, SymbolServer, StaticLint
    depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
    project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
    @info "LSP Started" project_path depot_path
    server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path);
    server.runlinter = true;
    run(server);
  ]],
})
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
  cmd = final_cmd ,
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

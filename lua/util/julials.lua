-- Locate / install the Julia LanguageServer environment used by `after/lsp/julials.lua`.
--
-- Lookup order:
--   1. `<depot>/environments/lsp<major.minor>/julials.so` matching the active `julia` version
--      (built with PackageCompiler.create_sysimage) -> run with `--sysimage`
--   2. any `<depot>/environments/lsp<major.minor>/` env (matching version preferred) -> plain `--project`
--   3. nothing found -> caller warns and points to `:JuliaInstallLSP`
local M = {}

local joinpath = vim.fs.joinpath

M.packages = { 'LanguageServer', 'SymbolServer', 'StaticLint' }
M.sysimage_name = 'julials.so'

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

--- First entry of `JULIA_DEPOT_PATH` (or `~/.julia`) + `/environments`
function M.environments_dir()
  local depot = vim.env.JULIA_DEPOT_PATH and vim.split(vim.env.JULIA_DEPOT_PATH, vim.fn.has 'win32' == 1 and ';' or ':', { trimempty = true })[1]
  return joinpath(vim.fs.normalize(depot or '~/.julia'), 'environments')
end

local version_cache = {}

--- `major.minor` of the `julia` that runs in `cwd` (juliaup overrides are per directory)
---@param cwd? string
---@return string?
function M.julia_version(cwd)
  cwd = cwd or vim.uv.cwd()
  if version_cache[cwd] == nil then
    local ok, res = pcall(function()
      return vim.system({ 'julia', '--startup-file=no', '--version' }, { text = true, cwd = cwd }):wait()
    end)
    version_cache[cwd] = ok and res.code == 0 and res.stdout and res.stdout:match '(%d+%.%d+)' or false
  end
  return version_cache[cwd] or nil
end

local function version_key(v)
  local major, minor = v:match '^(%d+)%.(%d+)$'
  return tonumber(major) * 1000 + tonumber(minor)
end

--- `lsp<major.minor>` envs, the one matching `version` first, then newest first
---@param version? string
local function lsp_envs(version)
  local root = M.environments_dir()
  local envs = {}
  for name, type in vim.fs.dir(root) do
    local v = name:match '^lsp(%d+%.%d+)$'
    if v and (type == 'directory' or type == 'link') then
      envs[#envs + 1] = { version = v, path = joinpath(root, name) }
    end
  end
  table.sort(envs, function(a, b)
    if (a.version == version) ~= (b.version == version) then
      return a.version == version
    end
    return version_key(a.version) > version_key(b.version)
  end)
  return envs
end

---@class JuliaLspEnv
---@field env string project directory holding LanguageServer & co.
---@field sysimage? string sysimage to load, if one was built for this julia version

---@param cwd? string
---@return JuliaLspEnv?
function M.resolve(cwd)
  local version = M.julia_version(cwd)
  local envs = lsp_envs(version)
  -- a sysimage is tied to the julia version that built it
  for _, e in ipairs(envs) do
    local so = joinpath(e.path, M.sysimage_name)
    if (version == nil or e.version == version) and exists(so) then
      return { env = e.path, sysimage = so }
    end
  end
  for _, e in ipairs(envs) do
    if exists(joinpath(e.path, 'Project.toml')) then
      return { env = e.path }
    end
  end
end

local server_script = [[
  using LanguageServer, SymbolServer, StaticLint
  depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
  project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
  @info "LSP Started" project_path depot_path
  server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path);
  server.runlinter = true;
  run(server);
]]

---@param info JuliaLspEnv
---@return string[]
function M.cmd(info)
  local cmd = { 'julia', '--project=' .. info.env, '--startup-file=no', '--history-file=no' }
  if info.sysimage then
    vim.list_extend(cmd, { '--sysimage=' .. info.sysimage, '--sysimage-native-code=yes' })
  end
  vim.list_extend(cmd, { '-e', server_script })
  return cmd
end

--- Create `<depot>/environments/lsp<major.minor>`, `Pkg.add` the server packages into it,
--- then (re)start julials on open Julia buffers.
---@param cwd? string
function M.install(cwd)
  if vim.fn.executable 'julia' ~= 1 then
    vim.notify('`julia` not found in PATH', vim.log.levels.ERROR)
    return
  end
  local version = M.julia_version(cwd)
  if not version then
    vim.notify('Could not determine the julia version (`julia --version` failed)', vim.log.levels.ERROR)
    return
  end
  local env = joinpath(M.environments_dir(), 'lsp' .. version)
  vim.fn.mkdir(env, 'p')

  local pkgs = table.concat(
    vim.tbl_map(function(p)
      return ('"%s"'):format(p)
    end, M.packages),
    ', '
  )
  local code = ('using Pkg; Pkg.add([%s])'):format(pkgs)
  vim.notify(('Installing %s into `%s` ...'):format(table.concat(M.packages, ', '), env), vim.log.levels.INFO)

  vim.system({ 'julia', '--project=.', '--startup-file=no', '--history-file=no', '-e', code }, { text = true, cwd = env }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify(('Julia LSP install failed (exit %d):\n%s'):format(res.code, res.stderr or ''), vim.log.levels.ERROR)
        return
      end
      vim.notify(('Julia LSP installed in `%s`'):format(env), vim.log.levels.INFO)
      M.warned = false
      -- re-fire FileType so open Julia buffers attach to the new server
      vim.lsp.enable 'julials'
    end)
  end)
end

return M

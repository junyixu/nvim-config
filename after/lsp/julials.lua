-- ~/.config/nvim/after/lsp/julials.lua
local env_path = vim.fn.expand '~/.julia/environments/nvim-lspconfig/'
local sysimage_path = env_path .. 'julials.so'

return {
  cmd = {
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
  },
}

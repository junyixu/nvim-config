---@brief
---
--- https://github.com/aviatesk/JETLS.jl
---
--- Alternative Julia language server; mutually exclusive with `julials` (see lua/config/lsp.lua).

-- JETLS resets LOAD_PATH to ["@", "@v#.#", "@stdlib"], so standalone scripts (no Project.toml)
-- resolve packages via "@". Point it at the sandbox env when present and JULIA_PROJECT is unset.
local cmd_env
if (vim.env.JULIA_PROJECT or '') == '' and vim.uv.fs_stat(vim.fn.expand '~/.julia/environments/sandbox/Project.toml') then
  cmd_env = { JULIA_PROJECT = '@sandbox' }
end

---@type vim.lsp.Config
return {
  cmd = { vim.fn.expand '~/.julia/bin/jetls', 'serve' },
  cmd_env = cmd_env,
  filetypes = { 'julia' },
  root_markers = { 'Project.toml' },
}

---@brief
---
--- https://github.com/aviatesk/JETLS.jl
---
--- Alternative Julia language server; mutually exclusive with `julials` (see lua/config/lsp.lua).

---@type vim.lsp.Config
return {
  cmd = { vim.fn.expand '~/.julia/bin/jetls', 'serve' },
  filetypes = { 'julia' },
  root_markers = { 'Project.toml' },
}

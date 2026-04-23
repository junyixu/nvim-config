-- folke/lazydev.nvim – Lua helper for Neovim configs

return {
  'folke/lazydev.nvim',
  priority = 1000,
  ft = 'lua',
  opts = {
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
    },
  },
}

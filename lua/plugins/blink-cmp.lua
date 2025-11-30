-- saghen/blink.cmp – main completion engine

return {
  'saghen/blink.cmp',
  event = 'VimEnter',
  version = '1.*',
  dependencies = {
    'L3MON4D3/LuaSnip',
    'folke/lazydev.nvim',
  },
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = {
      -- NOTE: Keep Blink's default preset but let the plain Neovim mappings in
      -- plugin/luasnip.vim own <Tab>/<S-Tab>, so snippet expansion/jumps still
      -- work even when the completion menu is visible.
      preset = 'default',
      ['<Tab>'] = false,
      ['<S-Tab>'] = false,
      ['<C-f>'] = false,
      ['<C-b>'] = false,
      ['<C-e>'] = false,
    },
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },
    sources = {
      default = { 'lsp', 'path', 'cmdline', 'lazydev', 'snippets' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    snippets = { preset = 'luasnip' },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    signature = { enabled = true },
  },
}

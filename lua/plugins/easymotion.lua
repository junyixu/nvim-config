return {
  'justinmk/vim-sneak',
  lazy = false,
  dependencies = {
    'tpope/vim-repeat',
  },
  config = function()
    vim.cmd [[
      map f <Plug>Sneak_f
      map F <Plug>Sneak_F
      nnoremap <C-q> q
      map q <Plug>Sneak_s
      map Q <Plug>Sneak_S
    ]]
  end,
}

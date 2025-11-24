-- tpope/vim-fugitive – Git wrapper

return {
  'tpope/vim-fugitive',
  config = function()
    vim.cmd [[nnoremap <leader>gdv :Gvdiffsplit<cr>
nnoremap <leader>gds :Ghdiffsplit<cr>
]]
  end,
}

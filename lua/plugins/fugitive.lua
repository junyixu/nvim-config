-- tpope/vim-fugitive – Git wrapper

return {
  {
    'tpope/vim-fugitive',
    config = function()
      vim.cmd [[nnoremap <leader>gdv :Gvdiffsplit<cr>
nnoremap <leader>gds :Ghdiffsplit<cr>
]]
    end,
  },
  { 'tpope/vim-rhubarb', dependencies = {
    'tpope/vim-fugitive',
  } },
  {
    'rbong/vim-flog',
    lazy = true,
    cmd = { 'Flog', 'Flogsplit', 'Floggit' },
    dependencies = {
      'tpope/vim-fugitive',
    },
  },
}

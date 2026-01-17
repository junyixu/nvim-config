-- tpope/vim-fugitive – Git wrapper

return {
  {
    'tpope/vim-fugitive',
    lazy = true,
    cmd = {
      'G',
      'Git',
      'Gw',
      'Gwrite',
      'Gread',
      'Ge',
      'Gedit',
      'Gdiffsplit',
      'Gvdiffsplit',
      'Ghdiffsplit',
      'Gclog',
      'GRemove',
      'GDelete',
      'GMove',
      'GRename',
    },
  },
  { 'tpope/vim-rhubarb', lazy = true, cmd = { 'GBrowse' }, dependencies = {
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

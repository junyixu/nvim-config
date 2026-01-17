silent! command -nargs=0 EditFtPlugin execute "vsp ~/.config/nvim/ftplugin/" . &filetype . '.vim'
nmap <leader>ef :EditFtPlugin<CR>

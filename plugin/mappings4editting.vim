silent! command -nargs=0 EditFtPlugin execute "vsp ~/.vim/ftplugin/" . &filetype . '.vim'
nmap <leader>ef :EditFtPlugin<CR>

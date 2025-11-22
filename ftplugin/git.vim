setlocal foldmethod=syntax
setlocal foldlevel=0
" s to use as window prefix
nmap <buffer> s <C-w>
nnoremap <buffer> com :Git checkout main<cr>
nnoremap <buffer> cob :Git checkout -b 
nnoremap <buffer> cbd :Git branch -d <C-R>=expand("<cWORD>")<CR>
nnoremap <buffer> cbD :Git branch -D <C-R>=expand("<cWORD>")<CR>
nnoremap <buffer> cm. :Git merge <C-R>=expand("<cWORD>")<CR>

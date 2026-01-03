setlocal foldmethod=syntax
setlocal foldlevel=1

" 覆盖 fugitive 的 s 键映射，改用 flash
nnoremap <buffer> s <cmd>lua require('flash').jump()<CR>
" 给 fugitive 的 stage 功能分配其他键位
nnoremap <buffer> <localleader>s :Git stage<CR>

nnoremap <buffer> <localleader>l :Git pull<CR>
nnoremap <buffer> <localleader>f :Git fetch<CR>
nnoremap <buffer> <localleader>p :Git push<CR>
nnoremap <buffer> <localleader>c<space> :Git commit -m ""<LEFT>
nnoremap <buffer> <localleader>cc :Git commit -m "update"<cr>

" TODO git checkout $(git_main_branch)
nnoremap <buffer> com :Git checkout main<cr>
nnoremap <buffer> cob :Git checkout -b 
nnoremap <buffer> cbd :Git branch -d 

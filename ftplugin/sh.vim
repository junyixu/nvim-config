" 设置格式化时制表符占用空格数
setlocal shiftwidth=2
" 让 vim 把连续数量的空格视为一个制表符
setlocal softtabstop=2
" 设置编辑时制表符占用空格数
setlocal tabstop=2

" ===================== slime ======================{{{
nmap <silent><buffer> <CR> <Plug>SlimeLineSend
xmap <silent><buffer> <CR> <Plug>SlimeRegionSend
nmap <silent><buffer> <space><space> <Plug>SlimeParagraphSend
" ===================== end slime ======================}}}

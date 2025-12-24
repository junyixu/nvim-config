" ============================================================================
" LaTeX/TeX Related Functions
" ============================================================================
" TeX 特定的工具函数

" LaTeX section to file conversion
" 将 section 转换为 input 并创建对应文件
function! tex#sec2file() abort
    exec 'normal yypk0'
    exec 's/section/input'
    exec 'normal %h'
    exec "sp <cfile>.tex"
    " 跳转回之前的窗口
    exec 'wincmd p'
    exec 'normal jVj]['
endfunction

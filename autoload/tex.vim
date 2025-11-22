" ============================================================================
" LaTeX/TeX Related Functions
" ============================================================================
" TeX 特定的工具函数

" 延迟加载 ALE 的 TeX 检查器
" 根据拼写语言设置相应的检查器
function! tex#lazy_load_ale() abort
    if &spelllang=='en_us' || &spelllang=='en_gb'
        let g:ale_linters['tex']=['textidote', 'lty']
    endif
endfunction

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
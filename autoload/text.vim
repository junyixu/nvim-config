" ============================================================================
" Text Processing Functions
" ============================================================================
" 用于文本处理相关的函数，如中文字符统计等

" 数中文字符有多少个
" 使用方法：在 visual 模式下选择文本，然后调用 text#chinese_count()
function! text#chinese_count() range abort
    let save = @z
    silent exec 'normal! gv"zy'
    let text = @z
    let @z = save
    silent exec 'normal! gv'
    let cc = 0
    for char in split(text, '\zs')
        if char2nr(char) >= 0x2000
            let cc += 1
        endif
    endfor
    echo "Count of Chinese charasters is:"
    echo cc
endfunction
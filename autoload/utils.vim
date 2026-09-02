" ============================================================================
" Utility Functions
" ============================================================================
" 通用工具函数

" 运行命令并复制结果到剪贴板
function! utils#exec_cmd(expr) abort
    if exists('*execute')
        let @" = execute(a:expr, '')
    else
        try
            redir @"
            execute a:expr
        finally
            redir END
        endtry
    endif
    let result = @"
    let result = substitute(result, '^\n\(.*\)', '\1', 'g')
    let result = substitute(result, '^\(.*\)\n', '\1', 'g')
    " system(result .. ' | xclip -selection clipboard -in')
    return result
endfunction

" 检测是否是临时粘贴文件
function! utils#is_tmp_pasted() abort
    if expand("%:p") == "/tmp/new"
        return 1
    else 
        return 0
    endif
endfunction

" 复制文件路径和行号到剪贴板 (格式: filepath|linenumber)
" 用于外部工具集成，如 syntax/index.vim
function! utils#copy_file_entry() abort
    let @+ = expand("%:p").'|'.line(".")
endfunction

" 复制文件完整路径到剪贴板
" 用于外部工具或脚本引用
function! utils#copy_file_path() abort
    let @+ = expand("%:p")
endfunction
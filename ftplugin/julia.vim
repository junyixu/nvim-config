" Julia formatters emit spaces; match that so Tree-sitter inserts spaces too
setlocal expandtab
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal iskeyword+=!
" setlocal iskeyword+=∂

" let b:delimitMate_quotes = "\""
nnoremap <silent><buffer> <localleader>d :call slime#send("@doc " . expand("<cword>") . "\r")<CR>
vnoremap <silent><buffer> <localleader>d :<c-u>call slime#send("@doc " . @* . "\r")<CR>
vnoremap <silent><buffer> <localleader>l :<c-u>call slime#send("@less " . @* . "\r")<CR>
noremap <buffer> <localleader>m :call slime#send("methods(" . expand("<cword>") . ")\r")<cr>
noremap <buffer> <localleader>t :call slime#send("typeof(" . expand("<cword>") . ")\r")<cr>
noremap <buffer> <localleader>ss :call slime#send("size(" . expand("<cword>") . ")\r")<cr>
" https://stackoverflow.com/questions/71203241/how-to-see-parameters-of-a-struct-in-julia
" 查看结构体成员
nnoremap <buffer> <localleader>sf :call slime#send("fieldnames(typeof(" . expand("<cword>") . "))\r")<cr>
vnoremap <buffer> <localleader>sf :call slime#send("fieldnames(typeof(" . @* . "))\r")<cr>
nnoremap <buffer> <localleader>ps :call slime#send("plt.show()\r")<cr>
nnoremap <buffer> <localleader>pw :call slime#send('plt.savefig("./figures/$(bytes2hex(rand(UInt8, 4))).pdf", bbox_inches="tight");plt.show()'.."\r")<cr>
noremap <buffer> <localleader>li :call slime#send(expand("<cword>") . "\r")<cr>
" noremap <leader>sje :call slime#send("@edit " . expand("<cword>") . "\r")<cr>


let g:latex_to_unicode_auto=1
" let g:latex_to_unicode_cmd_mapping=['<S-Tab>']

" Initialize LaTeX-to-Unicode for Julia files
call LaTeXtoUnicode#Refresh()
" Set up delayed initialization for auto-substitution (like julia-vim does)
augroup JuliaL2UInit
  autocmd!
  autocmd InsertEnter <buffer> let g:did_insert_enter = 1 | call LaTeXtoUnicode#Init(0)
augroup END
noremap <expr> <F7> LaTeXtoUnicode#Toggle()

let g:julia_cell_use_primary_selection=1
let g:julia_cell_cmd='@paste'
let b:slime_cell_delimiter = "# %%"
let g:julia_cell_delimit_cells_by = "tags"
let g:julia_cell_tag = "# %%"
setlocal omnifunc=syntaxcomplete#Complete

" Wrap whole-cell sends so the REPL sees `begin ... end;` and suppresses output.
function! _EscapeText_julia(text) abort
  if get(b:, 'julia_slime_silent_cell', 0)
    let l:text = a:text
    if l:text !~ "\n$"
      let l:text .= "\n"
    endif
    return "begin\n" . l:text . "end;\n"
  endif
  return a:text
endfunction

function! s:SlimeSendCellSilent() abort
  let b:julia_slime_silent_cell = 1
  try
    call slime#send_cell()
  finally
    unlet! b:julia_slime_silent_cell
  endtry
endfunction

" 不要在 ] 的后面按'自动拓展为 ''
let b:delimitMate_smart_quotes = '\%(\w\|[^[:punct:][:space:]]\|\]\|\%(\\\\\)*\\\)\%#\|\%#\%(\w\|[^[:space:][:punct:]]\)'

command! JuliaNormalModeCreateCell :execute 'normal! :set paste<CR>m`O# %%<ESC>``:set nopaste<CR>'
command! JuliaVisualModeCreateCell :execute 'normal! gvD:set paste<CR>O# %%<CR># %%<ESC>P:set nopaste<CR>'
command! JuliaInsertModeCreateCell :execute 'normal! I# %% '

nnoremap <buffer><silent> <M-c> :JuliaNormalModeCreateCell<CR>
vnoremap <buffer><silent> <M-c> :<C-u>JuliaVisualModeCreateCell<CR>

noremap <buffer><localleader>fb <Cmd>call julia#toggle_function_blockassign()<CR>
xmap <silent><buffer> <CR> <Plug>SlimeRegionSend
xmap <silent><buffer> <localleader>r :<c-u>call slime#send("@paste" . "\r")<CR>
nmap <silent><buffer> <localleader>C <Plug>SlimeConfig
nmap <silent><buffer> <M-CR> :call <SID>SlimeSendCellSilent()<CR>
nmap <silent><buffer> <C-CR> :call <SID>SlimeSendCell()<CR>
nmap <silent><buffer> <S-CR> :call <SID>SlimeSendCell()<CR>/# %%<CR>
nmap <silent><buffer> <CR> :exec "normal \<Plug>SlimeLineSend"<cr>

" map <Leader>jr to run entire file
nnoremap <buffer> <Leader>r :JuliaCellRun<CR>

" map <Leader>jc to execute the current cell

" nmap <silent><buffer> <localleader>r :JuliaCellExecuteCell<CR>
nnoremap <silent><buffer> <localleader>r :exec "normal \<Plug>SlimeSendCell"<cr>
nnoremap <silent><buffer> <localleader>R :call <SID>SlimeSendCellSilent()<CR>

" map <Leader>jC to execute the current cell and jump to the next cell
nnoremap <buffer> <localLeader>R :JuliaCellExecuteCellJump<CR>

" map <Leader>jl to clear Julia screen
nnoremap <buffer> <localLeader><c-l> :JuliaCellClear<CR>

" map <Leader>jp and <Leader>jn to jump to the previous and next cell header
nnoremap <buffer><silent> ]5 /# %%<CR>
nnoremap <buffer><silent> [5 ?# %%<CR>


" jupyter_ascending
let g:jupyter_ascending_match_pattern     = '.sync.jl'
let g:jupyter_ascending_default_mappings=0
nmap <buffer> <localLeader>x <Plug>JupyterExecute
nmap <buffer> <localLeader>X <Plug>JupyterExecuteAll

" diary
" 有报错，现在有事，以后再修，先用 isWSL 糊下
" "~/Notes/diary/2021-11-01.md" 7L, 129C
" VimTeX: latexmk is not executable
" VimTeX: Compiler was not initialized!
" VimTeX: latexmk is not executable
" VimTeX: Compiler was not initialized!
" Press ENTER or type command to continue
"if !$SSH_CONNECTION && $isWSL!='1'
"	call vimtex#init()
"	call vimtex#text_obj#init_buffer()
"	call vimtex#options#init()
"	omap <silent><buffer> id <plug>(vimtex-id)
"	omap <silent><buffer> ad <plug>(vimtex-ad)
"	xmap <silent><buffer> id <plug>(vimtex-id)
"	xmap <silent><buffer> ad <plug>(vimtex-ad)
"	omap <silent><buffer> i$ <plug>(vimtex-i$)
"	omap <silent><buffer> a$ <plug>(vimtex-a$)
"	xmap <silent><buffer> i$ <plug>(vimtex-i$)
"	xmap <silent><buffer> a$ <plug>(vimtex-a$)
"endif

setlocal suffixesadd=.md
let b:coc_suggest_disable = 1
nnoremap <buffer> <C-l> <Cmd>call markdown#toggle_todo()<CR>
"setlocal comments=fb:*,b:-,fb:+,n:>,b:>
"setlocal comments+=b:>
"setlocal fo+=r

setlocal expandtab
setlocal shiftwidth=2
setlocal softtabstop=2

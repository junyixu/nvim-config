" let b:tex_stylish=1
let g:tex_verbspell=0
"---------------------latex---------------------------------"
let b:ale_linter_aliases = ['tex', 'text']

" 小时物理百科
noremap <silent><buffer> <leader>vh :! xdg-open http://wuli.wiki/online/%:r.html<cr>
nnoremap <silent><buffer> <S-CR> :! xdg-open http://wuli.wiki/online/<cfile>.html<cr>
inoremap <silent><buffer> <S-CR> \\<CR>
nnoremap <buffer> <localleader>r :VimtexCompile<CR>
nnoremap <buffer> <localleader>e :VimtexError<CR>
nnoremap <buffer> <localleader>k :VimtexStop<CR>
nnoremap <buffer> <localleader>v :VimtexView<CR>
nnoremap <buffer> <localleader>c :VimtexClean<CR>

nnoremap <buffer> <localleader>s :AsyncRun! -mode=hide tex-screenshot<CR>
nnoremap <buffer> <localleader>S :AsyncRun! -mode=hide sleep 3; tex-screenshot<CR>

vnoremap <buffer><silent> <localleader>r "zc\red{<C-R>z}<ESC>
vnoremap <buffer><silent> <localleader>h "zc\hl{<C-R>z}<ESC>
vnoremap <buffer><silent> <localleader>b "zc\textbf{<C-R>z}<ESC>
vnoremap <buffer><silent> <localleader>i "zc\textit{<C-R>z}<ESC>
vnoremap <buffer><silent> <localleader>u "zc\uline{<C-R>z}<ESC>
vnoremap <buffer><silent> <localleader>e "zc\emph{<C-R>z}<ESC>

nnoremap <buffer> <localleader><tab> nla
inoremap <buffer><silent> <C-j> <esc>l%%a

" call textobj#user#plugin('tex', {
" \  'double-quote': {
" \     '*pattern*': ['``', "''"],
" \     'select-a': 'aQ',
" \     'select-i': 'iQ',
" \   },
" \  'biglimiter': {
" \     '*pattern*': ['\\{', '\\}'],
" \     'select-a': 'aU',
" \     'select-i': 'iU',
" \   },
" \ })


"call vimtex#imaps#add_map({
"	\ 'lhs' : 'b',
"	\ 'rhs' : 'vimtex#imaps#style_math("vb")',
"	\ 'expr' : 1,
"	\ 'leader' : '#',
"	\ 'wrapper' : 'vimtex#imaps#wrap_math'
"	\})
"
"call vimtex#imaps#add_map({
"	\ 'lhs' : '(',
"	\ 'rhs' : '\left(',
"	\ 'leader' : '#',
"	\ 'wrapper' : 'vimtex#imaps#wrap_math'
"	\})
"
" call vimtex#imaps#add_map({
"   \ 'lhs' : '<C-L>',
"   \ 'rhs' : '\item ',
"   \ 'leader' : '',
"   \ 'wrapper' : 'vimtex#imaps#wrap_environment',
"   \ 'context' : ["itemize", "enumerate"],
"   \})


" let b:vimtex_main = 'main.tex'

" TODO
" 部分公式预览
function ScreenLine()
	" 当前行
	let a=line(".")
	" 屏幕首行
	let b=line("w0")
 return a - b - 2
endfunction
function ScreenColumn()
 return col(".") + 20
endfunction
nnoremap <silent><buffer> <localleader><localleader> :call g:PreviewEq4LaTeX()<cr>
vnoremap <silent><buffer> <CR> :call g:VisualPreviewEq4LaTeX()<cr>

nnoremap <buffer> <F8> :compiler vlty<CR>

" 设置格式化时制表符占用空格数
setlocal shiftwidth=2
" 让 vim 把连续数量的空格视为一个制表符
setlocal softtabstop=2
" 设置编辑时制表符占用空格数
setlocal tabstop=2
setlocal expandtab
" let b:indentLine_color_term="81" " 蓝色
" let b:indentLine_color_gui='#81a2be' " 蓝色

" highlight Conceal cterm=NONE ctermfg="81"
" highlight Conceal gui=NONE guifg=81a2be

"autocmd filetype tex nnoremap <F10> :w<cr>:!xelatex %<cr>
"autocmd BufNewFile,BufRead *.tex inoremap ( (
"autocmd BufNewFile,BufRead *.tex inoremap { {

"autocmd BufNewFile,BufRead *.tex inoremap $ $$<ESC>i
"autocmd BufNewFile,BufRead *.tex inoremap $$ <ESC>o\[<CR>\]<ESC>O
" 词典 https://zhuanlan.zhihu.com/p/27027319
" setlocal dictionary+=~/.vim/plugin/english.dict
" setlocal dictionary+=~/.vim/plugin/latex.dict
"set complete+=k

setlocal spell spelllang=en_us,cjk		"忽略中文对英文进行拼写检查

" https://github.com/gillescastel/inkscape-figures
" 如果是 <C-i> 就会和 Ultisnips 的 tab 冲突
" 后来得知 <C-i> 就是 tab <C-m> 就是 <cr>

inoremap <M-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.b:vimtex.root.'/figures/"'<CR><CR>:w<CR>
" nnoremap <localleader><localleader>f : silent exec '!inkscape-figures edit "'.b:vimtex.root.'/figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>
" nnoremap <localleader><localleader>p o\includegraphics[width=0.5\textwidth]{figures/<C-r>+}<esc>

" 句首字母大写
" https://superuser.com/questions/737130/automatically-capitalize-the-first-letter-of-sentence-in-vim
" for char in split('abcdefghijklmnopqrstuvwxyz', '\zs')
"     exe printf("inoremap <expr> %s search('[.!?]\\_s\\+\\%%#', 'bcnw') ? '%s' : '%s'", char, toupper(char), char)
" endfor

" for char in split('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '\zs')
"     exe printf("inoremap <expr> %s search('[.!?]\\_s\\+\\%%#', 'bcnW') ? '%s' : '%s'", char, tolower(char), char)
" endfor

" https://github.com/tpope/vim-surround/issues/201#issuecomment-246439841
if exists('g:loaded_surround')
    " vim-surround: q for `foo' and Q for ``foo''
    let b:surround_{char2nr('q')} = "`\r'"
    let b:surround_{char2nr('Q')} = "``\r''"
endif

" let b:delimitMate_quotes = "\" ' `"

" 锚点
" 定义人工锚点 
" inoremap <buffer> <silent> <C-,> <++>
" 切换到下一个锚点  
" inoremap <buffer> <silent> <C-j> <Esc>/<+\w*+><CR>:nohlsearch<CR>cgn
inoremap <buffer> <silent> <M-j> <Esc>/<++><CR>c4l

nnoremap <buffer><silent> <localleader>f :call tex#sec2file()<CR>
" source $HOME/.vim/ycmMaps.vim
vmap <localleader>c c$\ce{"}$<ESC>

" Diary Navigation Plugin

if exists("g:loaded_last_diary") || !has('python3')
  finish
endif
let g:loaded_last_diary = 1

" Configuration
let g:diary_dir = get(g:, 'diary_dir', expand('~/Notes/diary'))
let g:diary_max_search_days = get(g:, 'diary_max_search_days', 365)

" Commands - use autoload functions for lazy loading
command! -nargs=0 DiaryPrev call diary#prev()
command! -nargs=0 DiaryNext call diary#next()

" Key mappings for markdown files
autocmd FileType markdown nnoremap <silent><buffer> <localLeader>p <Cmd>call diary#prev()<CR>
autocmd FileType markdown nnoremap <silent><buffer> <localLeader>n <Cmd>call diary#next()<CR>

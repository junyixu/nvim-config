nnoremap ,w,w :exec 'e ~/Notes/diary/' .. strftime('%Y/%m/%F') .. '.md'<cr>:tcd %:h<cr>:tcd ../../..<cr>
nnoremap ,w,t :exec 'tabe ~/Notes/diary/' .. strftime('%Y/%m/%F') .. '.md'<cr>:tcd %:h<cr>:tcd ../../..<cr>
nnoremap ,ww :e ~/Notes/index.md<cr>:tcd %:h<cr>
nnoremap ,wt :tabe ~/Notes/index.md<cr>:tcd %:h<cr>

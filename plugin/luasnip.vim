" press <Tab> to expand or jump in a snippet. These can also be mapped separately
" via <Plug>luasnip-expand-snippet and <Plug>luasnip-jump-next.
imap <silent><expr> <Tab> luasnip#expand_or_jumpable()
      \ ? '<Plug>luasnip-expand-or-jump'
      \ : copilot#GetDisplayedSuggestion().text !=# '' ? copilot#Accept("\<Tab>") : "\<Tab>"
"imap <silent><expr> <Tab> luasnip#expandable() ? '<Plug>luasnip-expand' : '<Tab>'
"imap <silent> <Plug>(luasnip-expand-only) <Cmd>lua require'luasnip'.expand()<CR>
"imap <silent><expr> <Tab> luasnip#expandable() ? '<Plug>(luasnip-expand-only)' : "\<Tab>"

" -1 for jumping backwards.
inoremap <silent> <C-b> <cmd>lua require'luasnip'.jump(-1)<Cr>
snoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>

snoremap <silent> <C-f> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
inoremap <silent> <C-f> <cmd>lua require('luasnip').jump(1)<Cr>
"snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

" For changing choices in choiceNodes (not strictly necessary for a basic setup).
imap <silent><expr> <C-e> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<A-n>'
smap <silent><expr> <C-e> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<A-n>'

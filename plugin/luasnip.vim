" [documentation]:
" NOTE:
" plugin/ 下面的 .vim 文件会在启动时无条件加载（先于 after/，也早于大部分 filetype/
" autocmd 配置），所以把 <Tab> 映射放在 plugin/luasnip.vim 能保证始终生效，这
" 对 LuaSnip 这样的全局映射没问题。想精细控制加载顺序或条件（比如只在特定事件后注
" 册），就不太适合。
" 通常更可控的做法是把映射集中在某个 Lua 模块里（例如 lua/config/keymaps.lua），在
" init.lua 里 require 它，用 vim.keymap.set/vim.api.nvim_set_keymap 写映射；这样可
" 以利用 Lua 逻辑和 opts，还能按需延迟加载。若某些映射用 Vimscript 写更轻松，可以在
" Lua 模块里 vim.cmd [[imap ...]]，也可以保留像现在这样的小型 plugin/*.vim 文件——关
" 键是确保你清楚加载顺序、避免被后续插件覆盖。
"
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

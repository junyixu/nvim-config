lua << EOF
require 'essentials'
require 'lazy_nvim'
EOF

nnoremap sO :tab split<CR>
nnoremap so <c-w>o
nnoremap <leader>y :call utils#copy_to_smart_clipboard(claude#get_line_reference())<CR>
vnoremap <leader>y :<C-u>call utils#copy_to_smart_clipboard(claude#get_line_reference())<CR>

" ============================================================================
" Kitty Clipboard Integration
" ============================================================================
" Kitty 剪贴板集成功能

" 通过kitty复制寄存器内容到本地剪贴板
" 适用于在服务器上通过kitty终端复制内容到本地剪贴板
function! kitty#CopyFromRegister(reg) abort
    let l:text = getreg(a:reg)
    call system('echo ' . shellescape(l:text) . ' | kitten clipboard')
    echo "Content copied to local clipboard via kitty!"
endfunction

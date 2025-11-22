" ============================================================================
" UI Functions
" ============================================================================
" 用于 UI 交互相关的函数，如弹出窗口滚动等

" 弹出窗口滚动函数
" 用于在弹出窗口中滚动内容
function! ui#scroll_popup(down) abort
    let winid = popup_findinfo()
    if winid == 0
        return 0
    endif

    " if the popup window is hidden, bypass the keystrokes
    let pp = popup_getpos(winid)
    if pp.visible != 1
        return 0
    endif

    let firstline = pp.firstline + a:down
    let buf_lastline = str2nr(trim(win_execute(winid, "echo line('$')")))
    if firstline < 1
        let firstline = 1
    elseif pp.lastline + a:down > buf_lastline
        let firstline = firstline - a:down + buf_lastline - pp.lastline
    endif

    " The appear of scrollbar will change the layout of the content which will cause inconsistent height.
    call popup_setoptions( winid,
                \ {'scrollbar': 0, 'firstline' : firstline } )

    return 1
endfunction
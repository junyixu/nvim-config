return {
  {
    'github/copilot.vim',
    config = function()
      vim.cmd [[
        let g:copilot_filetypes = {
        \ 'xml': v:false,
        \ 'markdown': v:false,
        \ 'julia': v:true,
        \ }
        imap <C-Right> <Plug>(copilot-accept-word)
        imap <silent><expr> <M-f> copilot#GetDisplayedSuggestion().text !=# '' ? '<Plug>(copilot-accept-word)' : "\<M-f>"
      ]]
    end,
  },
}

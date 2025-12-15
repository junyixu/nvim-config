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
      ]]
    end,
  },
}

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
      ]]
    end,
  },
}

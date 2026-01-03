return {
  {
    'github/copilot.vim',
    config = function()
      vim.cmd [[
        imap <C-Right> <Plug>(copilot-accept-word)
        imap <silent><expr> <M-f> copilot#GetDisplayedSuggestion().text !=# '' ? '<Plug>(copilot-accept-word)' : "\<M-f>"
      ]]
    end,
  },
}

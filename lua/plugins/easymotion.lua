return {
  'justinmk/vim-sneak',
  lazy = false,
  dependencies = {
    'tpope/vim-repeat',
  },
  config = function()
    -- Sneak forward to character
    vim.keymap.set('n', 'f', '<Plug>Sneak_f', { desc = 'Sneak forward to character' })

    -- Sneak backward to character
    vim.keymap.set('n', 'F', '<Plug>Sneak_F', { desc = 'Sneak backward to character' })

    -- Clear q recording
    vim.keymap.set('n', '<C-q>', 'q', { desc = 'Remap q recording' })

    -- Sneak from cursor position
    vim.keymap.set('n', 'q', '<Plug>Sneak_s', { desc = 'Sneak from cursor position' })

    -- Sneak backward from cursor position
    vim.keymap.set('n', 'Q', '<Plug>Sneak_S', { desc = 'Sneak backward from cursor position' })
  end,
}

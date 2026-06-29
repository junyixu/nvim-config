-- GitHub Copilot through the native LSP client (copilot-language-server).
--   * Next Edit Suggestion (NES): normal-mode <Tab> accepts / walks edits.
--   * inline ghost text (insert mode): vim.lsp.inline_completion, accepted via
--     <Tab> in plugin/luasnip.vim and ftplugin/markdown.lua.
-- Requirements (already satisfied on this machine):
--   * `copilot-language-server` on PATH (installed via npm).
--   * auth reused from ~/.config/github-copilot (shared with old copilot.vim).
return {
  {
    'copilotlsp-nvim/copilot-lsp',
    init = function()
      vim.g.copilot_nes_debounce = 500
      vim.lsp.enable 'copilot_ls'

      -- insert-mode ghost text; only active in buffers where an
      -- inlineCompletion-capable client (copilot_ls) is attached.
      vim.lsp.inline_completion.enable(true)

      -- <Tab>: when a NES is pending, jump to it on the first press and apply
      -- on the next; otherwise fall back to <C-i> (jumplist newer, default <Tab>).
      vim.keymap.set('n', '<Tab>', function()
        local nes = require 'copilot-lsp.nes'
        if vim.b.nes_state then
          local _ = nes.walk_cursor_start_edit() or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
          return nil
        end
        return '<C-i>'
      end, { expr = true, desc = 'Copilot NES: accept / jumplist newer' })
      vim.cmd [[
      imap <silent><expr> <Tab> luasnip#expand_or_jumpable()
            \ ? '<Plug>luasnip-expand-or-jump'
            \ : luaeval("vim.lsp.inline_completion.get()") ? '' : "\<Tab>"
            ]]
    end,
  },
}

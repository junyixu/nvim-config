-- GitHub Copilot through the native LSP client (copilot-language-server).
-- Only insert-mode inline completion (ghost text) is used here. NES (Next Edit
-- Suggestion, the "edit after an edit" suggestions) is disabled on both the
-- server and client side.
--   * ghost text: vim.lsp.inline_completion, accepted via <F13> (= physical
--     <C-i>, see lua/config/keymaps.lua). Dedicated key rather than <Tab>/<C-i>
--     because suggestions arrive asynchronously, so a navigation key can be
--     hijacked between intent and keypress.
-- Requirements (already satisfied on this machine):
--   * `copilot-language-server` on PATH (installed via npm).
--   * auth reused from ~/.config/github-copilot (shared with old copilot.vim).
return {
  {
    'copilotlsp-nvim/copilot-lsp',
    enabled = vim.g.full,
    init = function()
      -- Keep the diary private: ~/Notes/diary/YYYY/MM/YYYY-MM-DD.md never gets a
      -- copilot_ls client. A `root_dir` function that skips its `on_dir` callback
      -- aborts the start entirely (see lsp_enable_callback in runtime/lua/vim/lsp.lua),
      -- so no textDocument/didOpen is sent -- unlike detaching on LspAttach, which
      -- would upload the buffer first.
      vim.lsp.config('copilot_ls', {
        root_dir = function(bufnr, on_dir)
          local name = vim.api.nvim_buf_get_name(bufnr)
          if not name:match '/diary/%d%d%d%d/%d%d/%d%d%d%d%-%d%d%-%d%d%.md$' then
            on_dir(vim.uv.cwd())
          end
        end,

        -- NES off: tell the server not to compute suggestions, and replace its
        -- on_init so the upstream TextChanged/TextChangedI -> request_nes hooks
        -- are never installed. didFocus is kept from the upstream on_init.
        settings = { nextEditSuggestions = { enabled = false } },
        on_init = function(client)
          local au = vim.api.nvim_create_augroup('copilotlsp.init', { clear = true })
          vim.api.nvim_create_autocmd('BufEnter', {
            callback = function()
              local params = vim.lsp.util.make_text_document_params()
              client:notify('textDocument/didFocus', {
                textDocument = { uri = params.uri },
              })
            end,
            group = au,
          })
        end,
      })

      vim.lsp.enable 'copilot_ls'

      -- insert-mode ghost text; only active in buffers where an
      -- inlineCompletion-capable client (copilot_ls) is attached.
      vim.lsp.inline_completion.enable(true)

      -- <F13> = physical <C-i>: accept the Copilot ghost text; no-op otherwise.
      vim.keymap.set('i', '<F13>', function()
        vim.lsp.inline_completion.get()
      end, { desc = 'Copilot: accept inline completion' })
    end,
  },
}

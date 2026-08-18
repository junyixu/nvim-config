-- GitHub Copilot through the native LSP client (copilot-language-server).
--   * Next Edit Suggestion (NES): normal-mode <Tab> accepts / walks edits.
--   * inline ghost text (insert mode): vim.lsp.inline_completion, accepted via
--     <F13> (= physical <C-i>, see lua/config/keymaps.lua).
-- Key split rationale: ghost text arrives asynchronously, so putting it on <Tab>
-- means a suggestion can pop in between intent and keypress and swallow an
-- indent. <Tab> therefore keeps only deterministic, text-driven actions
-- (LuaSnip expand/jump, markdown table cells in ftplugin/markdown.lua); accepting
-- a completion is an explicit <F13>.
-- Requirements (already satisfied on this machine):
--   * `copilot-language-server` on PATH (installed via npm).
--   * auth reused from ~/.config/github-copilot (shared with old copilot.vim).
return {
  {
    'copilotlsp-nvim/copilot-lsp',
    init = function()
      vim.g.copilot_nes_debounce = 500

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
      })

      vim.lsp.enable 'copilot_ls'

      -- insert-mode ghost text; only active in buffers where an
      -- inlineCompletion-capable client (copilot_ls) is attached.
      vim.lsp.inline_completion.enable(true)

      -- <Tab> (normal): when a NES is pending, jump to it on the first press and
      -- apply on the next; otherwise a no-op -- jumplist newer lives on <F13>.
      vim.keymap.set('n', '<Tab>', function()
        local nes = require 'copilot-lsp.nes'
        if vim.b.nes_state then
          local _ = nes.walk_cursor_start_edit() or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
        end
      end, { desc = 'Copilot NES: accept / walk' })
      -- <Tab> (insert): LuaSnip expand/jump > literal tab. No Copilot here on
      -- purpose; ftplugin/markdown.lua extends this chain with table-cell nav.
      vim.keymap.set('i', '<Tab>', function()
        if require('luasnip').expand_or_locally_jumpable() then
          return '<Plug>luasnip-expand-or-jump'
        else
          return '<Tab>'
        end
      end, { expr = true, remap = true, replace_keycodes = true, silent = true, desc = 'LuaSnip expand/jump or tab' })
      -- <F13> = physical <C-i>: accept the Copilot ghost text; no-op otherwise.
      vim.keymap.set('i', '<F13>', function()
        vim.lsp.inline_completion.get()
      end, { desc = 'Copilot: accept inline completion' })
    end,
  },
}

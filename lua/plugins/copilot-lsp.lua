-- GitHub Copilot through the native LSP client (copilot-language-server).
--   * Next Edit Suggestion (NES): <C-y> accepts in both modes -- normal mode
--     here, insert mode through blink's keymap chain in lua/plugins/blink-cmp.lua
--     (menu accept first). <Esc> dismisses via the global map in
--     lua/config/keymaps.lua.
--   * inline ghost text (insert mode): vim.lsp.inline_completion, accepted via
--     <F13> (= physical <C-i>, see lua/config/keymaps.lua).
-- Key split rationale: suggestions arrive asynchronously, so a key that also has
-- a navigation meaning (<Tab>, <C-i>) can be hijacked between intent and
-- keypress. Copilot therefore sits on dedicated keys only: <C-y> in normal mode
-- and <F13> in insert mode. <Tab> is left to deterministic, text-driven actions
-- (LuaSnip expand/jump, markdown table cells) in insert mode and to the Tab
-- leader in normal mode. <CR> is not an option either -- slime owns it for
-- send-line in ftplugin/python.vim and ftplugin/julia.vim.
-- Requirements (already satisfied on this machine):
--   * `copilot-language-server` on PATH (installed via npm).
--   * auth reused from ~/.config/github-copilot (shared with old copilot.vim).
return {
  {
    'copilotlsp-nvim/copilot-lsp',
    enabled = vim.g.full,
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

      -- <C-y> (normal): when a NES is pending, jump to it on the first press and
      -- apply on the next; no-op otherwise. Its builtin meaning (scroll one line
      -- up) moved to <M-e> in lua/config/keymaps.lua.
      -- Deliberately not `expr`: applying a NES writes to the buffer, which is
      -- not allowed from an expr mapping (textlock).
      vim.keymap.set('n', '<C-y>', function()
        local nes = require 'copilot-lsp.nes'
        if vim.b.nes_state then
          local _ = nes.walk_cursor_start_edit() or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
        end
      end, { desc = 'Copilot NES: accept / walk' })
      -- <F13> = physical <C-i>: accept the Copilot ghost text; no-op otherwise.
      -- NES is not on this key -- it lives on <C-y> in both modes (insert side
      -- is wired through blink's keymap table, see lua/plugins/blink-cmp.lua).
      vim.keymap.set('i', '<F13>', function()
        vim.lsp.inline_completion.get()
      end, { desc = 'Copilot: accept inline completion' })
    end,
    config = function()
      -- Upstream bug, still present on main (1b6d827): nes/ui.lua:52 reads the
      -- old text with nvim_buf_get_lines(.., strict_indexing = false), which
      -- returns {} once the range starts past the last line. Only one branch
      -- guards num_old_lines == 0 (ui.lua:84-92); every other edit shape falls
      -- through to `old_lines[1]:sub(..)` at ui.lua:117 and throws out of the
      -- LSP handler. Happens when the buffer shrinks while the debounced
      -- request is in flight, or when the server proposes an edit on the
      -- phantom trailing line that LSP has and Neovim does not.
      -- An out-of-range suggestion cannot be rendered anyway, so drop it.
      local nes_ui = require 'copilot-lsp.nes.ui'
      local display_next_suggestion = nes_ui._display_next_suggestion
      nes_ui._display_next_suggestion = function(bufnr, ns_id, edits)
        local edit = edits and edits[1]
        if edit and edit.range.start.line >= vim.api.nvim_buf_line_count(bufnr) then
          return false
        end
        return display_next_suggestion(bufnr, ns_id, edits)
      end
    end,
  },
}

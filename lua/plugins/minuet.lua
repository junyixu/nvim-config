-- Inline code completion (ghost text) powered by DeepSeek FIM via minuet-ai.nvim.
-- Only insert-mode virtualtext completion is enabled (blink.cmp menu, in-process
-- LSP, and duet/NES are all off).
--   * ghost text: minuet virtualtext, accepted via <F13> (= physical <C-i>, see
--     lua/config/keymaps.lua). Dedicated key rather than <Tab>/<C-i> because
--     suggestions arrive asynchronously, so a navigation key can be hijacked
--     between intent and keypress.
--   * backend: DeepSeek FIM Completion API (Beta)
--     POST https://api.deepseek.com/beta/completions with model `deepseek-flash`
--     (DeepSeek-V4.1-Flash, non-thinking mode only).
-- Requirements:
--   * `DEEPSEEK_API_KEY` environment variable set.
--   * `curl` on PATH.
return {
  {
    'milanglacier/minuet-ai.nvim',
    main = 'minuet',
    enabled = vim.g.full,
    opts = {
      provider = 'openai_fim_compatible',
      n_completions = 1,
      context_window = 16000,
      throttle = 1000,
      debounce = 400,
      request_timeout = 3,
      notify = 'warn',
      -- Keep private notes and non-file buffers out of remote completion requests.
      enable_predicates = {
        function()
          if vim.bo.buftype ~= '' then
            return false
          end
          local name = vim.api.nvim_buf_get_name(0)
          -- Keep the diary private: ~/Notes/diary/YYYY/MM/YYYY-MM-DD.md never
          -- triggers completion requests.
          if name:match '/diary/%d%d%d%d/%d%d/%d%d%d%d%-%d%d%-%d%d%.md$' then
            return false
          end
          local base = vim.fn.fnamemodify(name, ':t')
          if base == '.env' or base:match '^%.env%.' then
            return false
          end
          return true
        end,
      },
      provider_options = {
        openai_fim_compatible = {
          model = 'deepseek-flash',
          end_point = 'https://api.deepseek.com/beta/completions',
          api_key = 'DEEPSEEK_API_KEY',
          name = 'Deepseek',
          stream = true,
          optional = {
            max_tokens = 256,
            top_p = 0.9,
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = { '*' },
        auto_trigger_ignore_ft = {
          'typr',
          'gitcommit',
          'oil',
          'codecompanion',
          'snacks_picker_input',
          'TelescopePrompt',
        },
        show_on_completion_menu = false,
        keymap = {
          -- <F13> = physical <C-i>: accept the ghost text; no-op otherwise.
          accept = '<F13>',
        },
      },
      -- Only virtualtext is used; keep LSP and duet/NES disabled.
      lsp = {
        completion = { enable = false },
        inline_completion = { enable = false },
      },
      duet = {
        recent_edits = { enabled = false },
      },
    },
  },
}

-- stevearc/conform.nvim – formatting on save

return {
  'stevearc/conform.nvim',
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<space>F',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      local name = vim.api.nvim_buf_get_name(bufnr)
      if disable_filetypes[vim.bo[bufnr].filetype] or name:find('/diary/', 1, true) then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      markdown = { 'prettier' },
      html = { 'prettier' },
      tex = { 'tex-fmt' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
    },
  },
}

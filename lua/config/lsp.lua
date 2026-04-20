vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = {
    source = 'if_many',
    spacing = 2,
    format = function(diagnostic)
      local diagnostic_message = {
        [vim.diagnostic.severity.ERROR] = diagnostic.message,
        [vim.diagnostic.severity.WARN] = diagnostic.message,
        [vim.diagnostic.severity.INFO] = diagnostic.message,
        [vim.diagnostic.severity.HINT] = diagnostic.message,
      }
      return diagnostic_message[diagnostic.severity]
    end,
  },
}

vim.keymap.set('n', '<leader>td', function()
  local is_enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not is_enabled)

  -- Optional: Print the status to the command line
  if is_enabled then
    print 'Diagnostics disabled'
  else
    print 'Diagnostics enabled'
  end
end, { desc = 'Toggle Diagnostics' })

vim.keymap.set('n', '<leader>th', function()
  local is_enabled = vim.lsp.inlay_hint.is_enabled { bufnr = 0 }
  vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = 0 })

  -- Optional: Print the status to the command line
  if is_enabled then
    print 'Inlay Hints disabled'
  else
    print 'Inlay Hints enabled'
  end
end, { desc = 'Toggle Inlay Hints' })

vim.lsp.enable 'pyright'
vim.lsp.enable 'lua_ls'
vim.lsp.enable 'stylua'
vim.lsp.enable 'julials'
vim.lsp.enable 'clangd'
vim.lsp.enable 'marksman'
vim.lsp.enable 'texlab'

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    local function snacks_picker(method, fallback, opts)
      return function()
        local ok, snacks = pcall(require, 'snacks')
        if ok and snacks.picker and snacks.picker[method] then
          return snacks.picker[method](opts or {})
        end
        if fallback then
          return fallback()
        end
      end
    end

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- :help grr
    -- Pre-fill picker with Julia type annotations (e.g. ::ParticleLocation)
    -- from the current line, so multiple method definitions can be filtered quickly.
    map('grd', function()
      if vim.bo.filetype ~= 'julia' then
        return vim.lsp.buf.definition()
      end
      local types = {}
      for ann in vim.api.nvim_get_current_line():gmatch '::[%w%.]+' do
        types[#types + 1] = ann
      end

      local ok, snacks = pcall(require, 'snacks')
      if ok and snacks.picker then
        return snacks.picker.lsp_definitions { pattern = types[1] }
      end
      vim.lsp.buf.definition()
    end, '[G]oto [D]efinition')
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('gW', snacks_picker('lsp_workspace_symbols', vim.lsp.buf.workspace_symbol), 'Open Workspace Symbols')

    local function client_supports_method(client, method, bufnr)
      if vim.fn.has 'nvim-0.11' == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Treesitter configuration (Adapter for main branch)
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'

      ts.setup {}

      -- 建议只在初次安装或更新时运行，也可以直接写在 config 里
      -- local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'julia', 'python', 'yaml' }
      -- ts.install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local bufnr = args.buf
          pcall(vim.treesitter.start, bufnr)
        end,
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      enable = true,
      mode = 'cursor',
      max_lines = 3, -- 限制行数，避免遮挡过多
    },
  },
}

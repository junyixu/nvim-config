-- Treesitter configuration (Adapter for main branch)
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'

      ts.setup {
        -- vimtex 官方推荐的做法是在 setup 里定义 highlight
        highlight = {
          enable = true,
          -- 核心：禁用 tex 文件的 TS 高亮
          disable = { 'latex', 'tex' },
        },
      }

      -- 建议只在初次安装或更新时运行，也可以直接写在 config 里
      -- local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'julia', 'python', 'yaml' }
      -- ts.install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local bufnr = args.buf
          local ft = vim.bo[bufnr].filetype
          if ft == 'tex' or ft == 'latex' or ft == 'plaintex' then
            -- 只启动 parser 供 LuaSnip 用，高亮交给 vimtex
            pcall(vim.treesitter.get_parser, bufnr, 'latex')
          else
            pcall(vim.treesitter.start, bufnr)
          end
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

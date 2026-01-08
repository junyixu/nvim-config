-- Treesitter configuration (Adapter for main branch)
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'

      -- 1. 基础配置 (可选)
      ts.setup {
        -- 如果你需要自定义安装路径等，在这里设置
        -- install_dir = vim.fn.stdpath('data') .. '/site',
      }

      -- 2. 代替 ensure_installed: 手动安装你需要的语言
      -- 建议只在初次安装或更新时运行，也可以直接写在 config 里
      -- local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'julia', 'python', 'yaml' }
      -- ts.install(parsers)

      -- 3. 【关键】手动开启高亮、缩进和折叠
      -- main 分支不再自动开启这些，需要利用 Neovim 原生 API
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local bufnr = args.buf
          local ft = vim.bo[bufnr].filetype

          -- 开启高亮
          -- 只有当你安装了对应语言的 parser 时才会生效
          pcall(vim.treesitter.start, bufnr)
        end,
      })
    end,
  },

  { -- Treesitter Context 也需要同步到最新
    'nvim-treesitter/nvim-treesitter-context',
    opts = {
      enable = true,
      mode = 'cursor',
      max_lines = 3, -- 建议限制行数，避免遮挡过多
    },
  },
}

-- Quarto configuration

return {
  {
    'jpalardy/vim-slime',
    init = function()
      -- 必须在插件加载前设置
      vim.g.slime_target = 'neovim'
    end,
    config = function()
      -- 可选配置
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false -- 设为 true 可以用菜单选择终端
      vim.g.slime_input_pid = false

      -- 自定义键映射
      -- 发送 motion/textobject (例如: <Leader>sip 发送段落, <Leader>sgg 发送到文件开头)
      vim.keymap.set('n', '<Leader>s', '<Plug>SlimeMotionSend', { remap = true, desc = 'Slime: Send Motion' })
      -- 快速发送当前行
      vim.keymap.set('n', '<Leader>ss', '<Plug>SlimeLineSend', { remap = true, desc = 'Slime: Send Line' })
      -- 发送当前段落
      vim.keymap.set('n', '<Leader>sp', '<Plug>SlimeParagraphSend', { remap = true, desc = 'Slime: Send Paragraph' })
      -- 发送选中区域 (visual mode)
      vim.keymap.set('v', '<Leader>s', '<Plug>SlimeRegionSend', { remap = true, desc = 'Slime: Send Region' })
      -- 配置目标终端
      vim.keymap.set('n', '<Leader>sc', '<Plug>SlimeConfig', { remap = true, desc = 'Slime: Configure Target' })
    end,
  },
  {
    'quarto-dev/quarto-nvim',
    dependencies = {
      'jmbuhr/otter.nvim',
      'nvim-treesitter/nvim-treesitter',
      'jpalardy/vim-slime',
    },
    config = function()
      local quarto = require 'quarto'
      quarto.setup {
        debug = false,
        closePreviewOnExit = true,
        lspFeatures = {
          enabled = true,
          chunks = 'curly',
          languages = { 'python', 'julia', 'lua' },
          diagnostics = {
            enabled = true,
            triggers = { 'BufWritePost' },
          },
          completion = {
            enabled = true,
          },
        },
        codeRunner = {
          enabled = true,
          default_method = 'slime', -- "molten", "slime", "iron" or <function>
          ft_runners = {}, -- filetype to runner, ie. `{ python = "molten" }`.
          -- Takes precedence over `default_method`
          never_run = { 'yaml' }, -- filetypes which are never sent to a code runner
        },
      }
      vim.keymap.set('n', '<leader>qp', quarto.quartoPreview, { silent = true, noremap = true })
      local runner = require 'quarto.runner'
      vim.keymap.set('n', '<C-CR>', runner.run_cell, { desc = 'run cell', silent = true })
      vim.keymap.set('n', '<localleader>rc', runner.run_cell, { desc = 'run cell', silent = true })
      vim.keymap.set('n', '<localleader>ra', runner.run_above, { desc = 'run cell and above', silent = true })
      vim.keymap.set('n', '<localleader>rA', runner.run_all, { desc = 'run all cells', silent = true })
      vim.keymap.set('n', '<CR>', runner.run_line, { desc = 'run line', silent = true })
      vim.keymap.set('v', '<localleader>r', runner.run_range, { desc = 'run visual range', silent = true })
      vim.keymap.set('n', '<localleader>RA', function()
        runner.run_all(true)
      end, { desc = 'run all cells of all languages', silent = true })
    end,
  },
}

return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'codecompanion', 'quarto' },
    config = function()
      -- 创建 autogroup
      local markdown_group = vim.api.nvim_create_augroup('MarkdownKeymaps', { clear = true })

      -- 为 markdown 和 quarto 文件设置 keymap
      vim.api.nvim_create_autocmd('FileType', {
        group = markdown_group,
        pattern = { 'markdown', 'codecompanion', 'quarto' },
        callback = function()
          -- 这里添加你的 keymap
          vim.keymap.set('n', '<leader>tm', ':RenderMarkdown buf_toggle<CR>', { buffer = true, desc = 'Toggle markdown preview' })
        end,
      })
    end,
  },
  {
    'HakonHarnes/img-clip.nvim',
    event = 'VeryLazy',
    opts = {
      filetypes = {
        codecompanion = {
          prompt_for_file_name = false,
          template = '[Image]($FILE_PATH)',
          use_absolute_path = true,
        },
      },
    },
    keys = {
      { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from system clipboard' },
    },
  },
}

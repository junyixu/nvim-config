return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'codecompanion' },
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
      { '<leader>pp', '<cmd>PasteImage<cr>', desc = 'Paste image from system clipboard' },
    },
  },
}

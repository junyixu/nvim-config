return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {
      jump = {
        jumplist = true,
      },
      modes = {
        char = {
          enabled = true, -- 确保 char 模式开启 [cite: 50]
          -- 核心修改：按照文档  的方式进行按键替换
          -- 这告诉 flash：把原本分配给 "," 的功能，现在分配给 "\"
          keys = { 'f', 'F', 't', 'T', ';', [','] = '\\' },
          char_actions = function(motion)
            return {
              [';'] = 'next',
              [','] = 'prev', -- 定义按下 \ 时的动作为 "跳转到上一个"
              [motion:lower()] = 'next',
              [motion:upper()] = 'prev',
            }
          end,
        },
      },
    },
    keys = {
      -- 你的常规 flash 快捷键保持不变
      {
        's',
        mode = { 'n', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      {
        'S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
    },
  },
}

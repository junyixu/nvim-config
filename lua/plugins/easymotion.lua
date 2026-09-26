return {
{
    "rainzm/flash-zh.nvim",
    -- event = "VeryLazy",
    dependencies = "folke/flash.nvim",
    -- `-` 同时匹配 ASCII 连字符与破折号/连接号（— – ―）
    opts = {
        char_map = {
            comma = { ["-"] = "-—–―" },
        },
    },
    keys = {{
        "s",
        mode = {"n", "o"},
        function()
            require("flash-zh").jump({
                chinese_only = false
            })
        end,
        desc = "Flash between Chinese"
    }}
},
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
          -- f/F/t/T 按下 `-` 时同时匹配破折号：char 模式的 search.mode 由
          -- flash.plugins.char 在 new() 里硬写，只能从 config 钩子里再包一层
          config = function(opts)
            -- flash 自带的两行默认逻辑，覆盖 config 后需原样保留
            opts.autohide = opts.autohide or (vim.fn.mode(true):find 'no' and vim.v.operator == 'y')
            opts.jump_labels = opts.jump_labels and vim.v.count == 0 and vim.fn.reg_executing() == '' and vim.fn.reg_recording() == ''

            local mode = opts.search.mode
            if type(mode) ~= 'function' then
              return -- 非 char 状态时 mode 是 "exact"
            end
            local motion = require('flash.plugins.char').motion
            local dash = '[-—–―]'
            opts.search.mode = function(c)
              if c ~= '-' then
                return mode(c)
              end
              local pattern = motion == 't' and ('\\m.\\ze' .. dash) or motion == 'T' and (dash .. '\\zs\\m.') or ('\\m' .. dash)
              if not opts.multi_line then
                pattern = ('\\%%%dl'):format(vim.api.nvim_win_get_cursor(0)[1]) .. pattern
              end
              return pattern
            end
          end,
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

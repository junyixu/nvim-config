return {
  'monaqa/dial.nvim',
  config = function()
    local augend = require 'dial.augend'

    -- 配置布尔值和其他常见切换项
    require('dial.config').augends:register_group {
      -- default group (使用默认 + 自定义)
      default = {
        -- 内置的数字增量/减量
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.integer.alias.binary,
        -- 内置的日期增量
        augend.date.alias['%Y-%m-%d'],
        augend.date.alias['%Y/%m/%d'],
        augend.date.alias['%m/%d'],
        augend.date.alias['%H:%M'],
        -- 内置的布尔值切换
        augend.constant.alias.bool, -- true/false
        augend.constant.alias.Bool, -- True/False
        -- 自定义布尔值切换
        augend.constant.new {
          elements = { 'yes', 'no' },
          word = true,
          cyclic = true,
        },
        augend.constant.new {
          elements = { 'on', 'off' },
          word = true,
          cyclic = true,
        },
        augend.constant.new {
          elements = { 'enable', 'disable' },
          word = true,
          cyclic = true,
        },
        -- 字母切换
        augend.constant.alias.alpha,
        augend.constant.alias.Alpha,
        -- 语义版本
        augend.semver.alias.semver,
      },
    }

    -- 设置快捷键，使用 <C-a> 和 <C-x>
    vim.keymap.set('n', '<C-a>', function()
      require('dial.map').manipulate('increment', 'normal')
    end, { noremap = true, desc = 'Increment (dial.nvim)' })

    vim.keymap.set('n', '<C-x>', function()
      require('dial.map').manipulate('decrement', 'normal')
    end, { noremap = true, desc = 'Decrement (dial.nvim)' })

    vim.keymap.set('n', 'g<C-a>', function()
      require('dial.map').manipulate('increment', 'gnormal')
    end, { noremap = true, desc = 'G- Increment (dial.nvim)' })

    vim.keymap.set('n', 'g<C-x>', function()
      require('dial.map').manipulate('decrement', 'gnormal')
    end, { noremap = true, desc = 'G- Decrement (dial.nvim)' })

    vim.keymap.set('v', '<C-a>', function()
      require('dial.map').manipulate('increment', 'visual')
    end, { noremap = true, desc = 'Increment visual (dial.nvim)' })

    vim.keymap.set('v', '<C-x>', function()
      require('dial.map').manipulate('decrement', 'visual')
    end, { noremap = true, desc = 'Decrement visual (dial.nvim)' })

    vim.keymap.set('v', 'g<C-a>', function()
      require('dial.map').manipulate('increment', 'gvisual')
    end, { noremap = true, desc = 'G-Increment visual (dial.nvim)' })

    vim.keymap.set('v', 'g<C-x>', function()
      require('dial.map').manipulate('decrement', 'gvisual')
    end, { noremap = true, desc = 'G-Decrement visual (dial.nvim)' })
  end,
}


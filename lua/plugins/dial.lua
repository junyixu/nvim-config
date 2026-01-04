return {
  'monaqa/dial.nvim',
  keys = {
    {
      '<C-a>',
      function()
        return require('dial.map').inc_normal()
      end,
      expr = true,
      desc = 'Increment',
    },
    {
      '<C-x>',
      function()
        return require('dial.map').dec_normal()
      end,
      expr = true,
      desc = 'Decrement',
    },
    {
      'g<C-a>',
      function()
        return require('dial.map').inc_gnormal()
      end,
      expr = true,
      desc = 'G-Increment',
    },
    {
      'g<C-x>',
      function()
        return require('dial.map').dec_gnormal()
      end,
      expr = true,
      desc = 'G-Decrement',
    },
    {
      '<C-a>',
      function()
        return require('dial.map').inc_visual()
      end,
      expr = true,
      mode = 'v',
      desc = 'Increment',
    },
    {
      '<C-x>',
      function()
        return require('dial.map').dec_visual()
      end,
      expr = true,
      mode = 'v',
      desc = 'Decrement',
    },
    {
      'g<C-a>',
      function()
        return require('dial.map').inc_gvisual()
      end,
      expr = true,
      mode = 'v',
      desc = 'G-Increment',
    },
    {
      'g<C-x>',
      function()
        return require('dial.map').dec_gvisual()
      end,
      expr = true,
      mode = 'v',
      desc = 'G-Decrement',
    },
  },
  config = function()
    local augend = require 'dial.augend'

    require('dial.config').augends:register_group {
      default = {
        augend.integer.alias.decimal,
        augend.integer.alias.hex,
        augend.integer.alias.binary,
        augend.date.alias['%Y-%m-%d'],
        augend.date.alias['%Y/%m/%d'],
        augend.date.alias['%m/%d'],
        augend.date.alias['%H:%M'],
        augend.constant.alias.bool,
        augend.constant.alias.Bool,
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
        augend.constant.alias.alpha,
        augend.constant.alias.Alpha,
        augend.semver.alias.semver,
      },
    }
  end,
}

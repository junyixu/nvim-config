return {
  {
    'olimorris/codecompanion.nvim',
    version = '^18.0.0',
    opts = {
      adapters = {
        http = {
          claudehub = function()
            return require('codecompanion.adapters').extend('openai_compatible', {
              env = {
                url = 'https://api.qinzhiai.com',
                api_key = os.getenv 'QINZHI_API_KEY',
              },
              schema = {
                model = {
                  default = 'gpt-5.2',
                },
              },
            })
          end,
          deepseek = function()
            return require('codecompanion.adapters').extend('deepseek', {})
          end,
          glm = function()
            return require('codecompanion.adapters').extend('openai_compatible', {
              env = {
                url = 'https://open.bigmodel.cn/api/paas',
                api_key = os.getenv 'ZHIPU_API_KEY',
                chat_url = '/v4/chat/completions',
              },
              schema = {
                model = {
                  default = 'glm-4-flash',
                },
              },
            })
          end,
        },
        acp = {
          codex = function()
            return require('codecompanion.adapters').extend('codex', {
              defaults = {
                auth_method = 'openai-api-key',
              },
              commands = {
                default = {
                  'codex-acp',
                  '-c',
                  'api_url="https://api.qinzhiai.com/v1"',
                  '-c',
                  'model="gpt-5.2"',
                },
              },
              env = {
                OPENAI_API_KEY = os.getenv 'QINZHI_API_KEY',
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          -- adapter = 'glm',
          -- adapter = 'codex',
          adapter = 'deepseek',
          keymaps = {
            yolo_mode = {
              modes = { n = "<leader>ty" },
              callback = "keymaps.yolo_mode",
              description = "YOLO mode toggle",
            },
          },
        },
      },
      display = {
        chat = {
          auto_scroll = false,
        },
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = function(_, opts)
      -- 加载插件并应用配置
      require('codecompanion').setup(opts)
      vim.keymap.set('n', '<leader>tc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = '[T]oggle CodeCompanion [C]hat' })
      vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true, desc = 'CodeCompanion Chat [A]dd selection' })
      vim.keymap.set('v', '<leader>ca', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true, desc = '[C]odeCompanion [A]ctions' })
      -- 添加命令缩写
      vim.cmd [[
        cabbrev cc CodeCompanion
      ]]
    end,
  },
}

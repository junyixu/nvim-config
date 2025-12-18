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
            options = {
              modes = { n = 'g?' },
              callback = 'keymaps.options',
              description = 'Options',
              hide = true,
            },
            fold_code = {
              modes = { n = 'gzc' },
              index = 15,
              callback = 'keymaps.fold_code',
              description = 'Fold code',
            },
            goto_file_under_cursor = {
              modes = { n = 'gf' },
              index = 20,
              callback = 'keymaps.goto_file_under_cursor',
              description = 'Open file under cursor',
            },
            yolo_mode = {
              modes = { n = '<leader>ty' },
              callback = 'keymaps.yolo_mode',
              description = 'YOLO mode toggle',
            },
          },
        },
      },
      display = {
        chat = {
          auto_scroll = false,
        },
      },
      rules = {
        -- 移除默认规则中的 CLAUDE.md
        myrule = {
          files = {
            '.clinerules',
            '.cursorrules',
            '.goosehints',
            '.rules',
            '.windsurfrules',
            '.github/copilot-instructions.md',
            'AGENT.md',
            'AGENTS.md',
            -- 注释掉 CLAUDE.md 相关文件
            -- { path = "CLAUDE.md", parser = "claude" },
            -- { path = "CLAUDE.local.md", parser = "claude" },
            -- { path = "~/.claude/CLAUDE.md", parser = "claude" },
          },
        },
        opts = {
          chat = {
            autoload = 'default',
          },
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

      local progress = require 'fidget.progress'
      local handles = {}
      local group = vim.api.nvim_create_augroup('CodeCompanionFidget', {})

      vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionRequestStarted',
        group = group,
        callback = function(e)
          handles[e.data.id] = progress.handle.create {
            title = 'CodeCompanion',
            message = 'Thinking...',
            lsp_client = { name = e.data.adapter.formatted_name },
          }
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'CodeCompanionRequestFinished',
        group = group,
        callback = function(e)
          local h = handles[e.data.id]
          if h then
            h.message = e.data.status == 'success' and 'Done' or 'Failed'
            h:finish()
            handles[e.data.id] = nil
          end
        end,
      })
    end,
  },
}

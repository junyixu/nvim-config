return {
  {
    'olimorris/codecompanion.nvim',
    version = '^18.0.0',
    lazy = true,
    cmd = { 'CodeCompanionChat', 'CodeCompanionCmd', 'CodeCompanionActions', 'CodeCompanion' },
    opts = {
      adapters = {
        http = {
          qin = function()
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
          gemini = function()
            return require('codecompanion.adapters').extend('gemini', {
              env = { api_key = os.getenv 'GEMINI_API_KEY', },
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
                  'api_url="https://qinzhiai.com/v1"',
                  '-c',
                  'model="gpt-5.2"',
                },
              },
              env = {
                OPENAI_API_KEY = os.getenv 'QINZHI_API_KEY',
              },
            })
          end,
          claude_code = function()
            return require('codecompanion.adapters').extend('claude_code', {
              env = {
                ANTHROPIC_API_KEY = os.getenv 'DEEPSEEK_API_KEY',
                ANTHROPIC_AUTH_TOKEN = os.getenv 'DEEPSEEK_API_KEY',
              },
            })
          end,
        },
      },
      interactions = {
        inline = {
          adapter = 'copilot',
        },
        chat = {
          -- adapter = 'glm',
          -- adapter = 'codex',
          adapter = 'deepseek',
          -- adapter = 'claude_code',
          roles = {
            user = 'Me',
          },
          keymaps = {
            stop = {
              modes = { n = '<C-c>' },
              index = 4,
              callback = 'keymaps.stop',
              description = 'Stop request',
            },
            send = {
              modes = {
                n = { '<C-CR>', '<C-s>' },
                i = '<C-s>',
              },
              index = 2,
              callback = 'keymaps.send',
              description = 'Send message',
            },
            next_chat = {
              modes = { n = 'g]' },
              index = 11,
              callback = 'keymaps.next_chat',
              description = 'Next chat',
            },
            previous_chat = {
              modes = { n = 'g[' },
              index = 12,
              callback = 'keymaps.previous_chat',
              description = 'Previous chat',
            },
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
          opts = {
            register = '*', -- The register to use for yanking code
          },
        },
      },
      display = {
        chat = {
          auto_scroll = false,
          intro_message = 'Welcome to CodeCompanion ✨! Press g? for options',
          window = {
            width = 0.35, ---@type number|"auto" using "auto" will allow full_height buffers to act like normal buffers
          },
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

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local function tailscale_diff()
  pickers
    .new({}, {
      prompt_title = 'Tailscale Nodes (Select for Diff)',
      -- 运行 tailscale status 并处理输出
      finder = finders.new_oneshot_job({ 'tailscale', 'status' }, {
        entry_maker = function(entry)
          -- 使用正则表达式拆分列 (IP, Hostname, User, OS, Status)
          local parts = {}
          for word in string.gmatch(entry, '%S+') do
            table.insert(parts, word)
          end

          local ip = parts[1]
          local hostname = parts[2]

          if not ip then
            return nil
          end

          return {
            value = ip,
            display = string.format('%-15s │ %s', ip, hostname),
            ordinal = ip .. ' ' .. hostname, -- 允许搜 IP 或主机名
          }
        end,
      }),
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          -- 这里调用你之前的自定义命令
          -- 也可以直接执行 vim.cmd("DiffRemote " .. selection.value)
          if selection then
            print('Connecting to: ' .. selection.value)
            vim.cmd('DiffRemote ' .. selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- 注册命令
vim.api.nvim_create_user_command('TelescopeTailscale', tailscale_diff, {})

-- 建议绑定快捷键
vim.keymap.set('n', '<leader>ts', tailscale_diff, { desc = 'Tailscale remote diff' })

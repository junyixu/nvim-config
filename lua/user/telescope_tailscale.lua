local function tailscale_diff()
  Snacks.picker.pick("tailscale", {
    prompt = "Tailscale Nodes (Select for Diff)",
    finder = function(opts, ctx)
      return require("snacks.picker.source.proc").proc(
        ctx:opts({
          cmd = "tailscale",
          args = { "status" },
          ---@param item snacks.picker.finder.Item
          transform = function(item)
            -- 使用正则表达式拆分列 (IP, Hostname, User, OS, Status)
            local parts = {}
            for word in string.gmatch(item.text, '%S+') do
              table.insert(parts, word)
            end

            local ip = parts[1]
            local hostname = parts[2]

            if not ip then
              return false
            end

            item.ip = ip
            item.hostname = hostname or ""
            item.text = string.format('%-15s │ %s', ip, hostname or "")
            return item
          end,
        }),
        ctx
      )
    end,
    format = function(item, picker)
      return { { item.text, "SnacksPickerList" } }
    end,
    confirm = function(picker, item)
      if item then
        vim.notify('Connecting to: ' .. item.ip, vim.log.levels.INFO)
        vim.cmd('DiffRemote ' .. item.ip)
      end
    end,
  })
end

-- 注册命令
vim.api.nvim_create_user_command('SnacksTailscale', tailscale_diff, {})

-- 建议绑定快捷键
vim.keymap.set('n', '<leader>ts', tailscale_diff, { desc = 'Tailscale remote diff' })

local function tailscale_diff()
  -- 在打开 picker 之前先保存当前文件的路径
  local local_file = vim.fn.expand('%:p')
  local local_buf = vim.api.nvim_get_current_buf()

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
      if item and local_file and local_file ~= '' then
        -- 构造 oil-ssh URL
        local user = 'junyi'
        local remote_url = string.format('oil-ssh://%s@%s/%s', user, item.ip, local_file)

        -- 调试信息
        print('[DEBUG] local_file: ' .. local_file)
        print('[DEBUG] local_buf: ' .. tostring(local_buf))
        print('[DEBUG] remote_url: ' .. remote_url)

        -- 先关闭 picker，然后切换回原 buffer，最后执行 diffsplit
        picker:close()
        vim.schedule(function()
          local buf_name = vim.api.nvim_buf_get_name(local_buf)
          print('[DEBUG] buf_name after schedule: ' .. buf_name)
          vim.api.nvim_set_current_buf(local_buf)
          vim.cmd('vertical diffsplit ' .. remote_url)
        end)
      else
        vim.notify('No file to diff', vim.log.levels.WARN)
      end
    end,
  })
end

-- 注册命令
vim.api.nvim_create_user_command('SnacksTailscale', tailscale_diff, {})

-- 建议绑定快捷键
vim.keymap.set('n', '<leader>ts', tailscale_diff, { desc = 'Tailscale remote diff' })

local M = {}

-- tailscale status 的每一行: IP, Hostname, User, OS, Status
local function tailscale_items()
  if vim.fn.executable 'tailscale' == 0 then
    return {}
  end
  local res = vim.system({ 'tailscale', 'status' }, { text = true }):wait(3000)
  if res.code ~= 0 or not res.stdout then
    return {}
  end

  local items = {}
  for _, line in ipairs(vim.split(res.stdout, '\n', { trimempty = true })) do
    local ip, hostname = line:match '^(%S+)%s+(%S+)'
    -- 跳过 "# Health check" 之类的非节点行
    if ip and (ip:match '^%d+%.%d+%.%d+%.%d+$' or ip:find ':') then
      table.insert(items, {
        text = string.format('%-10s │ %-15s │ %s', 'tailscale', hostname, ip),
        target = 'junyi@' .. ip,
      })
    end
  end
  return items
end

-- 解析 ~/.ssh/config 中的 Host 别名（跳过通配符），用别名连接以复用 User/Port/IdentityFile
local function ssh_config_items()
  local path = vim.fn.expand '~/.ssh/config'
  if vim.fn.filereadable(path) == 0 then
    return {}
  end

  local items, current = {}, {}
  for _, line in ipairs(vim.fn.readfile(path)) do
    local key, value = line:match '^%s*(%S+)%s*=?%s*(.-)%s*$'
    key = key and key:lower()
    if key == 'host' or key == 'match' then
      current = {}
      if key == 'host' then
        for alias in value:gmatch '%S+' do
          if not alias:find '[*?!]' then
            local item = { alias = alias, hostname = alias }
            table.insert(items, item)
            table.insert(current, item)
          end
        end
      end
    elseif key == 'hostname' then
      for _, item in ipairs(current) do
        item.hostname = value
      end
    end
  end

  return vim.tbl_map(function(item)
    return {
      text = string.format('%-10s │ %-15s │ %s', 'ssh', item.alias, item.hostname),
      target = item.alias,
    }
  end, items)
end

function M.diff()
  -- 在打开 picker 之前先保存当前文件的路径
  local local_file = vim.fn.expand '%:p'
  local local_buf = vim.api.nvim_get_current_buf()

  Snacks.picker.pick('remote_hosts', {
    prompt = 'Remote Hosts (Select for Diff)',
    layout = {
      preview = false,
    },
    finder = function()
      return vim.list_extend(tailscale_items(), ssh_config_items())
    end,
    format = function(item, picker)
      return { { item.text, 'SnacksPickerList' } }
    end,
    confirm = function(picker, item)
      if item and local_file and local_file ~= '' then
        -- 构造 oil-ssh URL（假设远程路径与本地路径一致）
        local remote_url = string.format('oil-ssh://%s/%s', item.target, local_file)

        -- 先关闭 picker，然后切换回原 buffer，最后执行 diffsplit
        picker:close()
        vim.schedule(function()
          vim.api.nvim_set_current_buf(local_buf)
          vim.cmd('vertical diffsplit ' .. remote_url)
        end)
      else
        vim.notify('No file to diff', vim.log.levels.WARN)
      end
    end,
  })
end

return M

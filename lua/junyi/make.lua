M = {}
function M.async_make()
  -- 1. 获取当前环境的配置
  local makeprg = vim.bo.makeprg
  local efm = vim.bo.errorformat

  if not makeprg or makeprg == '' then
    vim.notify('No makeprg set!', vim.log.levels.ERROR)
    return
  end

  -- 处理占位符，例如将 % 扩展为当前文件名
  local cmd = vim.fn.expandcmd(makeprg)

  -- vim.system 推荐接收 table 形式的命令，但 makeprg 通常是长字符串
  -- 这里简单用 sh -c 执行，或者用 vim.split 拆分
  local shell_cmd = { 'sh', '-c', cmd }

  vim.notify('Build started: ' .. cmd, vim.log.levels.INFO)

  -- 2. 使用 vim.system 异步执行
  vim.system(shell_cmd, {
    text = true, -- 将输出作为文本处理，而不是 raw bytes
    stderr = true, -- 同时捕获 stderr
  }, function(obj)
    -- 注意：这个回调函数是在 libuv 的事件循环中执行的
    -- 操作 Neovim 界面（如 Quickfix）通常需要 schedule 回主线程
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify('Build finished successfully!', vim.log.levels.INFO)
      else
        vim.notify('Build failed with code ' .. obj.code, vim.log.levels.WARN)
      end

      -- 3. 将结果填入 Quickfix
      -- 我们合并 stdout 和 stderr 进行解析
      local lines = vim.split(obj.stdout .. obj.stderr, '\n')

      -- 利用 setqflist 的 'efm' 参数，Neovim 会根据你当前的 errorformat 解析这些行
      vim.fn.setqflist({}, 'r', {
        title = 'AsyncMake: ' .. cmd,
        lines = lines,
        efm = efm,
      })

      -- 如果有错误，自动打开 Quickfix 窗口
      if obj.code ~= 0 then
        vim.cmd 'copen'
      end
    end)
  end)
end

return M

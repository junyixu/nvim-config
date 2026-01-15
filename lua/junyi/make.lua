M = {}
local function async_make_core(opts)
  opts = opts or {}

  local makeprg = vim.bo.makeprg
  local efm = vim.bo.errorformat
  local use_loclist = opts.use_loclist or false

  if not makeprg or makeprg == '' then
    vim.notify('No makeprg set!', vim.log.levels.ERROR)
    return
  end

  local cmd = vim.fn.expandcmd(makeprg)
  local shell_cmd = { 'sh', '-c', cmd }

  vim.notify('Build started: ' .. cmd, vim.log.levels.INFO)

  vim.system(shell_cmd, { text = true, stderr = true }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify('Build finished successfully!', vim.log.levels.INFO)
      else
        vim.notify('Build failed with code ' .. obj.code, vim.log.levels.WARN)
      end

      local output = (obj.stdout or '') .. (obj.stderr or '')
      local lines = vim.split(output, '\n')

      if use_loclist then
        vim.fn.setloclist(0, {}, 'r', {
          title = 'AsyncLMake: ' .. cmd,
          lines = lines,
          efm = efm,
        })
        if obj.code ~= 0 then
          vim.cmd 'lopen'
        end
      else
        vim.fn.setqflist({}, 'r', {
          title = 'AsyncMake: ' .. cmd,
          lines = lines,
          efm = efm,
        })
        if obj.code ~= 0 then
          vim.cmd 'copen'
        end
      end
    end)
  end)
end

function M.async_make()
  async_make_core { use_loclist = false }
end

function M.async_lmake()
  async_make_core { use_loclist = true }
end

return M

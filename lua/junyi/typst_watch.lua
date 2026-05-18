local M = {}
local typst_handle = nil
local zathura_handle = nil
local current_pdf = nil

local log_buf = nil

local function ensure_log_buf()
  if log_buf and vim.api.nvim_buf_is_valid(log_buf) then
    return log_buf
  end
  log_buf = vim.api.nvim_create_buf(false, true) -- listed=false, scratch=true
  vim.api.nvim_buf_set_name(log_buf, 'typst://watch.log')
  vim.bo[log_buf].filetype = 'typst-log'
  vim.bo[log_buf].bufhidden = 'hide'
  return log_buf
end

local function append_log(chunk)
  local buf = ensure_log_buf()
  -- strip ANSI color escapes
  chunk = chunk:gsub('\27%[[%d;]*m', '')
  local lines = vim.split(chunk, '\n', { plain = true, trimempty = true })
  if #lines == 0 then
    return
  end
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  -- 让已打开 log 的窗口自动滚到底
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
    end
  end
end

function M.open_log()
  vim.cmd 'botright 12split'
  vim.api.nvim_win_set_buf(0, ensure_log_buf())
end

local function notify(msg, level)
  vim.schedule(function()
    vim.notify(msg, level or vim.log.levels.INFO, { title = 'typst' })
  end)
end

local function wait_for_pdf(path, on_ready)
  local timer = assert(vim.uv.new_timer())
  local attempts = 0
  timer:start(0, 200, function()
    attempts = attempts + 1
    if vim.uv.fs_stat(path) then
      timer:stop()
      timer:close()
      vim.schedule(on_ready)
    elseif attempts > 50 then -- 10s 超时
      timer:stop()
      timer:close()
      notify('PDF did not appear within 10s', vim.log.levels.ERROR)
    end
  end)
end

local function spawn_zathura(pdf)
  zathura_handle = vim.system(
    { 'zathura', pdf },
    { detach = false }, -- 跟 nvim 生命周期绑定
    function(out)
      vim.schedule(function()
        if out.code ~= 0 and out.signal ~= 15 then
          notify(('zathura exited (code=%d)'):format(out.code), vim.log.levels.WARN)
        end
      end)
      zathura_handle = nil
    end
  )
end

function M.start()
  if typst_handle then
    notify('typst watch already running', vim.log.levels.WARN)
    return
  end

  local main = vim.fn.expand '%:p'
  local pdf = main:gsub('%.typ$', '.pdf')
  current_pdf = pdf

  typst_handle = vim.system({ 'typst', 'watch', main }, {
    text = true,
    stderr = function(_, data)
      if not data or data == '' then
        return
      end
      vim.schedule(function()
        append_log(data)
        -- 只在真正出错时弹一行,避免 hit-enter
        if data:match 'error:' then
          vim.notify('typst: compile error (:TypstLog)', vim.log.levels.ERROR, { title = 'typst' })
        end
      end)
    end,
  }, function(out)
    vim.schedule(function()
      notify(('typst watch exited (code=%d)'):format(out.code), vim.log.levels.WARN)
    end)
    typst_handle = nil
  end)

  -- zathura 默认带 inotify auto-reload,启动后 typst 每次重编译它会自动刷新
  wait_for_pdf(pdf, function()
    if not zathura_handle then
      spawn_zathura(pdf)
    end
  end)
end

function M.stop()
  if typst_handle then
    typst_handle:kill(15)
    typst_handle = nil
  end
  if zathura_handle then
    zathura_handle:kill(15)
    zathura_handle = nil
  end
end

function M.toggle()
  if typst_handle then
    M.stop()
  else
    M.start()
  end
end

vim.api.nvim_create_autocmd('VimLeavePre', { callback = M.stop })

return M

--- `w!!`: 用 sudo 把当前文件写回磁盘。
---
--- Neovim 的 `:!` 拿不到 tty, 直接 `:w !sudo tee %` 会报
--- "sudo: a terminal is required to read the password"。
--- 所以这里先把 buffer 导出到临时文件, 再在浮动终端 (有 pty) 里跑 `sudo tee`,
--- 这样 sudo 的密码提示才能正常工作。
local M = {}

local function notify(msg, level)
  vim.notify('w!!: ' .. msg, level or vim.log.levels.INFO)
end

--- 把 buffer 原样导出到临时文件 (走正常的 :write, 保留 fileformat / eol / encoding)
--- @param bufnr integer
--- @return string tmp 临时文件路径
local function dump_to_temp(bufnr)
  local tmp = vim.fn.tempname()
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd('silent keepalt write! ' .. vim.fn.fnameescape(tmp))
  end)
  return tmp
end

--- 写完重新从磁盘读入: 清掉 modified 标记, 也避免 mtime 变化导致下次 :w 报 W12
--- @param bufnr integer
--- @param win integer
local function reload_from_disk(bufnr, win)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then
    return
  end
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_set_current_win(win)
  local view = vim.fn.winsaveview()
  vim.cmd 'silent! keepalt edit!'
  vim.fn.winrestview(view)
end

--- 在浮动终端里跑 cmd, 退出后回调 exit code (终端带 pty, sudo 才能读密码)
--- @param cmd string 交给 sh -c 的命令
--- @param on_done fun(code: integer)
local function run_in_float(cmd, on_done)
  local width = math.min(72, math.max(24, vim.o.columns - 6))
  local height = 3
  local term_buf = vim.api.nvim_create_buf(false, true)
  local term_win = vim.api.nvim_open_win(term_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2)),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = 'minimal',
    border = 'rounded',
    title = ' w!! (sudo password) ',
    title_pos = 'center',
  })

  vim.fn.jobstart({ 'sh', '-c', cmd }, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(term_win) then
          vim.api.nvim_win_close(term_win, true)
        end
        if vim.api.nvim_buf_is_valid(term_buf) then
          vim.api.nvim_buf_delete(term_buf, { force = true })
        end
        on_done(code)
      end)
    end,
  })
  -- 终端打开后是 normal 模式, 要进 insert 才能输密码
  vim.cmd 'startinsert'
end

--- `:SudoWrite` / `:w!!`
function M.write()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local file = vim.api.nvim_buf_get_name(bufnr)

  if file == '' then
    return notify('buffer has no file name', vim.log.levels.ERROR)
  end
  if vim.bo[bufnr].buftype ~= '' then
    return notify('not a normal file buffer', vim.log.levels.ERROR)
  end

  local tmp = dump_to_temp(bufnr)
  local cmd = ('sudo tee %s < %s > /dev/null'):format(vim.fn.shellescape(file), vim.fn.shellescape(tmp))

  local function finish(code)
    vim.fn.delete(tmp)
    if code ~= 0 then
      return notify('sudo write failed (exit ' .. code .. ')', vim.log.levels.ERROR)
    end
    reload_from_disk(bufnr, win)
    notify('saved ' .. vim.fn.fnamemodify(file, ':~:.'))
  end

  -- 免密 sudo / 凭据已缓存: 不需要 pty, 直接同步写入, 不弹窗
  vim.fn.system 'sudo -n true 2>/dev/null'
  if vim.v.shell_error == 0 then
    vim.fn.system(cmd .. ' 2>/dev/null')
    return finish(vim.v.shell_error)
  end

  run_in_float(cmd, finish)
end

return M

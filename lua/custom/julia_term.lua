local slime_term = require 'custom.slime_term'
slime_term.ensure()

local M = {}

local job_id = 0
local term_bufnr = nil
local term_width = 50

local function configure_slime_job(bufnr)
  if job_id <= 0 then
    return
  end

  local ok_existing, existing = pcall(vim.api.nvim_buf_get_var, bufnr, 'slime_config')
  local config = {}
  if ok_existing and type(existing) == 'table' then
    config = existing
  end

  config.jobid = job_id

  local ok_pid, pid = pcall(vim.fn.jobpid, job_id)
  if ok_pid and type(pid) == 'number' and pid > 0 then
    config.pid = pid
  end

  vim.api.nvim_buf_set_var(bufnr, 'slime_config', config)
end

local function ensure_term_running()
  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    return true
  end

  job_id = 0
  term_bufnr = nil
  vim.notify('Julia terminal is not running yet', vim.log.levels.INFO, { title = 'julia_term' })
  return false
end

local function show_term_window()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_width(win, term_width)
    slime_term.scroll_buf(term_bufnr)
    return
  end

  vim.cmd 'topleft vsplit'
  vim.cmd.wincmd 'H'
  vim.api.nvim_win_set_buf(0, term_bufnr)
  vim.api.nvim_win_set_width(0, term_width)
  slime_term.scroll_buf(term_bufnr)
  vim.cmd.wincmd 'p'
end

local function hide_term_window()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win == -1 then
    return
  end

  if #vim.api.nvim_list_wins() == 1 then
    vim.notify('Cannot hide the Julia terminal when it is the only window', vim.log.levels.WARN, { title = 'julia_term' })
    return
  end

  vim.api.nvim_win_close(win, true)
end

function M.open()
  local source_buf = vim.api.nvim_get_current_buf()
  vim.cmd 'topleft vsplit'
  vim.cmd.wincmd 'H'
  vim.cmd.term()
  vim.opt_local.wrap = false
  term_bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_width(0, term_width)
  slime_term.scroll_buf(term_bufnr)
  job_id = vim.bo.channel

  -- 1. 定义基础命令
  local cmd = 'julia --banner=no --project=.'

  -- 2. 查找当前目录下所有以 Sysimage.so 结尾的文件
  -- 第三个参数 true 表示返回一个 table (list)，方便判断
  local sysimages = vim.fn.glob('*Sysimage.so', false, true)

  -- 3. 如果找到了至少一个文件，取第一个并追加 -J 参数
  if not vim.tbl_isempty(sysimages) then
    local image = sysimages[1]
    cmd = cmd .. ' -J' .. image
    vim.notify('🚀 Auto-detected Sysimage: ' .. image, vim.log.levels.INFO)
  end

  -- 4. 补上换行符
  cmd = cmd .. '\r\n'

  vim.fn.chansend(job_id, { cmd })
  configure_slime_job(source_buf)
  vim.cmd.wincmd 'p'
end

function M.toggle()
  if not ensure_term_running() then
    return
  end

  local win = vim.fn.bufwinid(term_bufnr)
  if win == -1 then
    show_term_window()
  else
    hide_term_window()
  end
end

-- Toggle slime target between kitty and neovim
function M.toggle_slime_target()
  -- Determine current target: buffer variable takes precedence over global
  local current_target = vim.b.slime_target or vim.g.slime_target or 'neovim'

  -- Toggle between kitty and neovim
  local new_target = (current_target == 'neovim') and 'kitty' or 'neovim'

  -- Set buffer variable (takes precedence over global)
  vim.b.slime_target = new_target

  -- Notify user
  vim.notify(string.format('Slime target switched to: %s', new_target), vim.log.levels.INFO)
end
return M

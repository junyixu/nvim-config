--- Generic terminal runner backed by vim-slime.
--- Usage:
---   local M = require('custom.term_runner').new({
---     name = 'Julia',          -- used in notifications
---     cmd  = 'julia --banner=no', -- string or function() -> string
---   })

local M = {}

--- `new()` 是工厂函数，每次调用都产生一个新的闭包，闭包内的局部变量
--- （`job_id`、`term_bufnr` 等）是各自独立的。`julia_term` 和 `python_term`
--- 是两次不同的 `new()` 调用，互不干扰，即使在不同 Tab 也一样。
--- @param opts { name: string, cmd: string|fun(): string, term_width?: integer }
function M.new(opts)
  local slime_term = require 'custom.slime_term'
  slime_term.ensure()

  local name = opts.name
  local title = name:lower() .. '_term'
  local term_width = opts.term_width or 50

  local job_id = 0
  local term_bufnr = nil
  local saved_width = nil

  local function configure_slime_job(bufnr)
    if job_id <= 0 then
      return
    end
    local ok_existing, existing = pcall(vim.api.nvim_buf_get_var, bufnr, 'slime_config')
    local config = (ok_existing and type(existing) == 'table') and existing or {}
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
    vim.notify(name .. ' terminal is not running yet', vim.log.levels.INFO, { title = title })
    return false
  end

  local function show_term_window()
    if not ensure_term_running() then
      return
    end
    local win = vim.fn.bufwinid(term_bufnr)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_width(win, saved_width or term_width)
      slime_term.scroll_buf(term_bufnr)
      return
    end
    vim.cmd 'topleft vsplit'
    vim.cmd.wincmd 'H'
    vim.api.nvim_win_set_buf(0, term_bufnr)
    vim.api.nvim_win_set_width(0, saved_width or term_width)
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
      vim.notify('Cannot hide the ' .. name .. ' terminal when it is the only window', vim.log.levels.WARN, { title = title })
      return
    end
    saved_width = vim.api.nvim_win_get_width(win)
    vim.api.nvim_win_close(win, true)
  end

  local runner = {}

  function runner.open()
    local source_buf = vim.api.nvim_get_current_buf()
    vim.cmd 'topleft vsplit'
    vim.cmd.wincmd 'H'
    local cmd = type(opts.cmd) == 'function' and opts.cmd() or opts.cmd
    vim.cmd('terminal ' .. cmd)
    vim.opt_local.wrap = false
    term_bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_set_width(0, term_width)
    slime_term.scroll_buf(term_bufnr)
    job_id = vim.bo.channel
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = term_bufnr,
      callback = function()
        vim.schedule(function()
          if vim.api.nvim_get_current_buf() == term_bufnr then
            vim.cmd.startinsert()
          end
        end)
      end,
    })
    configure_slime_job(source_buf)
    vim.cmd.wincmd 'p'
  end

  function runner.toggle()
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

  return runner
end

return M

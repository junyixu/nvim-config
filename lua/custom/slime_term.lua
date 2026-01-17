local M = {}

local override_installed = false

local function get_option(bufnr, option)
  local ok, value = pcall(vim.api.nvim_buf_get_option, bufnr, option)
  if ok then
    return value
  end
end

local function find_terminal_for_job(jobid)
  if not jobid then
    return nil
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local buftype = get_option(bufnr, 'buftype')
      if buftype == 'terminal' then
        local channel = vim.fn.getbufvar(bufnr, '&channel')
        if tonumber(channel) == jobid then
          return bufnr
        end
      end
    end
  end

  return nil
end

function M.scroll_buf(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  pcall(vim.api.nvim_win_set_cursor, win, { line_count, 0 })
end

function M.scroll_job(jobid)
  local job = tonumber(jobid)
  if not job then
    return
  end

  local bufnr = find_terminal_for_job(job)
  if bufnr then
    M.scroll_buf(bufnr)
  end
end

function M.after_send(jobid)
  if not jobid then
    return
  end

  vim.schedule(function()
    M.scroll_job(jobid)
  end)
end

function M.ensure()
  if override_installed then
    return
  end
  override_installed = true

  _G.SlimeTermAfterSend = function(jobid)
    require('custom.slime_term').after_send(jobid)
  end

  vim.cmd([[
    function SlimeOverrideSend(config, text) abort
      let l:target = slime#config#resolve('target')
      execute 'call slime#targets#' . l:target . '#send(a:config, a:text)'
      if has_key(a:config, 'jobid')
        call v:lua.SlimeTermAfterSend(a:config['jobid'])
      endif
    endfunction
  ]])
end

return M

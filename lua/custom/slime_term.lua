local M = {}

local override_installed = false

local function get_option(bufnr, option)
  local ok, value = pcall(vim.api.nvim_get_option_value, option, { buf = bufnr }) -- 使用新的 API，并通过 opts table 指定 bufnr
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

  --  SlimeOverrideSend 是 vim-slime “钦定”的扩展点
  vim.cmd [[
    function! SlimeOverrideSend(config, text) abort
      let l:enabled = get(b:, 'slime_collapse_blank_lines', get(g:, 'slime_collapse_blank_lines', 0))
      let l:text = a:text
      if l:enabled
        let l:has_trailing_eol = l:text =~# '\r\?\n\%$'
        let l:body = substitute(l:text, '\r\?\n\%$', '', '')
        let l:lines = split(l:body, '\r\?\n', 1)

        let l:out = []
        let l:blank_run = 0
        for l:line in l:lines
          if l:line =~# '^\s*$'
            let l:blank_run += 1
            if l:blank_run <= 1
              call add(l:out, '')
            endif
          else
            let l:blank_run = 0
            call add(l:out, l:line)
          endif
        endfor

        let l:text = join(l:out, "\n")
        if l:has_trailing_eol
          let l:text .= "\n"
        endif
      endif

      let l:target = slime#config#resolve('target')
      execute 'call slime#targets#' . l:target . '#send(a:config, l:text)'
      if has_key(a:config, 'jobid')
        call v:lua.SlimeTermAfterSend(a:config['jobid'])
      endif
    endfunction
  ]]
end

return M

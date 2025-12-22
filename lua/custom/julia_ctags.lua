local M = {}

local uv = vim.uv or vim.loop

M.config = {
  debounce_ms = 2300,
  tagfile = 'tags',
  excludes = {
    '.git',
    '.hg',
    '.svn',
    '.direnv',
    '.venv',
    'venv',
    'node_modules',
    'dist',
    'build',
    'target',
    '.julia',
    'deps',
  },
}

local timer
local pending_cwd

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'julia-ctags' })
end

local function build_args()
  local args = {
    'ctags',
    '-R',
    '--languages=julia',
    '--fields=+ln',
  }

  for _, ex in ipairs(M.config.excludes or {}) do
    table.insert(args, '--exclude=' .. ex)
  end

  vim.list_extend(args, { '-o', M.config.tagfile, '.' })
  return args
end

function M.run(cwd)
  cwd = cwd or vim.fn.getcwd()

  if vim.fn.executable 'ctags' ~= 1 then
    notify('`ctags` not found in PATH', vim.log.levels.WARN)
    return
  end

  vim.system(build_args(), { cwd = cwd }, function(res)
    if res.code ~= 0 then
      local stderr = (res.stderr or ''):gsub('%s+$', '')
      notify(('ctags failed (%d)%s'):format(res.code, stderr ~= '' and (': ' .. stderr) or ''), vim.log.levels.WARN)
    end
  end)
end

function M.schedule()
  pending_cwd = vim.fn.getcwd()

  if timer then
    timer:stop()
    timer:close()
  end

  timer = uv.new_timer()
  timer:start(
    M.config.debounce_ms,
    0,
    vim.schedule_wrap(function()
      timer = nil
      M.run(pending_cwd)
    end)
  )
end

function M.attach(bufnr)
  bufnr = bufnr or 0

  if vim.b[bufnr].julia_ctags_attached then
    return
  end
  vim.b[bufnr].julia_ctags_attached = true

  local group = vim.api.nvim_create_augroup('CustomJuliaCtags', { clear = false })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    buffer = bufnr,
    callback = function()
      require('custom.julia_ctags').schedule()
    end,
    desc = 'Run Julia ctags on save (debounced)',
  })
end

return M

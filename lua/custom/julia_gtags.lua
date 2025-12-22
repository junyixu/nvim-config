local M = {}

local uv = vim.uv or vim.loop

M.config = {
  debounce_ms = 2300,
  gtags_file = 'GTAGS',
}

local timer
local pending_cwd
local running = false

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'julia-gtags' })
end

local function joinpath(a, b)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(a, b)
  end
  return a .. '/' .. b
end

local function exists(path)
  return uv.fs_stat(path) ~= nil
end

local function run(cmd, cwd)
  if vim.fn.executable(cmd[1]) ~= 1 then
    notify(('`%s` not found in PATH'):format(cmd[1]), vim.log.levels.WARN)
    running = false
    return
  end

  vim.system(cmd, { cwd = cwd }, function(res)
    if res.code ~= 0 then
      local stderr = (res.stderr or ''):gsub('%s+$', '')
      notify(('%s failed (%d)%s'):format(cmd[1], res.code, stderr ~= '' and (': ' .. stderr) or ''), vim.log.levels.WARN)
    end
    running = false
  end)
end

function M.update(cwd)
  if running then
    return
  end

  cwd = cwd or vim.fn.getcwd()
  running = true

  if exists(joinpath(cwd, M.config.gtags_file)) then
    run({ 'global', '-u' }, cwd)
  else
    run({ 'gtags' }, cwd)
  end
end

function M.regen(cwd)
  if running then
    return
  end

  cwd = cwd or vim.fn.getcwd()
  running = true
  run({ 'gtags' }, cwd)
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
      M.update(pending_cwd)
    end)
  )
end

function M.attach(bufnr)
  bufnr = bufnr or 0

  if vim.b[bufnr].julia_gtags_attached then
    return
  end
  vim.b[bufnr].julia_gtags_attached = true

  if not vim.g.custom_julia_gtags_command_created then
    vim.g.custom_julia_gtags_command_created = true
    vim.api.nvim_create_user_command('JuliaGtagsRegen', function()
      require('custom.julia_gtags').regen(vim.fn.getcwd())
    end, { desc = 'Rebuild GTAGS in current directory' })
  end

  local group = vim.api.nvim_create_augroup('CustomJuliaGtags', { clear = false })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    buffer = bufnr,
    callback = function()
      require('custom.julia_gtags').schedule()
    end,
    desc = 'Update GTAGS on save (debounced)',
  })
end

return M

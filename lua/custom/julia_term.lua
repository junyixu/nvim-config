--- 决定是否显式传 --project：
--- - JULIA_PROJECT 非空时交给 Julia 自己处理，不再加参数；
--- - 当前目录有 Project.toml / JuliaProject.toml 时用 `.`（即该目录）；
--- - 否则用 `@sandbox`，避免落到一个不存在的空环境。
local function project_flag()
  local env_project = vim.env.JULIA_PROJECT
  if env_project and env_project ~= '' then
    return ''
  end
  local has_project = false
  for _, name in ipairs { 'Project.toml', 'JuliaProject.toml' } do
    if vim.fn.glob(vim.fs.joinpath(vim.uv.cwd(), name), false, true)[1] then
      has_project = true
      break
    end
  end
  return ' --project=' .. (has_project and '.' or '@sandbox')
end

local M = require('custom.term_runner').new({
  name = 'Julia',
  term_width = 80,
  cmd = function()
    local cmd = 'julia --banner=no' .. project_flag()
    local sysimages = vim.fn.glob('*Sysimage.so', false, true)
    if not vim.tbl_isempty(sysimages) then
      local image = sysimages[1]
      cmd = cmd .. ' -J' .. image
      vim.notify('🚀 Auto-detected Sysimage: ' .. image, vim.log.levels.INFO)
    end
    return cmd
  end,
})

function M.toggle_slime_target()
  local current_target = vim.b.slime_target or vim.g.slime_target or 'neovim'
  local new_target = (current_target == 'neovim') and 'kitty' or 'neovim'
  vim.b.slime_target = new_target
  vim.notify(string.format('Slime target switched to: %s', new_target), vim.log.levels.INFO)
end

return M

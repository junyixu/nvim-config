local M = require('custom.term_runner').new({
  name = 'Julia',
  term_width = 80,
  cmd = function()
    local cmd = 'julia --banner=no --project=.'
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

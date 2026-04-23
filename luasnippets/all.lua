---@diagnostic disable: undefined-global
---@global s
---@global f

return {
  s(
    'curtime',
    f(function()
      return os.date '%D - %H:%M'
    end)
  ),
}

require 'config'
require 'lazy_nvim'
-- 使用 pcall (protected call) 防止因为没装 tailscale 命令或插件而卡死启动
local status_ok, ts_custom = pcall(require, 'user.telescope_tailscale')
if not status_ok then
  vim.notify('未能加载 Tailscale 脚本', vim.log.levels.WARN)
end

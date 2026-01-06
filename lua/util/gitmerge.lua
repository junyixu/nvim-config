local M = {}
function M.smart_diffget(side)
  -- 1. 备份当前的 diffopt 字符串
  local old_diffopt = vim.api.nvim_get_option_value('diffopt', {})

  -- 2. 构造一个不含 linematch 的新 diffopt
  -- 使用 gsub 移除 linematch:数字 以及可能存在的逗号
  local new_diffopt = old_diffopt:gsub(',?linematch:%d+', ''):gsub('^,', '')

  -- 3. 临时设置新选项
  vim.api.nvim_set_option_value('diffopt', new_diffopt, {})

  -- 4. 执行获取操作 (//2 为左/LOCAL, //3 为右/REMOTE)
  -- 执行后，Neovim 会像 Vim 一样把整个冲突块替换掉，标记自动消失
  vim.cmd('diffget //' .. side)

  -- 5. 恢复原始 diffopt (恢复 linematch 显示)
  vim.api.nvim_set_option_value('diffopt', old_diffopt, {})

  -- 6. 刷新 diff 状态
  vim.cmd 'diffupdate'
end
return M

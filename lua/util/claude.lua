-- ============================================================================
-- Claude Code Integration
-- ============================================================================
-- 目的：生成 Claude Code 可识别的文件行号引用格式 (@filename:line-range)
-- 作用：避免将整个文件内容发送给 Claude，而是通过行号精准定位代码片段
--
-- 使用场景：
--   - 讨论特定代码行时，提供精确引用
--   - 让 Claude 分析特定代码段而非整个文件
--   - 在代码审查中快速定位问题区域
-- 键位绑定见 lua/config/keymaps.lua 的 <leader>y

--- @class ClaudeUtil
local M = {}

--- 取当前 visual 选区的行范围
--- 必须在 visual 模式仍然活跃时调用：'< / '> 标记要等离开 visual 模式才更新，
--- 所以这里用 line('v') (选区固定端) 和 line('.') (光标端)，不依赖标记
--- @return integer # 起始行
--- @return integer # 结束行 (不小于起始行)
function M.visual_range()
  local anchor = vim.fn.line 'v'
  local cursor = vim.fn.line '.'
  return math.min(anchor, cursor), math.max(anchor, cursor)
end

--- 引用中使用的文件路径
--- 本地文件: 相对 vim 工作目录的路径，不在 CWD 之下时保留绝对路径
--- oil-ssh 远程文件，如 oil-ssh://tw//home/junyi/WorkSpace/julia_test_dir/a.sh:
---   路径含 WorkSpace/<project>/ 时以 <project> 为根 -> a.sh
---   否则去掉 oil-ssh://<host>/ 前缀，保留远程路径 (单斜杠形式相对远程 home，补成 ~/...)
--- @return string
local function reference_path()
  local remote = vim.api.nvim_buf_get_name(0):match '^oil%-ssh://[^/]+/(.*)$'
  if not remote then
    -- ":." 取相对于 vim 工作目录的路径，不在 CWD 之下时保留绝对路径
    return vim.fn.expand '%:.'
  end

  -- 前面补 '/'：WorkSpace 只按完整目录名匹配，同时兼容相对 home 的写法
  local project_relative = ('/' .. remote):match '/WorkSpace/[^/]+/(.+)$'
  if project_relative then
    return project_relative
  end
  return remote:sub(1, 1) == '/' and remote or '~/' .. remote
end

--- 生成 Claude Code 识别的行号引用
--- 单行: @filename:123    多行: @filename:123-456
--- @param line_start? integer 起始行，省略则取光标所在行
--- @param line_end? integer 结束行，省略则与起始行相同 (即单行引用)
--- @return string # 形如 "@lua/util/claude.lua:12-34" 的引用
function M.get_line_reference(line_start, line_end)
  line_start = line_start or vim.fn.line '.'
  line_end = line_end or line_start

  local reference = '@' .. reference_path() .. ':' .. line_start

  if line_end ~= line_start then
    reference = reference .. '-' .. line_end
  end

  return reference
end

return M

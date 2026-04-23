local M = {}

function M.fix_markdown_latex()
  local buf = vim.api.nvim_get_current_buf()
  -- 1. 获取所有行并合并为一个大字符串
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')

  -- 2. 处理块级公式 \[ ... \] -> $$...$$
  -- %s* 会匹配并消除内容前后的所有空白（包括换行和空格）
  -- 使用 (.-) 进行非贪婪匹配
  content = content:gsub('\\%[%s*(.-)%s*\\%]', '$$%1$$')

  -- 3. 处理行内公式 \( ... \) -> $...$
  -- 同样确保 $ 紧贴内容
  content = content:gsub('\\%(%s*(.-)%s*\\%)', '$%1$')

  -- 4. 将处理后的字符串重新拆分为行并写回 buffer
  local new_lines = vim.split(content, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)

  vim.notify 'LaTeX delimiters converted: Multi-line supported, spaces trimmed.'
end

return M

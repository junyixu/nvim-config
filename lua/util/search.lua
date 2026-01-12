--- @class SearchUtil
local M = {}

--- 获取所有已列出 (listed) 且关联了文件的 Buffer 路径列表
--- 过滤掉无名 Buffer 和非文件类型的 Buffer (如插件窗口)
--- @return string[] # 转义后的绝对路径列表
function M.get_listed_paths()
  return vim
    .iter(vim.fn.getbufinfo { buflisted = 1 })
    :filter(function(b)
      return b.name ~= '' and vim.bo[b.bufnr].buftype == ''
    end)
    :map(function(b)
      return vim.fn.fnameescape(b.name)
    end)
    :totable()
end

--- 获取相对于当前工作目录 (CWD) 的简洁路径列表
--- 这样做可以避免命令行过长，同时保持路径的可读性
--- @return string[] # 转义后的相对路径列表
function M.get_short_paths()
  return vim
    .iter(vim.fn.getbufinfo { buflisted = 1 })
    :filter(function(b)
      return b.name ~= '' and vim.bo[b.bufnr].buftype == ''
    end)
    :map(function(b)
      -- ":." 转换为相对路径，如果不在 CWD 下则保留原样
      local rel_path = vim.fn.fnamemodify(b.name, ':.')
      return vim.fn.fnameescape(rel_path)
    end)
    :totable()
end

--- 构造 vimgrep 命令字符串
--- 使用 \V (very nomagic) 和 \C (match case) 确保搜索行为可预测
--- @param pattern string 搜索模式 (关键词)
--- @param paths string[] 需要搜索的文件路径列表
--- @return string # 构造好的命令字符串，如 ":vimgrep /\<word\>\V\C/ file1 file2"
function M.build_vimgrep_cmd(pattern, paths)
  if #paths == 0 or pattern == '' then
    return ''
  end
  -- 用 \< \> 匹配全字，\V 禁止大部分特殊字符转义，\C 强制区分大小写
  return string.format(':vimgrep /\\<%s\\>\\V\\C/ %s', pattern, table.concat(paths, ' '))
end

--- 将字符串喂给命令行 (Command-line) 但不立即触发回车
--- 方便用户在执行前进行最后的检查或修改
--- @param cmd string 需要输入的命令内容
function M.feed_cmd(cmd)
  if cmd == '' then
    return
  end
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end

--- [主功能] 在所有打开的 Buffer 中搜索当前光标下的单词 (cword)
--- 默认使用相对路径以保持命令行整洁
function M.search_cword_in_buffers()
  local cword = vim.fn.expand '<cword>'
  if cword == '' then
    vim.notify('Cursor is not on a word', vim.log.levels.WARN)
    return
  end

  local paths = M.get_short_paths()
  local cmd = M.build_vimgrep_cmd(cword, paths)

  if cmd ~= '' then
    M.feed_cmd(cmd)
  else
    vim.notify('No valid listed buffers found', vim.log.levels.INFO)
  end
end

return M

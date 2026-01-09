local M = {}

local QUICKFIX_MAX_HEIGHT = 15

function M.adjust_quickfix_height(item_count)
  local height = math.min(item_count, QUICKFIX_MAX_HEIGHT)

  local qf_win = vim.fn.getqflist({ winid = 0 }).winid
  if qf_win ~= 0 then
    vim.api.nvim_win_set_height(qf_win, height)
  end
end

--- 1. 处理正则转换 (对应你的 s:query2vimregexp)
--- @param query string 原始查询字符串
--- @param is_vimgrep boolean 是否是 vimgrep (如果是，已经是 Vim 格式)
function M.query_to_vim_regexp(query, is_vimgrep)
  if is_vimgrep then
    return query
  end

  local vim_query = query

  -- 处理转义的引号: '\'' -> '
  vim_query = vim_query:gsub("'\\''", "'")

  -- 移除首尾的引号 (匹配 "query" 或 'query')
  local first = vim_query:sub(1, 1)
  local last = vim_query:sub(-1, -1)
  if first == last and (first == '"' or first == "'") then
    vim_query = vim_query:sub(2, -2)
  end

  -- 正则转换逻辑
  -- \bfoo\b -> \<foo\> (假设只有一对)
  vim_query = vim_query:gsub('\\b(.-)\\b', '\\<%1\\>')

  -- 非贪婪匹配转换: *? -> \{-} 和 +? -> \{-1,}
  vim_query = vim_query:gsub('%*%?', '\\{-}')
  vim_query = vim_query:gsub('%+%?', '\\{-1,}')

  -- 如果有其他 tool.escape 逻辑，可以在此继续扩展
  return vim_query
end

--- 2. 从完整的命令行中提取真正的模式部分
--- @param full_cmd string 例如: vimgrep /pattern/g files
function M.extract_pattern(full_cmd)
  -- 移除开头的命令名 (vimgrep, grep 等)
  local cmd_content = full_cmd:gsub('^%s*%w+!?%s+', '')

  -- 针对 vimgrep 的解析: 通常格式为 /pattern/ 或 #pattern#
  -- 如果第一个字符是非字母数字且不是空格，通常是分隔符
  local first_char = cmd_content:sub(1, 1)
  if first_char:match '[^%w%s\\]' then
    local pattern = cmd_content:match(first_char .. '(.-)' .. first_char)
    if pattern then
      return pattern
    end
  end

  -- 针对 grep 的解析: 简单处理，取第一个非 flag 的参数
  -- 这里为了简化逻辑，假设 pattern 是第一个不以 - 开头的单词
  for word in cmd_content:gmatch '%S+' do
    if not word:match '^%-' then
      return word
    end
  end
  return cmd_content
end

--- 3. 同步到 Vim 搜索状态
function M.sync_to_search_register(pattern)
  if not pattern or pattern == '' then
    return
  end

  -- 设置寄存器 @/
  vim.fn.setreg('/', pattern)
  -- 添加到搜索历史
  vim.fn.histadd('search', pattern)

  -- 触发高亮 (通过 feedkeys 模拟按下回车触发 hlsearch 重绘)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':set hls<bar>echo<cr>', true, false, true), 'n', false)
end

return M

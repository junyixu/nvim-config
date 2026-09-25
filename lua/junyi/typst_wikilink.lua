-- inkycap 的 #wikilink("笔记名", display: "…", label: "标签") 跳转:
-- 打开 <项目根>/笔记名.typ, 有 label 就跳到 `<标签>` 所在行.
-- 项目根 = 往上找含 .inkycap/ 的目录 (找不到就用当前文件所在目录).
local M = {}

local function text(node, buf)
  return vim.treesitter.get_node_text(node, buf)
end

local function is_wikilink(node, buf)
  if node:type() ~= 'call' then
    return false
  end
  local item = node:field('item')[1]
  return item ~= nil and item:type() == 'ident' and text(item, buf) == 'wikilink'
end

-- 光标所在的 #wikilink(...) call 节点 (调用内任意位置, 包括开头的 `#`)
local function wikilink_at_cursor(buf)
  -- buffer 没开 treesitter 高亮时语法树可能还没生成, 先 parse (增量, 已解析过就很快)
  local has_parser, parser = pcall(vim.treesitter.get_parser, buf, 'typst')
  if not has_parser or not parser then
    return
  end
  parser:parse()
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf })
  if not ok then
    return
  end
  while node do
    if is_wikilink(node, buf) then
      return node
    end
    -- 光标在 `#` 上时拿到的是 (code (call ...))
    local child = node:type() == 'code' and node:named_child(0)
    if child and is_wikilink(child, buf) then
      return child
    end
    node = node:parent()
  end
end

-- "…" -> …
local function unquote(s)
  return (s:gsub('^"', ''):gsub('"$', ''))
end

-- 返回 name, label (label 可能为 nil)
local function parse_args(call, buf)
  local group
  for child in call:iter_children() do
    if child:type() == 'group' then
      group = child
      break
    end
  end
  if not group then
    return
  end
  local name, label
  for arg in group:iter_children() do
    if arg:type() == 'string' and not name then
      name = unquote(text(arg, buf))
    elseif arg:type() == 'tagged' then
      local field = arg:field('field')[1]
      local value = arg:named_child(1)
      if field and value and text(field, buf) == 'label' and value:type() == 'string' then
        label = unquote(text(value, buf))
      end
    end
  end
  return name, label
end

--- 笔记库根目录: 往上找 .inkycap/, 找不到就用当前文件所在目录
function M.root(buf)
  return vim.fs.root(buf, '.inkycap') or vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
end

local label_query

-- lines 里所有标签: { { label = 'sec:…', detail = '== …', row = 0 起, col = 0 起 }, … }
-- 用 treesitter 的 (label) 节点, 所以公式/代码/注释/字符串里的 `<…>` 不算;
-- detail = 标签所在行去掉标签后的文字, 标签单独一行时取上面最近的非空行.
local function collect_labels(lines)
  local src = table.concat(lines, '\n')
  label_query = label_query or vim.treesitter.query.parse('typst', '(label) @label')
  local root = vim.treesitter.get_string_parser(src, 'typst'):parse()[1]:root()
  local res = {}
  for _, node in label_query:iter_captures(root, src) do
    local row, col = node:start()
    local detail = vim.trim((lines[row + 1]:gsub('<[^%s<>]+>', '')))
    local r = row
    while detail == '' and r > 0 do
      r = r - 1
      detail = vim.trim(lines[r + 1])
    end
    res[#res + 1] = { label = text(node, src):sub(2, -2), detail = detail, row = row, col = col }
  end
  return res
end

--- 文件里所有标签 (读磁盘), 格式见 collect_labels
function M.labels(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and collect_labels(lines) or {}
end

--- 光标在 #wikilink 上就跳转并返回 true; 否则返回 false (交给 LSP)
function M.jump()
  local buf = vim.api.nvim_get_current_buf()
  local call = wikilink_at_cursor(buf)
  if not call then
    return false
  end

  local name, label = parse_args(call, buf)
  if not name then
    vim.notify('wikilink: 没有解析出笔记名', vim.log.levels.WARN)
    return true
  end

  local path = vim.fs.joinpath(M.root(buf), name .. '.typ')
  if not vim.uv.fs_stat(path) then
    vim.notify('wikilink: 文件不存在: ' .. path, vim.log.levels.ERROR)
    return true
  end

  vim.cmd "normal! m'"
  local ok, err = pcall(vim.cmd.edit, vim.fn.fnameescape(path))
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return true
  end
  if not label then
    return true
  end

  -- 解析 buffer 而不是磁盘文件: 目标可能已打开且有未保存的修改
  for _, l in ipairs(collect_labels(vim.api.nvim_buf_get_lines(0, 0, -1, false))) do
    if l.label == label then
      vim.api.nvim_win_set_cursor(0, { l.row + 1, l.col })
      vim.cmd 'normal! zv'
      return true
    end
  end
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.notify(('wikilink: %s 里没有标签 <%s>'):format(name, label), vim.log.levels.WARN)
  return true
end

return M

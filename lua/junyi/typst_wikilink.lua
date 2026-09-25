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

--- 文件里所有标题标签: { { label = 'sec:…', heading = '== …' }, … }
function M.labels(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  local res = {}
  if not ok then
    return res
  end
  for _, line in ipairs(lines) do
    local label = line:match '^%s*=+%s.-<([^%s<>]+)>%s*$'
    if label then
      res[#res + 1] = { label = label, heading = vim.trim((line:gsub('<[^%s<>]+>%s*$', ''))) }
    end
  end
  return res
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

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  if vim.fn.search('\\V<' .. vim.fn.escape(label, '\\') .. '>', 'cW') == 0 then
    vim.notify(('wikilink: %s 里没有标签 <%s>'):format(name, label), vim.log.levels.WARN)
  else
    vim.cmd 'normal! zv'
  end
  return true
end

return M

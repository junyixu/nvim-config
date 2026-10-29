-- blink.cmp source: markdown 里 Claude Code 风格的 @路径 补全 (相对 :pwd, 逐级目录)
--   @lua/cu|          → 列出 lua/ 下的条目
--   @"my notes/a|     → 含空格的路径用 @"..." (Claude Code CLI 支持这种写法)
-- 选中目录后自动弹出下一层; 含空格的名字在不带引号的写法里会整段改成带引号的写法.
-- 配合 lua/custom/claude_kitty.lua 把 markdown 发给 kitty 里的 Claude Code.

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == 'markdown' and vim.bo.buftype == ''
end

function source:get_trigger_characters()
  return { '@', '/' }
end

--- 光标前的 @ 上下文; @ 必须在行首或空白后, 避免邮箱 foo@bar.com
--- @return integer? start 0-based 列, @ 之后第一个字符 (带引号时是引号)
--- @return string typed @ (及引号) 之后已输入的部分
--- @return boolean quoted
local function at_context(before)
  local start, typed = before:match '()@"([^"]*)$'
  local quoted = start ~= nil
  if not quoted then
    start, typed = before:match '()@([^%s"@]*)$'
  end
  if not start or (start > 1 and not before:sub(start - 1, start - 1):match '%s') then
    return nil, '', false
  end
  return start, typed, quoted
end

local function list_dir(dir, include_hidden)
  local entries = {}
  for name, kind in vim.fs.dir(dir) do
    if include_hidden or name:sub(1, 1) ~= '.' then
      local path = vim.fs.joinpath(dir, name)
      local is_dir = kind == 'directory' or (kind == 'link' and vim.fn.isdirectory(path) == 1)
      entries[#entries + 1] = { name = name, is_dir = is_dir }
    end
  end
  table.sort(entries, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir
    end
    return a.name < b.name
  end)
  return entries
end

function source:get_completions(ctx, callback)
  local kinds = require('blink.cmp.types').CompletionItemKind
  local row, col = ctx.cursor[1] - 1, ctx.cursor[2]
  local before = ctx.line:sub(1, col)
  local items = {}

  local start, typed, quoted = at_context(before)
  if start then
    -- typed = dir_part .. segment, 只替换正在输入的这一段
    local dir_part, segment = typed:match '^(.*/)([^/]*)$'
    if not dir_part then
      dir_part, segment = '', typed
    end
    local dir = vim.fs.joinpath(vim.fn.getcwd(), dir_part)
    local seg_start = col - #segment
    -- @ 后面的位置 (0-based), 用于把整段改写成带引号的写法
    local path_start = start

    for _, e in ipairs(list_dir(dir, segment:sub(1, 1) == '.')) do
      local label = e.is_dir and e.name .. '/' or e.name
      local new_text, range_start = label, seg_start
      if quoted then
        new_text = e.is_dir and label or label .. '"'
      elseif e.name:find ' ' then
        new_text = '"' .. dir_part .. label .. (e.is_dir and '' or '"')
        range_start = path_start
      end
      items[#items + 1] = {
        label = label,
        filterText = e.name,
        kind = e.is_dir and kinds.Folder or kinds.File,
        data = { is_dir = e.is_dir },
        textEdit = {
          newText = new_text,
          range = {
            start = { line = row, character = range_start },
            ['end'] = { line = row, character = col },
          },
        },
      }
    end
  end

  callback { items = items, is_incomplete_forward = false, is_incomplete_backward = false }
end

-- 选中目录后继续弹出下一层
function source:execute(_, item, callback, default_implementation)
  default_implementation()
  if item.data and item.data.is_dir then
    vim.schedule(function()
      require('blink.cmp').show { providers = { 'at_path' } }
    end)
  end
  callback()
end

return source

-- blink.cmp source: inkycap #wikilink 补全
--   #wikilink("|              → 笔记名 (根目录下 *.typ 去掉扩展名)
--   #wikilink("名", label: "| → 目标笔记里标题行末尾的 <标签>
-- 用光标前的行文本匹配, 不用 treesitter: 正在输入的调用往往还没闭合, 语法树是 ERROR.
local wikilink = require 'junyi.typst_wikilink'

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == 'typst'
end

function source:get_trigger_characters()
  return { '"' }
end

-- 笔记名含空格, 而 blink 只拿光标前最后一个"词"做模糊匹配 (遇到空格就断),
-- 所以先按已输入的整段文字过滤: 空格分隔的每一段都要出现在候选里 (不区分大小写).
local function match_all(typed, candidate)
  candidate = candidate:lower()
  for part in typed:lower():gmatch '%S+' do
    if not candidate:find(part, 1, true) then
      return false
    end
  end
  return true
end

local function note_names(root)
  local names = {}
  for name, kind in vim.fs.dir(root) do
    local stem = name:match '^(.*)%.typ$'
    if (kind == 'file' or kind == 'link') and stem and stem ~= 'template' and not stem:match '^test' then
      names[#names + 1] = stem
    end
  end
  table.sort(names)
  return names
end

local function item(text, row, start_col, end_col, kind, detail)
  return {
    label = text,
    filterText = text,
    kind = kind,
    labelDetails = detail and { description = detail } or nil,
    textEdit = {
      newText = text,
      range = {
        start = { line = row, character = start_col },
        ['end'] = { line = row, character = end_col },
      },
    },
  }
end

function source:get_completions(ctx, callback)
  local kinds = require('blink.cmp.types').CompletionItemKind
  local row, col = ctx.cursor[1] - 1, ctx.cursor[2]
  local before = ctx.line:sub(1, col)
  local items = {}

  local name, typed = before:match '#wikilink%("([^"]+)"[^)]-label:%s*"([^"]*)$'
  if name then
    local path = vim.fs.joinpath(wikilink.root(ctx.bufnr), name .. '.typ')
    for _, l in ipairs(wikilink.labels(path)) do
      if match_all(typed, l.label) then
        items[#items + 1] = item(l.label, row, col - #typed, col, kinds.Reference, l.detail)
      end
    end
  else
    typed = before:match '#wikilink%("([^"]*)$'
    if typed then
      for _, stem in ipairs(note_names(wikilink.root(ctx.bufnr))) do
        if match_all(typed, stem) then
          items[#items + 1] = item(stem, row, col - #typed, col, kinds.File)
        end
      end
    end
  end

  -- 每次按键都重新过滤 (match_all 依赖整段输入)
  callback { items = items, is_incomplete_forward = true, is_incomplete_backward = true }
end

return source

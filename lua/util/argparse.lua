-- 给 nvim 用户命令用的小型参数解析器：一份声明同时生成 parse、帮助文本和补全函数。
-- 出错时返回 nil, msg，不会 print，也不会退出 nvim。
--
--   local parser = require('util.argparse').new {
--     name = 'TrixiSync',                                   -- 帮助和报错里显示为 :TrixiSync
--     commands = {                                          -- 可省略；有的话第一个位置参数必须是其中之一
--       { 'push', '本地 -> 远端', usage = '[-y]' },
--       { 'open', '打开文件', complete = 'file' },          -- complete: 列表 / 函数 / getcompletion 的类型名
--     },
--     usage = '[FILE]',                                     -- 没有 commands 时帮助第一行的用法
--     flags = {
--       { '-n', '--dry-run', key = 'dry', help = '只打印不执行' },  -- 布尔开关；key 默认取长名 dry_run
--       { '-p', '--pattern', arg = 'PAT', help = '过滤' },          -- 带值：-p x / --pattern x / --pattern=x
--     },
--     epilog = { '配置：...' },                             -- 帮助末尾的附加说明
--   }
--
--   local o, err = parser:parse(opts.fargs)  -- o.cmd、o.args（其余位置参数）、o.dry、o.pattern、o.help
--   parser:help()                            -- string[]
--   complete = parser:complete()             -- 直接交给 nvim_create_user_command
--
-- 自动支持 -h/--help（只置 o.help = true，由调用方决定怎么显示）、`--` 之后全当位置参数、
-- 短开关合写（-ny）。

local M = {}

local Parser = {}
Parser.__index = Parser

local HELP_FLAG = { '-h', '--help', help = '显示帮助' }

local function key_of(f)
  if f.key then
    return f.key
  end
  local name = f[1]
  for _, n in ipairs(f) do
    if vim.startswith(n, '--') then
      name = n
    end
  end
  return (name:gsub('^%-+', ''):gsub('-', '_'))
end

-- 按最宽的左列对齐，左右列之间至少空 3 格
local function columns(rows, indent)
  local width = 0
  for _, r in ipairs(rows) do
    width = math.max(width, vim.fn.strdisplaywidth(r[1]))
  end
  return vim.tbl_map(function(r)
    local pad = string.rep(' ', width - vim.fn.strdisplaywidth(r[1]) + 3)
    return ((indent .. r[1] .. pad .. (r[2] or '')):gsub('%s+$', ''))
  end, rows)
end

function M.new(spec)
  local p = setmetatable({
    name = spec.name,
    usage = spec.usage,
    epilog = spec.epilog,
    commands = spec.commands,
    command = {}, -- 名字 -> 命令声明
    flags = {},
    flag = {}, -- '-n' / '--dry-run' -> 选项声明
  }, Parser)
  for _, c in ipairs(spec.commands or {}) do
    p.command[c[1]] = c
  end
  for _, f in ipairs(vim.list_extend(vim.list_slice(spec.flags or {}), { HELP_FLAG })) do
    f = vim.tbl_extend('keep', { key = key_of(f) }, f)
    p.flags[#p.flags + 1] = f
    for _, n in ipairs(f) do
      p.flag[n] = f
    end
  end
  return p
end

function Parser:error(fmt, ...)
  return ('%s（:%s -h 看帮助）'):format(fmt:format(...), self.name)
end

-- 把 '-ny' 拆成 { '-n', '-y' }；不是合法的短开关合写就返回 nil
function Parser:split_shorts(a)
  if not a:match '^%-%a%a+$' then
    return nil
  end
  local out = {}
  for ch in a:sub(2):gmatch '.' do
    local f = self.flag['-' .. ch]
    if not f or f.arg then
      return nil
    end
    out[#out + 1] = '-' .. ch
  end
  return out
end

---@param fargs string[]
---@return table? opts, string? err
function Parser:parse(fargs)
  local o, pos = {}, {}
  for _, f in ipairs(self.flags) do
    o[f.key] = f.default
  end

  local i, rest = 1, false
  while i <= #fargs do
    local a = fargs[i]
    if rest or a == '-' or a:sub(1, 1) ~= '-' then
      pos[#pos + 1] = a
    elseif a == '--' then
      rest = true
    else
      local name, val = a:match '^(%-%-[^=]+)=(.*)$'
      local f = self.flag[name or a]
      local shorts = not f and self:split_shorts(a)
      if shorts then
        for _, s in ipairs(shorts) do
          o[self.flag[s].key] = true
        end
      elseif not f then
        return nil, self:error('未知选项: %s', a)
      elseif f.arg then
        if not val then
          i = i + 1
          val = fargs[i]
        end
        if not val then
          return nil, self:error('选项 %s 需要参数 %s', a, f.arg)
        end
        o[f.key] = val
      elseif val then
        return nil, self:error('选项 %s 不接受参数', name)
      else
        o[f.key] = true
      end
    end
    i = i + 1
  end

  if self.commands and #pos > 0 then
    o.cmd = table.remove(pos, 1)
    if not self.command[o.cmd] then
      return nil, self:error('未知命令: %s', o.cmd)
    end
  end
  o.args = pos
  return o
end

---@return string[]
function Parser:help()
  local lines = {}
  if self.commands then
    local w = 0
    for _, c in ipairs(self.commands) do
      w = math.max(w, #c[1])
    end
    vim.list_extend(
      lines,
      columns(
        vim.tbl_map(function(c)
          return { vim.trim(('%s %-' .. w .. 's %s'):format(':' .. self.name, c[1], c.usage or '')), c[2] }
        end, self.commands),
        ''
      )
    )
  else
    lines[1] = vim.trim((':%s [选项] %s'):format(self.name, self.usage or ''))
  end

  vim.list_extend(lines, { '', '选项：' })
  vim.list_extend(
    lines,
    columns(
      vim.tbl_map(function(f)
        return { table.concat(f, ', ') .. (f.arg and ' ' .. f.arg or ''), f.help }
      end, self.flags),
      '  '
    )
  )

  if self.epilog then
    lines[#lines + 1] = ''
    vim.list_extend(lines, self.epilog)
  end
  return lines
end

---@return fun(arglead: string, cmdline: string): string[]
function Parser:complete()
  local flag_names = {}
  for _, f in ipairs(self.flags) do
    vim.list_extend(flag_names, f)
  end
  local command_names = vim.tbl_map(function(c)
    return c[1]
  end, self.commands or {})

  return function(arglead, cmdline)
    local function matching(list)
      return vim.tbl_filter(function(s)
        return vim.startswith(s, arglead)
      end, list)
    end
    if arglead:sub(1, 1) == '-' then
      return matching(flag_names)
    end

    -- 已经写完的词：去掉命令名本身，以及正在补全的 arglead
    local words = vim.split(cmdline, '%s+', { trimempty = true })
    table.remove(words, 1)
    if arglead ~= '' then
      table.remove(words)
    end
    local f = self.flag[words[#words] or '']
    if f and f.arg then
      return {} -- 正在写选项的值
    end

    local cmd = vim.iter(words):find(function(w)
      return self.command[w] ~= nil
    end)
    if not self.commands then
      return {}
    elseif not cmd then
      return matching(command_names)
    end

    local comp = self.command[cmd].complete
    if type(comp) == 'function' then
      return comp(arglead, cmdline)
    elseif type(comp) == 'string' then
      return vim.fn.getcompletion(arglead, comp)
    end
    return matching(comp or {})
  end
end

return M

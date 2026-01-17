-- Simple tabline: show tab index prefix (for <M-1..9> muscle memory)
-- and keep the per-tab window count suffix.

local M = {}

local function hl(name, fallback)
  if vim.fn.hlexists(name) == 1 then
    return string.format('%%#%s#', name)
  end
  return string.format('%%#%s#', fallback)
end

local function abbrev_dir_component(component)
  if component == '' then
    return ''
  end
  if component == '.' or component == '..' then
    return component
  end
  if component:sub(1, 1) == '.' and #component >= 2 then
    return '.' .. component:sub(2, 2)
  end
  return component:sub(1, 1)
end

local function normalize_path(path)
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end
  return vim.fn.fnamemodify(path, ':p')
end

local function is_under_dir(path, dir)
  local sep = package.config:sub(1, 1)
  local p = normalize_path(path)
  local d = normalize_path(dir)
  if d:sub(-1) ~= sep then
    d = d .. sep
  end
  return p:sub(1, #d) == d
end

local function relative_to_dir(path, dir)
  local sep = package.config:sub(1, 1)
  local p = normalize_path(path)
  local d = normalize_path(dir)
  if d:sub(-1) ~= sep then
    d = d .. sep
  end
  if p:sub(1, #d) ~= d then
    return nil
  end
  local rel = p:sub(#d + 1)
  if rel == '' then
    return vim.fn.fnamemodify(p, ':t')
  end
  return rel
end

local function abbreviate_path(path)
  local sep = package.config:sub(1, 1)
  local p = normalize_path(path)

  local home = vim.env.HOME
  local prefix = sep
  local rel = p
  if home and home ~= '' then
    local home_norm = normalize_path(home)
    if p == home_norm or p:sub(1, #home_norm + 1) == home_norm .. sep then
      prefix = '~' .. sep
      rel = p:sub(#home_norm + 2)
    end
  end

  local parts = vim.split(rel, sep, { plain = true, trimempty = true })
  if #parts == 0 then
    return prefix
  end

  local filename = parts[#parts]
  local dirs = {}
  for i = 1, #parts - 1 do
    table.insert(dirs, abbrev_dir_component(parts[i]))
  end

  if #dirs == 0 then
    return prefix .. filename
  end

  return prefix .. table.concat(dirs, sep) .. sep .. filename
end

local function tab_title(tabpage)
  local winid = vim.api.nvim_tabpage_get_win(tabpage)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  if bufname == '' then
    return '[No Name]'
  end

  -- Only abbreviate real filesystem paths. For special buffers (like terminals),
  -- keep the basename to avoid odd-looking protocol names.
  if bufname:sub(1, 1) ~= '/' then
    local scheme = bufname:match('^(%a[%w+.-]*):')
    if scheme == 'fugitive' then
      return 'FUGITIVE'
    end

    local base = vim.fn.fnamemodify(bufname, ':t')
    if base ~= '' then
      return base
    end
    return scheme or '[No Name]'
  end

  local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
  local tab_cwd = vim.fn.getcwd(0, tabnr)
  if tab_cwd and tab_cwd ~= '' and is_under_dir(bufname, tab_cwd) then
    return relative_to_dir(bufname, tab_cwd) or vim.fn.fnamemodify(bufname, ':t')
  end

  return abbreviate_path(bufname)
end

local function list_layout_wins(tabpage)
  local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
  local layout = vim.fn.winlayout(tabnr)
  if type(layout) ~= 'table' or layout[1] == nil then
    return {}
  end

  local wins = {}
  local function walk(node)
    if type(node) ~= 'table' then
      return
    end

    if node[1] == 'leaf' and type(node[2]) == 'number' then
      table.insert(wins, node[2])
      return
    end

    local children = node[2]
    if type(children) ~= 'table' then
      return
    end
    for _, child in ipairs(children) do
      walk(child)
    end
  end

  walk(layout)
  return wins
end

local function tab_win_status_suffix(tabpage)
  -- Count only "real" split windows from `winlayout()`.
  -- This avoids counting temporary floating/plugin windows (e.g. flash.nvim hints).
  local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
  local wins = list_layout_wins(tabpage)
  if #wins <= 1 then
    return ''
  end

  local items = {}
  for _, win in ipairs(wins) do
    local ok, tabwin = pcall(vim.fn.win_id2tabwin, win)
    if ok and type(tabwin) == 'table' and tabwin[1] == tabnr and type(tabwin[2]) == 'number' then
      table.insert(items, { win = win, winnr = tabwin[2] })
    end
  end

  table.sort(items, function(a, b)
    return a.winnr < b.winnr
  end)

  local total = #items
  if total <= 1 then
    return ''
  end

  local cur_win = vim.api.nvim_tabpage_get_win(tabpage)
  local cur_index = 1
  for i, item in ipairs(items) do
    if item.win == cur_win then
      cur_index = i
      break
    end
  end

  return string.format(' [%d/%d]', cur_index, total)
end

function M.render()
  local parts = {}
  local current = vim.api.nvim_get_current_tabpage()

  for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local tab_hl = tabpage == current and hl('MiniTablineCurrent', 'TabLineSel') or hl('MiniTablineVisible', 'TabLine')
    local label = string.format('%d. %s%s', i, tab_title(tabpage), tab_win_status_suffix(tabpage))
    table.insert(parts, string.format('%%%dT%s %s ', i, tab_hl, label))
  end

  table.insert(parts, hl('MiniTablineFill', 'TabLineFill') .. '%=%T')
  return table.concat(parts)
end

function M.setup()
  -- Only show tabline when there are at least 2 tabpages.
  vim.o.showtabline = 1
  vim.o.tabline = "%{%v:lua.require('custom.tabline').render()%}"
end

return M

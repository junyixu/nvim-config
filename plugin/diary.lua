-- Diary keymaps

local function diary_template(date_str)
  local y, m, d = date_str:match('(%d+)-(%d+)-(%d+)')
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  local today_t = os.time({ year = y, month = m, day = d })
  local yesterday_t = os.time({ year = y, month = m, day = d - 1 })
  local tomorrow_t = os.time({ year = y, month = m, day = d + 1 })

  local old_locale = os.setlocale('en_US.UTF-8')
  local formatted_date = os.date('%A, %B %d, %Y', today_t)
  local yesterday_link = os.date('%Y/%m/%Y-%m-%d', yesterday_t)
  local tomorrow_link = os.date('%Y/%m/%Y-%m-%d', tomorrow_t)
  os.setlocale(old_locale)

  local header = string.format(
    '# %s\n\n<< [[diary/%s|Yesterday]] | [[diary/%s|Tomorrow]] >>\n\n',
    formatted_date, yesterday_link, tomorrow_link
  )

  local template_path = vim.fn.expand '~/Notes/templates/diary.md'
  local body = ''
  if vim.fn.filereadable(template_path) == 1 then
    local lines = vim.fn.readfile(template_path)
    for i = 5, #lines do
      body = body .. lines[i] .. '\n'
    end
  end

  return header .. body
end

vim.api.nvim_create_autocmd('BufNewFile', {
  group = vim.api.nvim_create_augroup('DiaryTemplate', { clear = true }),
  pattern = vim.fn.expand('~/Notes/diary') .. '/*/*/*.md',
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local date_str = vim.fn.expand '%:t:r'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(diary_template(date_str), '\n'))
    vim.schedule(function()
      vim.bo[buf].modified = true
    end)
  end,
})

local function open_diary(open_cmd)
  local date_str = os.date('%Y-%m-%d')
  local year = os.date('%Y')
  local month = os.date('%m')
  local path = '~/Notes/diary/' .. year .. '/' .. month .. '/' .. date_str .. '.md'
  local expanded = vim.fn.expand(path)

  vim.fn.mkdir(vim.fn.fnamemodify(expanded, ':h'), 'p')
  vim.cmd(open_cmd .. ' ' .. vim.fn.fnameescape(expanded))
  vim.cmd('tcd %:h')
  vim.cmd('tcd ../../..')
end

vim.keymap.set('n', ',w,w', function()
  open_diary('e')
end, { silent = true, desc = 'Open today\'s diary' })

vim.keymap.set('n', ',w,t', function()
  open_diary('tabe')
end, { silent = true, desc = 'Open today\'s diary in new tab' })

-- Collect unchecked tasks from the last N diary files into the quickfix list
local function diary_tasks(days)
  local root = vim.fn.expand '~/Notes'
  local today = os.date '*t'
  local files = {}

  for i = 0, days - 1 do
    -- hour=12 keeps day arithmetic DST-safe
    local t = os.time { year = today.year, month = today.month, day = today.day - i, hour = 12 }
    local f = root .. os.date('/diary/%Y/%m/%Y-%m-%d.md', t)
    if vim.fn.filereadable(f) == 1 then
      files[#files + 1] = vim.fn.fnameescape(f)
    end
  end

  if #files == 0 then
    vim.notify('No diary files in the last ' .. days .. ' days', vim.log.levels.WARN)
    return
  end

  vim.cmd('silent! vimgrep /\\v^\\s*[-*] \\[ \\]/j ' .. table.concat(files, ' '))

  if vim.fn.getqflist({ size = 0 }).size == 0 then
    vim.notify('No open tasks in the last ' .. days .. ' days', vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, 'a', { title = 'Diary tasks (last ' .. days .. ' days)' })
  vim.cmd 'copen'
end

vim.api.nvim_create_user_command('DiaryTasks', function(opts)
  diary_tasks(tonumber(opts.args) or 7)
end, { nargs = '?', desc = 'Quickfix list of open diary tasks (default last 7 days)' })

vim.keymap.set('n', ',wq', '<Cmd>DiaryTasks<CR>', { silent = true, desc = 'Diary tasks in quickfix' })

vim.keymap.set('n', ',ww', function()
  vim.cmd('e ~/Notes/index.md')
  vim.cmd('tcd %:h')
end, { silent = true, desc = 'Open Notes index' })

vim.keymap.set('n', ',wt', function()
  vim.cmd('tabe ~/Notes/index.md')
  vim.cmd('tcd %:h')
end, { silent = true, desc = 'Open Notes index in new tab' })

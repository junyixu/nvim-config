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

local function open_diary(open_cmd)
  local date_str = os.date('%Y-%m-%d')
  local year = os.date('%Y')
  local month = os.date('%m')
  local path = '~/Notes/diary/' .. year .. '/' .. month .. '/' .. date_str .. '.md'
  local expanded = vim.fn.expand(path)

  local is_new = vim.fn.filereadable(expanded) == 0
  if is_new then
    vim.fn.mkdir(vim.fn.fnamemodify(expanded, ':h'), 'p')
  end

  vim.cmd(open_cmd .. ' ' .. vim.fn.fnameescape(expanded))

  if is_new then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(diary_template(date_str), '\n'))
  end
  vim.cmd('tcd %:h')
  vim.cmd('tcd ../../..')
end

vim.keymap.set('n', ',w,w', function()
  open_diary('e')
end, { silent = true, desc = 'Open today\'s diary' })

vim.keymap.set('n', ',w,t', function()
  open_diary('tabe')
end, { silent = true, desc = 'Open today\'s diary in new tab' })

vim.keymap.set('n', ',ww', function()
  vim.cmd('e ~/Notes/index.md')
  vim.cmd('tcd %:h')
end, { silent = true, desc = 'Open Notes index' })

vim.keymap.set('n', ',wt', function()
  vim.cmd('tabe ~/Notes/index.md')
  vim.cmd('tcd %:h')
end, { silent = true, desc = 'Open Notes index in new tab' })

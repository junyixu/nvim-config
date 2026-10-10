-- Diary navigation: jump to the previous/next existing entry under
-- <diary_dir>/YYYY/MM/YYYY-MM-DD.md, skipping days without one.
-- Required lazily by plugin/last_diary.lua on first :DiaryPrev/:DiaryNext.
--
-- Options (read on every call):
--   vim.g.diary_dir              default '~/Notes/diary'
--   vim.g.diary_max_search_days  default 365

local M = {}

-- Date of the current buffer (from its YYYY-MM-DD file name), today for an
-- unnamed buffer, nil for any other file.
local function buf_date()
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then
    return os.date '*t'
  end
  local y, m, d = vim.fn.fnamemodify(name, ':t:r'):match '^(%d%d%d%d)-(%d%d)-(%d%d)$'
  if y then
    return { year = tonumber(y), month = tonumber(m), day = tonumber(d) }
  end
end

local function navigate(direction)
  local date = buf_date()
  if not date then
    vim.notify('Not a diary file: ' .. vim.fn.expand '%:t', vim.log.levels.WARN)
    return
  end

  local dir = vim.fs.normalize(vim.g.diary_dir or '~/Notes/diary')
  for i = 1, vim.g.diary_max_search_days or 365 do
    -- hour=12 keeps day arithmetic DST-safe; os.time normalizes day overflow
    local t = os.time { year = date.year, month = date.month, day = date.day + i * direction, hour = 12 }
    local path = dir .. os.date('/%Y/%m/%Y-%m-%d.md', t)
    if vim.uv.fs_stat(path) then
      vim.cmd('silent edit ' .. vim.fn.fnameescape(path))
      return
    end
  end
end

function M.prev()
  navigate(-1)
end

function M.next()
  navigate(1)
end

return M

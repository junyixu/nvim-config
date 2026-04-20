local function clamp_buf_pos(buf, pos)
  if type(pos) ~= 'table' then
    return pos
  end
  local lnum = tonumber(pos[1]) or 0
  local col = tonumber(pos[2]) or 0
  if lnum <= 0 then
    return pos
  end

  if not (vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)) then
    return pos
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count < 1 then
    line_count = 1
  end
  if lnum > line_count then
    lnum = line_count
  elseif lnum < 1 then
    lnum = 1
  end

  col = math.max(col, 0)
  local line = ''
  if vim.api.nvim_buf_is_valid(buf) then
    line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ''
  end
  col = math.min(col, #line)

  return { lnum, col }
end

local function win_set_numbers(win, number, relativenumber)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  vim.wo[win].number = number
  vim.wo[win].relativenumber = relativenumber
end

local function buf_set_numbers(buf, number, relativenumber)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    pcall(win_set_numbers, win, number, relativenumber)
  end
end

local function win_disable_numbers_for_terminal(win, expected_buf)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  vim.api.nvim_win_call(win, function()
    local current_buf = vim.api.nvim_win_get_buf(win)
    if expected_buf ~= nil and current_buf ~= expected_buf then
      return
    end
    if not (current_buf and vim.api.nvim_buf_is_valid(current_buf) and vim.bo[current_buf].buftype == 'terminal') then
      return
    end

    if vim.w._snacks_term_saved_number == nil then
      -- Terminal windows often start with `nonumber` from Neovim defaults.
      -- For restoring to a normal buffer, use the global defaults instead of
      -- capturing the current terminal window state.
      vim.w._snacks_term_saved_number = vim.o.number
      vim.w._snacks_term_saved_relativenumber = vim.o.relativenumber
    end
    vim.wo.number = false
    vim.wo.relativenumber = false
  end)
end

local function win_restore_numbers_if_saved(win)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  vim.api.nvim_win_call(win, function()
    if vim.w._snacks_term_saved_number == nil and vim.w._snacks_term_saved_relativenumber == nil then
      return
    end
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
      return
    end
    vim.wo.number = vim.o.number
    vim.wo.relativenumber = vim.o.relativenumber
    vim.w._snacks_term_saved_number = nil
    vim.w._snacks_term_saved_relativenumber = nil
  end)
end

local function tab_restore_numbers_if_saved(tab)
  if not (tab and vim.api.nvim_tabpage_is_valid(tab)) then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == '' then
      win_restore_numbers_if_saved(win)
    end
  end
end

local function is_terminal_item(item)
  if not item then
    return false
  end
  if item.buftype == 'terminal' then
    return true
  end
  local buf = item.buf
  if buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
    return true
  end
  if type(item.name) == 'string' and item.name:match '^term://' then
    return true
  end
  if type(item.file) == 'string' and item.file:match '^term://' then
    return true
  end
  return false
end

local function buffers_transform(item)
  if is_terminal_item(item) then
    item.pos = nil
    return item
  end
  if item and item.buf and item.pos then
    item.pos = clamp_buf_pos(item.buf, item.pos)
  end
  return item
end

local function terminal_aware_jump(picker, item, action)
  local ok_selected, selected = pcall(function()
    return picker:selected { fallback = true }
  end)
  if ok_selected and type(selected) == 'table' then
    for _, it in ipairs(selected) do
      if is_terminal_item(it) then
        it.pos = nil
      elseif it and it.buf and it.pos then
        it.pos = clamp_buf_pos(it.buf, it.pos)
      end
    end
  end

  local cmd = action and action.cmd or 'edit'
  local origin_win = picker and picker.main or nil

  -- Special-case terminal buffers: don't set cursor positions, and prefer
  -- reusing an existing terminal window (Telescope-like behavior).
  local first = ok_selected and selected and selected[1] or nil
  if is_terminal_item(first) and first and first.buf and vim.api.nvim_buf_is_valid(first.buf) then
    local buf = first.buf
    vim.bo[buf].buflisted = true

    if picker.opts.jump and picker.opts.jump.close then
      picker:close()
    else
      vim.api.nvim_set_current_win(picker.main)
    end

    local current_tab = vim.api.nvim_get_current_tabpage()
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.api.nvim_win_is_valid(win) then
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == '' and vim.api.nvim_win_get_tabpage(win) == current_tab then
          vim.api.nvim_set_current_win(win)
          win_disable_numbers_for_terminal(win, buf)
          vim.schedule(function()
            win_disable_numbers_for_terminal(win, buf)
          end)
          return
        end
      end
    end

    local open_cmd = ({
      edit = 'buffer',
      split = 'sbuffer',
      vsplit = 'vert sbuffer',
      tab = 'tab sbuffer',
      drop = 'buffer',
      tabdrop = 'tab sbuffer',
    })[cmd] or 'buffer'

    vim.cmd(('%s %d'):format(open_cmd, buf))
    local win = vim.api.nvim_get_current_win()
    win_disable_numbers_for_terminal(win, buf)
    vim.schedule(function()
      win_disable_numbers_for_terminal(win, buf)
    end)
    return
  end

  local actions = require 'snacks.picker.actions'
  local ok, err = pcall(actions.jump, picker, item, action or {})
  if not ok then
    if type(err) == 'string' and err:match 'Cursor position outside buffer' then
      local retry_ok, retry_selected = pcall(function()
        return picker:selected { fallback = true }
      end)
      if retry_ok and type(retry_selected) == 'table' then
        for _, it in ipairs(retry_selected) do
          it.pos = nil
        end
      end
      ok, err = pcall(actions.jump, picker, item, action or {})
    end
  end
  if not ok then
    error(err)
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local opened_is_terminal = vim.bo[buf].buftype == 'terminal'

  if opened_is_terminal then
    win_disable_numbers_for_terminal(win, buf)
    vim.schedule(function()
      buf_set_numbers(buf, false, false)
      win_disable_numbers_for_terminal(win, buf)
    end)
    return
  end

  local post_tab = vim.api.nvim_get_current_tabpage()
  local post_win = win
  vim.schedule(function()
    -- Restore for the destination window, and also any other windows in the tab
    -- that were previously "terminal-styled" by Snacks.
    win_restore_numbers_if_saved(post_win)
    tab_restore_numbers_if_saved(post_tab)
  end)
  -- Some Lua callbacks may toggle window options after the jump; run again.
  vim.defer_fn(function()
    pcall(win_restore_numbers_if_saved, post_win)
    pcall(tab_restore_numbers_if_saved, post_tab)
  end, 10)
end

return {
  {
    'junyixu/snacks.nvim',
    priority = 1000,
    lazy = false,
    keys = {
      {
        '<leader>fh',
        function()
          require('snacks').picker.help()
        end,
        desc = '[F]ind [H]elp',
      },
      {
        '<leader>fk',
        function()
          require('snacks').picker.keymaps()
        end,
        desc = '[F]ind [K]eymaps',
      },
      {
        '<leader>ff',
        function()
          require('snacks').picker.files()
        end,
        desc = '[F]ind [F]iles',
      },
      {
        '<leader>fs',
        function()
          require('snacks').picker()
        end,
        desc = '[F]ind [S]elect Picker',
      },
      {
        '<leader>fw',
        function()
          require('snacks').picker.grep_word()
        end,
        desc = '[F]ind current [W]ord',
      },
      {
        '<leader>fg',
        function()
          require('snacks').picker.grep()
        end,
        desc = '[F]ind by [G]rep',
      },
      {
        '<leader>fd',
        function()
          require('snacks').picker.diagnostics()
        end,
        desc = '[F]ind [D]iagnostics',
      },
      {
        '<leader>fr',
        function()
          require('snacks').picker.resume()
        end,
        desc = '[F]ind [R]esume',
      },
      {
        '<leader>f.',
        function()
          require('snacks').picker.recent()
        end,
        desc = '[F]ind Recent Files ("." for repeat)',
      },
      {
        '<leader><leader>',
        function()
          require('snacks').picker.buffers()
        end,
        desc = '[ ] Find existing buffers',
      },

      {
        '<leader>/',
        function()
          require('snacks').picker.lines()
        end,
        desc = '[/] Fuzzily search in current buffer',
      },
      {
        '<leader>s/',
        function()
          require('snacks').picker.grep_buffers()
        end,
        desc = '[F]ind [/] in Open Files',
      },

      {
        '<leader>fn',
        function()
          require('snacks').picker.files { cwd = vim.fn.stdpath 'config' }
        end,
        desc = '[F]ind [N]eovim files',
      },
      {
        '<leader>fp',
        function()
          require('snacks').picker.files { cwd = vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy') }
        end,
        desc = '[F]ind Neovim [P]lug files',
      },
    },
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = false },
      input = { enabled = true },
      picker = {
        enabled = true,
        ---@type snacks.picker.matcher.Config
        matcher = {
          frecency = true, -- frecency bonus
        },
        actions = {
          confirm = terminal_aware_jump,
          jump = terminal_aware_jump,
        },
        sources = {
          buffers = {
            transform = buffers_transform,
            jump = { reuse_win = true },
          },
        },
      },
      notifier = { enabled = false },
      quickfile = { enabled = false },
      scope = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
      image = {
        enabled = vim.g.snacks_image_enabled,
        math = {
          enabled = true, -- enable math expression rendering
          -- in the templates below, `${header}` comes from any section in your document,
          -- between a start/end header comment. Comment syntax is language-specific.
          -- * start comment: `// snacks: header start`
          -- * end comment:   `// snacks: header end`
          typst = {
            tpl = [[
        #set page(width: auto, height: auto, margin: (x: 2pt, y: 2pt))
        #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
        #set text(size: 12pt, fill: rgb("${color}"))
        ${header}
        ${content}]],
          },
          latex = {
            font_size = 'large', -- see https://www.sascha-frank.com/latex-font-size.html
            -- for latex documents, the doc packages are included automatically,
            -- but you can add more packages here. Useful for markdown documents.
            packages = { 'amsmath', 'amssymb', 'mathrsfs','amsfonts', 'amscd', 'mathtools', 'braket' },
            tpl = [[
        \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
        \usepackage{${packages}}

        \makeatletter
        \renewenvironment{equation}{\begin{equation*}}{\end{equation*}}
        \makeatother

        \begin{document}
        ${header}
        { \${font_size} \selectfont
          \color[HTML]{${color}}
        ${content}}
        \end{document}]],
          },
        },
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          float = true,
          inline = false,
          max_width = 100,
          max_height = 60,
        },
      },
      words = { enabled = false },
    },
  },
}

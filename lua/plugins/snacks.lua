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
            packages = { 'amsmath', 'amssymb', 'amsfonts', 'amscd', 'mathtools', 'braket' },
            tpl = [[
        \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
        \usepackage{${packages}}
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

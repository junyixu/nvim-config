return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {},
    keys = {
      {
        's',
        mode = { 'n', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      {
        'S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
    },
    config = function(_, opts)
      -- 在 fugitive 的 gitrebase 界面或 git 相关缓冲区中，cS 通常用于 autosquash 或切换 commit 状态，
      -- 而 flash.nvim 将 S 绑定到 operator-pending mode (o) 后，
      -- 当你按下 c 准备接 S 时，Neovim 会优先触发 flash 的远程逻辑。
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'fugitive', 'gitrebase', 'floggraph' },
        callback = function()
          -- 针对当前 buffer 删除 S 的映射
          -- 这样 cS 就能正常触发 fugitive 的功能了
          pcall(vim.keymap.del, { 'n', 'x', 'o' }, 'S', { buffer = true })
        end,
      })
    end,
  },
}

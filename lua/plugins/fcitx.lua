return {
  {
    'junyixu/fcitx.nvim',
    lazy = false,
    priority = 1000,
    cond = function()
      local ok, ldbus = pcall(require, 'ldbus')
      if not ok then
        return false
      end
      local ok_conn, conn = pcall(ldbus.bus.get, 'session')
      return ok_conn and not not conn
    end,
    config = function()
      require('fcitx').setup {
        -- enable_cmdline = true, -- also toggle when entering / or ?
      }
    end,
  },
}

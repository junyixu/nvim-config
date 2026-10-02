return {
  "nvzone/typr",
  enabled = vim.g.full,
  dependencies = { "nvzone/volt" },
  cmd = { "Typr", "TyprStats" },
  opts = {
    mode = "phrases",
    phrases = require("junyi.typr_craft_of_research"),
  },
  config = function(_, opts)
    -- Upstream bug: save_str_tofile wraps the JSON stats blob in a Lua
    -- single-quoted string with no escaping. char_accuracy/char_times are
    -- keyed by every typed character, so a corpus with real prose (which
    -- has apostrophes, unlike the stock word/phrase lists) breaks the
    -- generated Lua source and crashes on every test finish.
    -- https://github.com/nvzone/typr/blob/main/lua/typr/stats/utils.lua#L39-L47
    require("typr.stats.utils").save_str_tofile = function(tb)
      local state = require "typr.state"
      local str = string.format("%q", vim.json.encode(tb))
      local data = "return string.dump(function()return" .. str .. "end, true)"
      local file = io.open(state.config.stats_filepath, "wb")
      file:write(loadstring(data)())
      file:close()
    end

    require("typr").setup(opts)
  end,
}

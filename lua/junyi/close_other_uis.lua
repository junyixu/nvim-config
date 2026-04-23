local M = {}

function M.close_other_uis(opts)
  opts = opts or {}
  local uis = vim.api.nvim_list_uis()
  if #uis <= 1 then
    vim.notify("only one UI attached, nothing to close", vim.log.levels.INFO)
    return
  end

  -- 策略：保留 opts.keep（channel id），否则保留列表中最后一个
  local keep = opts.keep or uis[#uis].chan

  for _, ui in ipairs(uis) do
    local chan = ui.chan
    if chan ~= keep and chan ~= 1 then  -- 永远不碰 channel 1 (stdio)
      local ok, err = pcall(vim.fn.chanclose, chan)
      if ok then
        vim.notify(("closed UI on channel %d"):format(chan), vim.log.levels.INFO)
      else
        vim.notify(("failed to close channel %d: %s"):format(chan, err), vim.log.levels.WARN)
      end
    end
  end
end

return M

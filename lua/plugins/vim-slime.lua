-- jpalardy/vim-slime – send code to REPLs

return {
  'jpalardy/vim-slime',
  init = function()
    vim.g.slime_target = 'neovim'
  end,
  config = function()
    vim.g.slime_suggest_default = true
    vim.g.slime_menu_config = false
    vim.g.slime_input_pid = false

    local function slime_send_largest_ts_obj()
      local target_types = {
        compound_statement = true,
        let_statement = true,
        function_definition = true,
        struct_definition = true,
      }

      local node
      if vim.treesitter.get_node then
        local ok, ts_node = pcall(vim.treesitter.get_node, { ignore_injections = true })
        if ok then
          node = ts_node
        end
      else
        local ok, parser = pcall(vim.treesitter.get_parser, 0)
        if ok and parser then
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local tree = parser:parse()[1]
          if tree then
            node = tree:root():named_descendant_for_range(row - 1, col, row - 1, col)
          end
        end
      end

      if not node then
        vim.cmd 'SlimeSend'
        return
      end

      local best = nil
      while node do
        if target_types[node:type()] then
          best = node
        end
        node = node:parent()
      end

      if not best then
        vim.cmd 'SlimeSend'
        return
      end

      local start_row, start_col, end_row, end_col = best:range()
      local lines = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
      local text = table.concat(lines, '\n')
      if text == '' then
        return
      end
      if text:sub(-1) ~= '\n' then
        text = text .. '\n'
      end
      vim.fn['slime#send'](text)
    end

    vim.keymap.set('n', '<space><space>', '<Plug>SlimeMotionSend', { remap = true, desc = 'Slime: Send Motion' })
    vim.keymap.set('n', '<space><space><space>', slime_send_largest_ts_obj, { desc = 'Slime: Send Largest TS Obj' })
    vim.keymap.set('n', '<space><space>p', '<Plug>SlimeParagraphSend', { remap = true, desc = 'Slime: Send Paragraph' })
    vim.keymap.set('v', '<space><space>', '<Plug>SlimeRegionSend', { remap = true, desc = 'Slime: Send Region' })
    vim.keymap.set('n', '<space><space>c', '<Plug>SlimeConfig', { remap = true, desc = 'Slime: Configure Target' })
  end,
}

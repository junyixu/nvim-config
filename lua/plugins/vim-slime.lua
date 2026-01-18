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
    vim.g.slime_collapse_blank_lines = 1

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

      -- 转换 <Plug> 序列
      local sendParagraph = vim.api.nvim_replace_termcodes('<Plug>SlimeParagraphSend', true, true, true)

      -- 使用 'm' 模式 (remap) 来确保 <Plug> 能够被正确解析执行

      if not node then
        vim.api.nvim_feedkeys(sendParagraph, 'm', true)
        return
      end

      local best = nil
      -- If the cursor is *already* on a target node, send it immediately instead of
      -- walking up and potentially selecting a larger surrounding block.
      -- TODO:
      -- 也许有更简洁的逻辑
      -- 或许我应该写两个 target_types, 一个是可以直接发送的节点类型
      -- 另一个是可以继续向上查找的节点类型
      while node do
        if target_types[node:type()] then
          best = node
          break
        end
        node = node:parent()
      end

      if not best then
        vim.api.nvim_feedkeys(sendParagraph, 'm', true)
        return
      end

      local start_row, _, end_row, _ = best:range()
      local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, true)
      local text = table.concat(lines, '\n')
      if text == '' then
        return
      end
      if text:sub(-1) ~= '\n' then
        text = text .. '\n'
      end
      vim.fn['slime#send'](text)
    end

    vim.keymap.set('n', '<space>f', '<Plug>SlimeMotionSend', { remap = true, desc = 'Slime: Send Motion' })
    vim.keymap.set('n', '<space><space>', slime_send_largest_ts_obj, { desc = 'Slime: Send Largest TS Obj' })
    vim.keymap.set('n', '<space>fp', '<Plug>SlimeParagraphSend', { remap = true, desc = 'Slime: Send Paragraph' })
    vim.keymap.set('v', '<space>f', '<Plug>SlimeRegionSend', { remap = true, desc = 'Slime: Send Region' })
    vim.keymap.set('n', '<space>fc', '<Plug>SlimeConfig', { remap = true, desc = 'Slime: Configure Target' })
  end,
}

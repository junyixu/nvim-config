vim.keymap.set('i', '<CR>', function()
  local ok, mod = pcall(require, 'custom.markdown_smart_cr')
  if not ok then
    return vim.api.nvim_replace_termcodes('<CR>', true, false, true)
  end
  return mod.smart_cr()
end, { expr = true, buffer = true, silent = true })

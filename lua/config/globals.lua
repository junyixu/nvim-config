-- Global variables (vim.g.*)
-- NOTE: Leader keys must be set before plugins are loaded.
vim.g.mapleader = ','
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Cached environment checks (avoid repeated feature/env probing elsewhere).
vim.g.is_wsl = vim.fn.has 'wsl' == 1 or vim.env.WSL_DISTRO_NAME ~= nil or vim.env.WSL_INTEROP ~= nil

vim.g.has_wl_copy = vim.fn.executable 'wl-copy' == 1

-- Whether to enable special Unicode characters in the commit graph.
-- Currently supported by the Kitty terminal.
vim.g.flog_enable_extended_chars = true

vim.g.snacks_image_enabled = true

vim.g.copilot_filetypes = {
  xml = false,
  markdown = false,
  julia = true,
}

vim.g.slime_python_ipython = 1

pcall(vim.fn.mkdir, vim.fn.stdpath 'cache', 'p')
pcall(vim.fn.mkdir, vim.fn.stdpath 'state', 'p')
pcall(vim.fn.mkdir, vim.fn.stdpath 'log', 'p')

require 'config.globals'
require 'config.options'
require 'config.commands'
require 'config.autocmds'
require 'config.keymaps'

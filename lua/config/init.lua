local mkdir = vim.fn.mkdir
local stdpath = vim.fn.stdpath

pcall(mkdir, stdpath 'cache', 'p')
pcall(mkdir, stdpath 'state', 'p')
pcall(mkdir, stdpath 'log', 'p')

require 'config.globals'
require 'config.options'
require 'config.commands'
require 'config.autocmds'
require 'config.templates'
require 'config.keymaps'
require 'config.lsp'

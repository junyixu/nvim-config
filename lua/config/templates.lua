local group = vim.api.nvim_create_augroup('UserLoadTemplates', { clear = true })

vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = '*.py',
  -- $ 表示跳转到最后一行
  command = '0read ~/.config/nvim/templates/skeleton.py | $',
})

vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = '*.sh',
  -- $ 表示跳转到最后一行
  command = '0read ~/.config/nvim/templates/skeleton.sh | $',
})

-- C/C++ files
vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = '*.c',
  command = '0read ~/.config/nvim/templates/skeleton.c | $',
})

vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = '*.h',
  command = '0read ~/.config/nvim/templates/skeleton.h | 10',
})

-- Makefile
vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = 'Makefile',
  command = '0read ~/.config/nvim/templates/skeleton.Makefile | $',
})

-- CMake
vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = 'CMakeLists.txt',
  command = '0read ~/.config/nvim/templates/skeleton.CMakeLists.txt | $',
})

-- LaTeX
vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = '*.tex',
  command = '0read ~/.config/nvim/templates/skeleton.tex',
})

vim.api.nvim_create_autocmd('BufNewFile', {
  group = group,
  pattern = '.latexmkrc',
  command = '0read ~/.config/nvim/templates/skeleton.latexmkrc | 11',
})

return {
  'mfussenegger/nvim-lint',
  ft = { 'matlab', 'sh' },
  config = function()
    local lint = require 'lint'

    -- 只注册本机已安装的 linter（VPS/docker 精简环境下自动禁用）
    lint.linters_by_ft = {}
    for ft, linter in pairs { matlab = 'mlint', sh = 'shellcheck' } do
      if vim.fn.executable(linter) == 1 then
        lint.linters_by_ft[ft] = { linter }
      end
    end
    if vim.tbl_isempty(lint.linters_by_ft) then
      return
    end

    -- 设置 autocmd 触发 lint
    -- 你可以根据需要选择触发时机：写入后、进入 buffer 后、离开 insert mode 后
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}

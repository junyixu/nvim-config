# Tree-sitter indent 与缩进策略

## 背景

- 在 `lua/plugins/lsp.lua` 等 Lua 文件里按 `o` 新增行时，indent 会突然变得很深，与周围缩进不一致。
- `~/WorkSpace/test_Makie/anim.jl` 中第 57 行和 58 行肉眼看齐，但 58 行是按 `o` 插入的，内部实际是一个 `Tab` 字符。
- Python 文件表现正常，因为 `ftplugin/python.vim` 在缓冲区里 `setlocal expandtab`，无论 indentexpr 怎么算，最终都插入空格而不是 `Tab`。

## 问题根源

1. `nvim-treesitter` 会为很多语言注册 Tree-sitter 驱动的 indentexpr。Lua/Julia 默认启用了该模块。
2. indentexpr 只决定“缩进层级”，不会关心 `Tab` 还是空格。当 `expandtab` 关闭时，Neovim 会按照 `shiftwidth` 个列宽写入真实 `Tab`。
3. 你的 formatter（Lua 使用 stylua，Julia 使用 VSCode 默认规则）生成的是纯空格，因此当 Tree-sitter 触发自动 indent 时，就出现“表面一样但实际不同”的缩进。

## 当前方案

### Lua

- 在 `lua/plugins/nvim-treesitter.lua` 中把 Lua 加入 `indent.disable`，让 Lua 回退到 Neovim 内置 indentexpr，避免 Tree-sitter 计算过度的层级。
- 在 `ftplugin/lua.lua` 中强制 `expandtab = true` 且 `shiftwidth = softtabstop = 2`，保证自动缩进写入空格。

> 之前的配置示例（已删除，但保留做法）：  
> ```lua
> additional_vim_regex_highlighting = { 'ruby', 'lua' },
> indent = { enable = true, disable = { 'ruby', 'lua' } },
> ```  
> 当某个语言（如 Lua）也需要回退到 Vim 的 indent 逻辑时，把它和 Ruby 一样加入这两个列表即可。

### Julia

- 在 `ftplugin/julia.vim` 顶部补上注释和 `setlocal expandtab shiftwidth=4 softtabstop=4`，与 formatter 输出保持一致。

## 其他可选方案

1. **自定义 indent 查询**  
   在 `after/queries/<lang>/indents.scm` 下放置重写后的 Tree-sitter 查询，微调 indent 逻辑，但成本较高。
2. **自定义 indentexpr**  
   例如 `ftplugin/lua.vim` 中设置 `vim.bo.indentexpr = 'GetLuaIndent()'`，让 Vimscript 的缩进函数接管。
3. **临时禁用**  
   可在 buffer 内运行 `:TSBufDisable indent` 快速排查是否是 Tree-sitter 导致。

## 建议

- 需要 Tree-sitter indent 的语言，确保有对应的 `ftplugin` 把 `expandtab` 设置为期望值，避免混用 `Tab` 与空格。
- 如果发现特定语言依旧 indent 过深，优先把该语言加入 `indent.disable`，再考虑编写自定义查询。

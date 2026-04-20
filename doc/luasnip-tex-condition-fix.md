# LuaSnip tex snippet 条件修复

## 问题

tex 文件中，数学 snippet 在非数学环境也触发。`is_math()` 命令行测试正常，但 LuaSnip 不检查条件。

## 根因

LuaSnip 在 **snippet 创建时** 把条件封进 `resolveExpandParams` 闭包：

```lua
-- nodes/snippet.lua:273
effective_context.resolveExpandParams = generate_resolve_expand_params_func(
    context.condition or opts.condition,  -- 创建时读取，之后不再看
    ...
)
```

创建后再赋值无效：

```lua
-- 这两行什么都没做
snip.condition = is_math
snip.show_condition = is_math
```

## 修复

`greeks_snipets` 和 `math_snipets` 改用 decorator 版本，条件在创建时注入：

| 旧 | 新 | 位置 |
|---|---|---|
| `parse(` | `parse_math(` | greeks_snippets + math_snippets |
| `s(` | `maths(` | math_snippets |
| 死代码 for 循环 | 删除 | greeks_snippets + math_snippets |

`parse_math` / `maths` 通过 `extend_decorator` 把 `condition = pipe { is_math, no_backslash }` 注入每个 snippet 的构造参数，绕过上述限制。

`origin_snippets` 不动——已在构造时传入 condition（`condition = is_math` 写在 `s({...})` 第一参数里）。

## treesitter 配置

tex 文件需要 latex parser 运行，`in_mathzone()` 才能查询节点。`treesitter.lua` FileType autocmd 对 tex 调用 `vim.treesitter.get_parser(bufnr, 'latex')` 启动 parser，但不启动 highlighter（vimtex 管高亮）。

## 插件脉络

- 插件：`iurimateus/luasnip-latex-snippets.nvim`，在 `lua/plugins/luasnip-latex-snippets.lua` 里通过 `require('luasnip-latex-snippets').setup { use_treesitter = true, allow_on_markdown = true }` 注册。
- 触发条件：所有 snippet 都包在 `ls.add_snippets(..., { type = 'autosnippets' })`，配合 `enable_autosnippets = true` (见 `lua/plugins/LuaSnip.lua`) 才能自动展开。
- Treesitter 检测：`util/utils.lua` 提供 `is_math` / `not_math` / `no_backslash` 等条件函数，用来区分数学环境、普通文本、或是否已经输入 `\`。

## 主要分类

| 文件 | 作用 | 条件 |
| --- | --- | --- |
| `math_i.lua` | 数学环境内的常规 snippet（需手动 `<Tab>` 展开） | `is_math` |
| `math_iA.lua` | 数学环境内的 autosnippet，支持正则触发（如 `(%a+)hat`） | `is_math` + `no_backslash` |
| `math_iA_no_backslash.lua` | 只匹配纯触发词（`hat`、`bar` 等），同样要求 math + `no_backslash` | `is_math` + `no_backslash` |
| `math_wA_no_backslash.lua` 等 | 文本环境 autosnippet，禁止数学上下文 | `not_math` |
| `wA.lua` / `bwA.lua` | Markdown 普通文本，用来提供 `mk`、`dm` 等定界符 snippet | `not_math` |

## `hat` / `bar` 的用法

插件里同时提供了两种触发方式：

1. `math_iA.lua:15-70` 中的**正则 autosnippet**：
   ```lua
   s({
     trig = "(%a+)hat",
     regTrig = true,
     wordTrig = false,
     condition = pipe({ is_math, no_backslash }),
   }, f(function(_, snip)
     return string.format("\\hat{%s}", snip.captures[1])
   end))
   ```
   - 触发方式：在数学环境中直接把变量名和 `hat` 连写，如输入 `vhat`、`ABhat`，一旦检测到末尾的 `hat` 就会自动替换成 `\hat{v}` / `\hat{AB}`。
   - `no_backslash` 会阻止在已经输入 `\hat` 的情况下重复展开。

2. `math_iA_no_backslash.lua:9-25` 中的**简单 autosnippet**：
   ```lua
   with_priority({ trig = "hat", name = "hat" }, "\\hat{$1}$0 ")
   ```
   - 触发方式：在数学环境里单独敲 `hat`（不带前缀），LuaSnip 会直接展开成 `\hat{•}` 并把光标放在花括号内部。
   - 适合没有现成符号要包裹的情况，可以先输入 `hat` 展开，再填内容。

`bar`、`ora`、`ola`、`dot` 等都遵循同样的双路线：正则版本 `(字符 + 关键字)` 自动包裹已有变量；纯文本版本提供空壳模板。

## 示例

在 Markdown 数学块或 LaTeX 文档中：

| 输入 | 环境 | 结果 |
| --- | --- | --- |
| `xhat` | math 环境 | 自动替换成 `\hat{x}` |
| `uvbar` | math 环境 | 变为 `\overline{uv}` |
| `hat` `<Tab>`（或等待 autosnippet） | math 环境 | 生成 `\hat{•}`，光标位于花括号内 |
| `mk` | 普通文本 | 由于 `wA.lua`，在 Markdown 中自动生成 `$ … $`，把选区或光标包进行内公式 |
| `dm` | 普通文本 | 生成 `$$ ... $$` (或 `\[\]`，取决于当前 filetype) |

请注意：

- 所有 `math_*` snippet 都要求 Treesitter 判定当前在 math zone，因此在 code block 或 `\text{}` 里不会触发。
- `no_backslash` 条件意味着触发词前面不能已有 `\` 或字母序列如 `\hat`，这样可以避免和手动输入的命令冲突。
- `regTrig = true` 的 snippet（如 `(%a+)hat`）会吃掉整个匹配串并返回格式化后的 LaTeX，属于“打完词立刻自动改写”的风格；如果不想让它自动触发，可以通过 `:LuaSnipEdit` 找到对应 snippet 并改成普通 `trig`。

## 如何查找其它 snippet

1. 在仓库中搜索触发词：`rg -n '"mk"' lua/luasnip-latex-snippets`.
2. 打开对应文件，例如 `math_wrA.lua` 里还有 `frac` 等自动分数模板。
3. 结合 `util/utils.lua` 可以理解它的 `condition` 限制，从而知道要在什么环境下输入才能触发。

这样就能快速定位插件自带的 LaTeX snippet，并知道像 `hat`/`bar` 这类“看见但不会用”的触发方式。***

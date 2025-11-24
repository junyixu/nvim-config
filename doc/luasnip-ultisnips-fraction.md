## 背景

- 需求：把 UltiSnips 中的 Python snippet `'^.*\)/'` 迁移到 LuaSnip，并放到 `lua/luasnippets/markdown.lua`。
- 目标行为：在 LaTeX 数学环境里，输入 `(foo)/` 或 `a_1/`、`1/` 时自动展开成 `\frac{...}{•}`，尖括号位置开插入点。

## 实现过程

1. **环境分析**：Neovim 已加载 `luasnip-latex-snippets.util.ts_utils`，因此可以直接使用 `ts_utils.in_mathzone` 做 condition / show_condition。
2. **括号场景 (UltiSnips #12)**：
   - 需要从正则捕获中找到和末尾 `/` 匹配的 `()` 内容。
   - LuaSnip 没有 `snip.rv`，改用 `dynamic_node` + `snippet_node` 返回一串 `text_node`/`insert_node`。
   - Python 原代码通过 `match.string` 操作字符串，我在 `lua/luasnippets/markdown.lua:11-48` 实现 `paren_fraction` 函数，复用 depth 计数回溯逻辑：
     ```lua
     local function paren_fraction(_, snip)
       local stripped = snip.captures[1] or ''
       -- 反向扫描，depth 回到 0 时找到 '('
       local depth, idx = 0, #stripped
       while idx > 0 do
         local char = stripped:sub(idx, idx)
         if char == ')' then depth = depth + 1
         elseif char == '(' then depth = depth - 1 end
         if depth == 0 then break end
         idx = idx - 1
       end
       local prefix = stripped:sub(1, idx - 1)
       local numerator = stripped:sub(idx + 1, #stripped - 1)
       return sn(nil, { t(prefix .. '\\frac{' .. numerator .. '}{'), i(1), t '}', i(0) })
     end
     ```
   - snippet 本体定义（`lua/luasnippets/markdown.lua:60-73`）：
     ```lua
     s({
       trig = '(^.*\\))/',
       regTrig = true,
       trigEngine = 'ecma',
       snippetType = 'autosnippet',
     }, {
       d(1, paren_fraction),
     }, {
       condition = is_math,
       show_condition = is_math,
     }),
     ```
3. **符号/数字场景 (UltiSnips #13)**：
   - 原 UltiSnips 用正则捕获数字或 `\alpha`, `a_1`, `x^2` 等，然后直接 `snip.rv` 输出。
   - LuaSnip 版在 `lua/luasnippets/markdown.lua:88-104` 里新增第二个 autosnippet：
     ```lua
     s({
       trig = [[((\d+)|(\d*)(\\)?([A-Za-z]+)((\^|_)(\{\d+\}|\d))*)/]],
       regTrig = true,
       trigEngine = 'ecma',
       snippetType = 'autosnippet',
     }, {
       t '\\frac{',
       f(function(_, snip) return snip.captures[1] or '' end),
       t '}{',
       i(1),
       t '}',
       i(0),
     }, {
       condition = is_math,
       show_condition = is_math,
     }),
     ```

## 遇到的困难

- **Regex 语法不同**：Lua 默认使用 Lua pattern，无法解析 `\d`、分组等。通过 `trigEngine = 'ecma'` 强制 LuaSnip 按 ECMAScript 正则来匹配，才能兼容原 Python 正则。
- **Dynamic output vs. `snip.rv`**：UltiSnips 的 Python block 可以修改 `snip.rv`。LuaSnip 需要用 `function_node` 或 `dynamic_node` 返回节点树。括号场景必须动态拼接 `prefix + \frac{...}{...}` + 插入点，所以选 `dynamic_node`。
- **触发覆盖范围**：初版只处理 `(...)/`，导致 `1/2` 不触发。根据 issue 里 evesdropper 的提示，又补了符号正则 snippet。

## 容易混淆的点

- `regTrig` vs `trigEngine`：`regTrig = true` 只表示“使用正则”。若不指定 `trigEngine`，默认是 LuaSnip 的 PCRE2-Lua 简化版（兼容性有限）。要复现 Python regex，最好显式设置 `trigEngine = 'ecma'`。
- `snip.captures` 的下标：Lua 1-based；UltiSnips/Python 0-based。如果直接照搬 `match.group(1)` 等价，就要写 `snip.captures[1]`。
- `dynamic_node` 的返回值必须是 `snippet_node`，不能直接返回字符串；否则会报错或什么都不做。

## 结果

在 math zone 输入 `(1+2)/` 或 `x_1/` 会立即展开：

```
(1+2)/    →  \frac{1+2}{•}
x_1/      →  \frac{x_1}{•}
```

效果与原 UltiSnips 一致，且用户进一步确认 `(1)/2`、`1/2` 均能触发。

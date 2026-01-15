# Julia stacktrace：在 terminal 里用 `gF` 打开 `@ file:line`

## 需求背景

Julia 的 stacktrace 常见格式是 `@ 文件路径:行号`，例如：

```text
  [17] top-level scope
    @ ~/WorkSpace/test_Makie/35.jl:91
```

我希望在 Neovim 的 terminal split 里，把光标移动到这一行，然后按一次键就能：

1. 在“正常编辑的那个窗口”里打开对应文件
2. 跳到对应行号
3. 默认不要把 terminal 窗口替换掉（保留 terminal，去另一个窗口开文件）
4. 不改动全局 `gF/gf` 的默认行为（只在 terminal buffer 里增强）

最终方案选择增强 `gF`（因为 `gF` 天生支持 `file:line` 的语义）。

---

## `flatten.nvim` 的“在当前 nvim 打开文件”原理（简述）

`flatten.nvim` 解决的是：当你在一个 Neovim 里的 terminal 中运行 `nvim file` 时，避免出现“嵌套的 Neovim UI”（nested session）。

核心思路是“host/guest”：

- 已经在跑的 Neovim 是 **host**
- 从 terminal 启动的那个 `nvim ...` 是 **guest**
- Neovim 在 terminal 环境里会设置 `NVIM` 环境变量（指向 host 的 server 地址）
- `flatten.nvim` 在 guest 启动时检测 `vim.env.NVIM`（或其他 pipe 路径），判断自己应当连接到 host
- guest 把 argv（文件、`+cmd`、`--cmd` 等）通过 RPC 发送给 host，由 host 来执行“开文件/执行命令/选窗口”等逻辑
- guest 根据配置决定是否阻塞等待（例如 git commit），否则立刻退出

所以从用户体验上看：你在 terminal 里“运行了 nvim”，但实际上文件是在**已有的 Neovim 实例**里打开的。

---

## 本配置实现：只在 terminal buffer 里增强 `gF`

这里的目标更窄一些：不是拦截命令行 `nvim`，而是直接在 terminal buffer 内解析 stacktrace 行，并在现有窗口里 `:edit` + 跳转。

实现由三块组成：

1. `lua/util/julia_stacktrace.lua`：解析一行文本里的 `path:line`，并按策略打开文件
2. `lua/config/autocmds.lua`：`TermOpen` 时给 terminal buffer 设置 **buffer-local** 的 `gF` 映射
3. `lua/config/commands.lua`：提供 `:JuliaStackOpen` 方便手动验证

### 使用方式

- 在 terminal buffer 进入“普通模式”（terminal-normal mode，例如 `<C-\\><C-n>`）
- 光标放在包含 `@ ...file:line` 的那一行
- 按 `gF`

行为：

- 如果当前行能解析出 Julia 的 `file:line`：在目标窗口打开文件并跳转
- 否则：回退到 Neovim 内置 `gF`（不改变原生行为）

---

## 识别哪些 Julia 行

当前解析覆盖的典型格式：

- `@ Main ~/WorkSpace/foo.jl:91`
- `@ ~/WorkSpace/foo.jl:91 [inlined]`
- `@ Contour ~/.julia/.../Contour.jl:74`
- `in expression starting at /abs/path/foo.jl:129`

会做的“路径清理”：

- 支持 `~`（通过 `vim.fn.expand()` 展开）
- 会忽略行内其他字段（如 `[inlined]`）

---

## 窗口策略：默认“在 alternate 窗口里 split 再开文件”

本配置的默认打开策略是 `alternate_split`：

1. 先选一个“目标窗口”：
   - 优先使用 alternate window（`winnr('#')`，类似 flatten 的 `window.open = "alternate"`）
   - 否则选当前 tab 里任意一个普通 buffer 窗口（跳过浮窗/特殊 buftype）
2. 切到目标窗口后，对它执行一次 `:split`（把原来的 alternate 窗口分成两个）
3. 在新 split 中 `:edit {file}` 并跳到行号

这样做的效果是：

- terminal 仍然留在原窗口
- 原来的 alternate 窗口内容也保留在其中一个 split
- 新 split 用来打开 stacktrace 指向的源码位置

---

## 手动命令（可选）

`lua/config/commands.lua` 里提供了：

- `:JuliaStackOpen`：对当前行执行同样的解析与打开逻辑

主要用于调试/验证，不是必须功能。

---

## 限制与可改进点

- 路径里包含空格时，当前的匹配规则可能识别失败（模式用的是“非空白连续字符”）
- `./none:0` 之类的 Julia 内部占位位置会被忽略（它也没有实际可打开的文件）
- 当前 fallback 直接执行内置 `gF`：这会遵循原生 `gF` 的窗口策略（我们刻意不动它）


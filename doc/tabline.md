# Tabline（自定义）

这个配置实现了一个很简单的 tabline：

- 每个 tab 前显示序号：`1.` / `2.` / ...（配合 `<M-1..9>` 快速切 tab）
- 每个 tab 后显示窗口信息：`[当前窗口/总窗口]`（仅当总窗口 > 1 时显示）
- 路径显示规则：
  - 如果文件在该 tab 的 `cwd` 内：显示相对路径（例如 `lua/plugins/mini.lua`）
  - 如果文件不在该 tab 的 `cwd` 内：显示缩写路径（每级目录取首字母，`.` 开头目录保留 `.` + 首字母），例如 `~/.l/s/n/l/g/t/hunk_spec.lua`
- 只有 1 个 tab 时不显示 tabline

## 相关文件

- 实现：`lua/custom/tabline.lua`
- 启用：`lua/config/options.lua`（调用 `require('custom.tabline').setup()`）
- 快捷键：`lua/config/keymaps.lua`（`<M-1..9>`）

## 显示格式

每个 tab 大致长这样：

```
{tab_index}. {title}{win_status}
```

示例：

- `1. init.lua`
- `2. lua/plugins/mini.lua [3/5]`

其中：

- `[3/5]`：`3` 表示当前窗口在该 tab 的“真实分屏窗口”序号，`5` 表示真实分屏窗口总数。

## 为什么不用 `tabpagewinnr()` 计数

你可能会遇到这种现象：明明肉眼只看到 3 个 split，但 tabline 显示 `[3/5]`。

这通常是因为某些插件（例如 `flash.nvim`、LSP hover、某些提示 UI）会临时创建浮动窗口。
`tabpagewinnr(tabnr, '$')` 在某些时刻可能把这些也算进去，从而导致计数偏大。

为了解决这个问题，这个 tabline 的窗口统计使用：

- `vim.fn.winlayout(tabnr)` 获取该 tab 的窗口布局树
- 只统计其中的 `leaf` 节点（也就是分屏布局里的“真实窗口”）

这样可以自然地排除浮动窗口/临时窗口的干扰。

## 路径显示规则

标题（title）遵循以下规则：

1. 非文件系统路径（例如某些特殊 buffer 名字不是以 `/` 开头）：只显示 basename。
2. 文件路径在该 tab 的 `cwd` 内：显示相对路径（相对 `tab_cwd`）。
3. 文件路径不在该 tab 的 `cwd` 内：显示缩写绝对路径：
   - `$HOME` 前缀显示为 `~`
   - 每级目录取首字母
   - 以 `.` 开头的目录显示为 `.` + 首字母（例如 `.local` → `.l`）

## 高亮（Tokyonight / mini.tabline 风格）

虽然我们没有启用 `mini.tabline` 插件本身，但为了更好地和 Tokyonight 配色融合，tabline 会：

- 优先使用 `MiniTablineCurrent` / `MiniTablineVisible` / `MiniTablineFill` 这些高亮组（如果它们存在）
- 否则回退到默认的 `TabLineSel` / `TabLine` / `TabLineFill`

Tokyonight 通常会在检测到 `mini.nvim` 时自动提供这些 `MiniTabline*` 高亮组。

## 快捷键

为了快速切换 tab：

- `Alt+1` → 第 1 个 tab
- `Alt+2` → 第 2 个 tab
- ...
- `Alt+9` → 第 9 个 tab

注意：不同终端对 `Alt+数字` 的支持不完全一致；如果你的终端不发送 `<M-1>` 这类按键码，需要换终端/改映射。

## 常见自定义

- 想在只有 1 个 tab 时也显示 tabline：把 `vim.o.showtabline` 改回 `2`。
- 想让窗口后缀在 `1` 个窗口时也显示：修改 `tab_win_status_suffix()` 的 `if #wins <= 1 then return '' end`。
- 想完全禁用缩写路径：在 `tab_title()` 里直接返回相对路径或 basename。


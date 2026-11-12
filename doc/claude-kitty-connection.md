# claude_kitty：`kitty @` 连到哪个 kitty

`lua/custom/claude_kitty.lua` 通过 `kitty @ --to <addr>` 把 markdown 发给 kitty 里的
Claude Code 等 agent。本文记录 `<addr>` 的选择逻辑，以及这样设计的原因。

## 结论

`kitty()` 按以下顺序决定 `--to`：

| 场景 | 判定 | `--to` | 超时 |
| --- | --- | --- | --- |
| Windows 上的 `neovide --wsl` | `vim.g.neovide and vim.g.is_wsl` | `NEOVIDE_KITTY`（经 tailscale 连 archsurface 的 TCP 地址） | 3 s |
| 在 kitty 里运行的 nvim / neovide | `KITTY_LISTEN_ON` 非空 | `KITTY_LISTEN_ON` | 无 |
| 从 Linux 桌面启动器打开的 neovide | 以上都不满足且 `vim.g.neovide` | `/tmp/kitty-*` 中最新的 socket | 无 |
| 其他 | — | 不加 `--to`（交给 kitty 自己判断） | 无 |

## 为什么用 `is_wsl` 而不是只看 `vim.g.neovide`

以前只要是 neovide 就连 `NEOVIDE_KITTY`。但 Linux 桌面上也会用 neovide，这时要控制的是本机 kitty，
不是 archsurface 上的。所以“连远端 kitty”的条件收紧为 neovide **且** WSL（`lua/config/globals.lua`
里的 `vim.g.is_wsl`）。

从 Windows 启动器打开 `neovide --wsl` 时，nvim 运行在 WSL 里，同样没有 `KITTY_LISTEN_ON`，
但这条路径直接用写死的 `NEOVIDE_KITTY`，不受影响。

## 为什么要 glob `/tmp/kitty-*`

从桌面启动器打开的 neovide 不是 kitty 的子进程，不会继承 `KITTY_LISTEN_ON`。

而 kitty.conf 里的 `listen_on` 拿不到固定路径。kitty 0.49 的 `kitty.conf(5)` 原文：

> If `{kitty_pid}` is present, then it is replaced by the PID of the kitty process, otherwise the PID
> of the kitty process is appended to the value, with a hyphen.

所以 `listen_on unix:/tmp/kitty` 实际生成的是 `/tmp/kitty-8451` 这样的路径。
这是为了避免多个 kitty 实例抢同一个 socket。

`newest_kitty_socket()` 的做法：

- glob `/tmp/kitty-*`，只保留 `fs_stat(...).type == 'socket'` 的项，
  以排除同名前缀的普通文件（比如 `/tmp/kitty-paste-probe.py`）；
- 取 mtime 最新的一个，加 `unix:` 前缀返回。

## 已知限制

- **开了多个 kitty**：socket 的 mtime 基本等于 kitty 的启动时间，所以连的是最后启动的 kitty，
  不一定是正在用的那个。之后的窗口选择列表也只包含这个 kitty 里的窗口。
- **残留 socket**：kitty 崩溃后 `/tmp/kitty-PID` 可能还在，类型仍是 socket。若它恰好最新，
  `kitty @` 会连接失败，删掉该文件即可。

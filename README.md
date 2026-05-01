# Neovim 配置

基于 [lazy.nvim](https://github.com/folke/lazy.nvim) 的 Neovim 配置，面向 **Julia 科研计算** 与 **LaTeX / Markdown / Quarto** 写作场景深度定制。

## 核心特性

### REPL 驱动开发

- 通过 **vim-slime** 实现代码块 / 选区 / 段落发送到终端 REPL
- 一键启动 Julia（自动检测 `Sysimage.so`）/ Python（IPython）终端
- 终端内代码发送时自动折叠空行、智能滚动

### LaTeX 与数学公式

- 100+ Unicode LaTeX 符号自动补全（`luasnippets/julia.lua`）
- 数学模式自动判断（Tree-sitter + vimtex 双重检测）
- LaTeX snippet 增强：自动分式、上下标、bra-ket、矩阵、微分算子
- 批量 `\(...\)` / `\[...\]` 转 `$...$` / `$$...$$` 命令（`:FixMath`）
- vimtex + texlab 前端 / 反向搜索（Zathura）

### Markdown / Quarto

- 智能 `<CR>`：自动续行 blockquote、列表、checkbox
- 代码块 LSP 支持（otter.nvim）
- 预览 `:QuartoPreview`
- 图片粘贴（img-clip.nvim）

### AI 辅助

| 工具 | 用途 |
|------|------|
| **CodeCompanion.nvim** | 多模型聊天（QinzhAI/Gemini/DeepSeek/GLM/Claude Code） |
| **GitHub Copilot** | 代码补全，`<C-Right>` 逐词接受 |
| **GPTCommit** | AI 生成 commit message |

### 代码导航

- **Treesitter text-objects**：函数/类/块/条件/循环
- **Aerial**：代码大纲侧边栏
- **Flash.nvim**：中文友好的快速跳转（集成 flash-zh.nvim）
- **GNU Global**：C/C++/Julia 符号索引与跳转

### LSP

| 语言 | LSP Server | 特性 |
|------|-----------|------|
| Julia | julials | Sysimage 加速、延迟诊断 |
| Python | pyright | 组织 imports、切换 Python 路径 |
| Lua | lua_ls | Neovim 配置感知补全 |
| C/C++ | clangd | 源/头文件切换 |
| LaTeX | texlab | latexmk 构建、正反向搜索 |
| Markdown | marksman | 文档 LSP |

### UI

- **主题**：tokyonight (night variant)
- **状态栏**：mini.statusline (Nerd Font 图标)
- **标签页**：自定义 tabline（编号、缩略路径、窗口数）
- **缩进线**：indent-blankline
- **Git 符号**：gitsigns（行内 diff、hunk 导航）
- **文件管理**：oil.nvim（目录编辑）、yazi.nvim（双栏文件管理器）

## 插件一览

<details>
<summary>点击展开完整插件列表</summary>

| 类别 | 插件 |
|------|------|
| 补全 | blink.cmp, LuaSnip |
| 语法 | nvim-treesitter, treesitter-context, treesitter-textobjects |
| 格式化 | conform.nvim |
| Linting | nvim-lint |
| LSP | lazydev.nvim |
| UI | mini.nvim (ai/surround/pairs/statusline), indent-blankline, aerial, which-key, fidget, render-markdown, snacks.nvim |
| Git | gitsigns, vim-fugitive, vim-rhubarb, vim-flog |
| 导航 | flash.nvim, flash-zh.nvim, dial.nvim, lastplace, guess-indent |
| 终端 | flatten.nvim, kitty-scrollback.nvim |
| 输入法 | fcitx.nvim |
| 其他 | todo-comments, vim-slime, quarto-nvim, vimtex |

</details>

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `<M-hjkl>` | 窗口间移动 |
| `<M-1..9>` | 跳转窗口 1-9 |
| `<Tab>1..9` | 跳转标签页 1-9 |
| `<M-n/p>` | Quickfix 上/下一条（预览） |
| `<M-q>` | 智能关闭窗口 / 分离 UI |
| `<leader>*` | 在所有缓冲区搜索光标词 |
| `s` / `S` | Flash 跳转 / Treesitter 跳转 |
| `<leader>tc` | 切换 AI 聊天 |
| `<leader>ta` | 切换代码大纲 |
| `<leader>th` | 切换 inlay hints |
| `<leader>td` | 切换诊断 |
| `<space>f` / `<space><space>` | 发送代码块 / 最大 TS 节点到 REPL |
| `grd` / `grD` | 跳转定义 / 声明 |
| `gy` | 复制到系统剪贴板（OSC52） |

## 目录结构

```
~/.config/nvim/
├── init.lua                  # 入口
├── lua/
│   ├── config/               # 核心配置（选项、快捷键、自动命令、LSP）
│   ├── plugins/              # 插件声明（每个插件一个文件）
│   ├── custom/               # 自定义模块（终端运行器、标签栏、AI 客户端）
│   └── util/                 # 工具函数（TS 区域检测、搜索、Quickfix）
├── ftplugin/                 # 文件类型插件
├── after/ftplugin/           # 文件类型覆盖
├── lsp/                     # LSP 服务器配置
├── luasnippets/              # 代码片段
├── templates/                # 新文件模板
├── queries/                  # Tree-sitter 查询
└── plugin/                   # 全局按键映射
```

## 依赖

- Neovim >= 0.10
- [lazy.nvim](https://github.com/folke/lazy.nvim)（首次启动自动安装）
- [Julia](https://julialang.org)（可选）
- [GNU Global](https://www.gnu.org/software/global/)（可选，符号跳转）
- [fzf](https://github.com/junegunn/fzf)（可选）

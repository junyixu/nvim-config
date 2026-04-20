# CodeCompanion.nvim 源码分析文档

## 概述
本文档记录了 CodeCompanion.nvim 插件源码的关键位置分析，重点关注 Rules/Context 系统的实现机制。

## 关键源码位置

### 1. 默认配置 (config.lua)

#### 1.1 Rules 默认文件列表
- **文件**: `lua/codecompanion/config.lua`
- **行号**: 751-753

```lua
default = {
  files = {
    ".clinerules",
    ".cursorrules",
    ".goosehints",
    ".rules",
    ".windsurfrules",
    ".github/copilot-instructions.md",
    "AGENT.md",
    "AGENTS.md",
    { path = "CLAUDE.md", parser = "claude" },
    { path = "CLAUDE.local.md", parser = "claude" },
    { path = "~/.claude/CLAUDE.md", parser = "claude" },
  },
}
```

#### 1.2 Rules 默认选项配置
- **文件**: `lua/codecompanion/config.lua`
- **行号**: 820-827

```lua
opts = {
  chat = {
    autoload = "default",
  },
},
```

---

### 2. Rules 帮助函数 (rules/helpers.lua)

#### 2.1 列出所有规则
- **文件**: `lua/codecompanion/interactions/chat/rules/helpers.lua`
- **行号**: 50

```lua
function M.list(chat)
```

#### 2.2 添加回调函数
- **文件**: `lua/codecompanion/interactions/chat/rules/helpers.lua`
- **行号**: 96

```lua
function M.add_callbacks(args, rules_name)
```

#### 2.3 添加上下文
- **文件**: `lua/codecompanion/interactions/chat/rules/helpers.lua`
- **行号**: 142

```lua
function M.add_context(files, chat)
```

#### 2.4 生成规则标签 ID
- **文件**: `lua/codecompanion/interactions/chat/rules/helpers.lua`
- **行号**: 144

```lua
local id = "<rules>" .. file.name .. "</rules>"
```

#### 2.5 添加文件或缓冲区
- **文件**: `lua/codecompanion/interactions/chat/rules/helpers.lua`
- **行号**: 164

```lua
function M.add_files_or_buffers(included_files, chat)
```

---

### 3. Context 显示 (context.lua)

#### 3.1 Context 头部显示
- **文件**: `lua/codecompanion/interactions/chat/context.lua`
- **行号**: 1

```lua
local context_header = "> Context:"
```

---

## 问题解决过程

### 问题: 自动加载 CLAUDE.md

**问题描述**: 每次打开 `:CodeCompanionChat` 都显示 `> Context: - <rules>/home/junyi/.claude/CLAUDE.md</rules>`

**源码分析**:
1. **自动加载机制** (`config.lua:820-827`)
   - `rules.opts.chat.autoload = "default"` 控制自动加载的规则组

2. **默认规则文件** (`config.lua:751-753`)
   - "default" 规则组包含了三个 CLAUDE.md 相关文件:
     - `{ path = "CLAUDE.md", parser = "claude" }`
     - `{ path = "CLAUDE.local.md", parser = "claude" }`
     - `{ path = "~/.claude/CLAUDE.md", parser = "claude" }`

3. **标签生成** (`rules/helpers.lua:144`)
   - 使用 `<rules>` 和 `</rules>` 包裹文件名
   - 格式: `<rules>filename</rules>`

4. **Context 显示** (`context.lua:1`)
   - 显示格式: `> Context:`

**解决方案**:
在用户配置中完全重写 `rules.default.files`:

```lua
rules = {
  default = {
    files = {
      ".clinerules",
      ".cursorrules",
      ".goosehints",
      ".rules",
      ".windsurfrules",
      ".github/copilot-instructions.md",
      "AGENT.md",
      "AGENTS.md",
      -- 注释掉 CLAUDE.md 相关文件
      -- { path = "CLAUDE.md", parser = "claude" },
      -- { path = "CLAUDE.local.md", parser = "claude" },
      -- { path = "~/.claude/CLAUDE.md", parser = "claude" },
    },
  },
  opts = {
    chat = {
      autoload = "default",
    },
  },
},
```

**原理**:
通过显式提供完整的 `rules.default` 配置结构，确保用户配置完全覆盖内置默认值。

## 规则自动加载流程

1. **聊天创建** → 调用 `M.add_callbacks()` (`rules/helpers.lua:96`)
2. **检查 autoload** → 读取 `rules.opts.chat.autoload` (`config.lua:820-827`)
3. **获取规则组** → 根据名称找到对应规则 (如 "default")
4. **添加上下文** → 调用 `add_to_chat_from_config()` → `M.add_context()` (`rules/helpers.lua:142`)
5. **生成标签** → 创建 `<rules>filename</rules>` 格式 ID (`rules/helpers.lua:144`)
6. **显示** → 渲染 `> Context:` 头部 (`context.lua:1`)

## 参考配置

完整用户配置 (`lua/plugins/CodeCompanion.lua`):

```lua
return {
  {
    'olimorris/codecompanion.nvim',
    version = '^18.0.0',
    opts = {
      adapters = { /* 适配器配置 */ },
      interactions = {
        chat = {
          adapter = 'deepseek',
          keymaps = {
            yolo_mode = {
              modes = { n = "<leader>ty" },
              callback = "keymaps.yolo_mode",
              description = "YOLO mode toggle",
            },
          },
        },
      },
      rules = {
        default = {
          files = {
            ".clinerules",
            ".cursorrules",
            ".goosehints",
            ".rules",
            ".windsurfrules",
            ".github/copilot-instructions.md",
            "AGENT.md",
            "AGENTS.md",
            -- 注释掉 CLAUDE.md 相关文件
            -- { path = "CLAUDE.md", parser = "claude" },
            -- { path = "CLAUDE.local.md", parser = "claude" },
            -- { path = "~/.claude/CLAUDE.md", parser = "claude" },
          },
        },
        opts = {
          chat = {
            autoload = "default",
          },
        },
      },
    },
    config = function(_, opts)
      require('codecompanion').setup(opts)
      -- 键位设置
      vim.keymap.set('n', '<leader>tc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = '[T]oggle CodeCompanion [C]hat' })
      vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { noremap = true, silent = true, desc = 'CodeCompanion Chat [A]dd selection' })
      vim.keymap.set('v', '<leader>ca', '<cmd>CodeCompanionActions<cr>', { noremap = true, silent = true, desc = '[C]odeCompanion [A]ctions' })
      -- 命令缩写
      vim.cmd [[ cabbrev cc CodeCompanion ]]
    end,
  },
}
```

## 总结

- **默认规则配置**: `config.lua:751-753`
- **自动加载设置**: `config.lua:820-827`
- **规则处理逻辑**: `rules/helpers.lua:96-220`
- **标签生成**: `rules/helpers.lua:144`
- **Context 显示**: `context.lua:1`
- **解决方案**: 完全重写 `rules.default.files` 配置以覆盖内置默认值

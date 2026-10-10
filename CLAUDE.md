# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim configuration (kickstart.nvim-derived), managed with `lazy.nvim`. There is no
build step and no test suite — "correctness" means the config loads cleanly and the plugin/keymap/
LSP behavior works interactively.

## Commands

- **Check for load errors after editing Lua config**: `nvim --headless -c 'qa' 2>&1` (a clean exit
  with no output means no startup errors). To exercise one changed file in isolation without a full
  session: `nvim --headless -u NONE -c "luafile <path>" -c 'qa' 2>&1`.
- **Plugin management**: `:Lazy` (status), `:Lazy sync` / `:Lazy update` (install/update). Plugin
  versions are **not pinned** — `lazy-lock.json` is gitignored, so updates float.
- **LSP/health**: `:LspInfo`, `:checkhealth`.
- **Format Lua**: handled by `conform.nvim` (`stylua`), either on save or via `<space>F`; can also be
  run directly from the CLI as `stylua .` (style is pinned in `.stylua.toml`: 2-space indent, prefer
  single quotes, no parens on single-arg calls, 160-col width).
- **Lint**: `nvim-lint` runs automatically on `BufEnter`/`BufWritePost`/`InsertLeave` for `matlab`
  (`mlint`) and `sh` (`shellcheck`) only — see `lua/plugins/lint.lua`. There is no manual lint command
  for other filetypes.
- **Julia/C tag navigation**: `:Gtags`/`:Gtagsa` (GNU Global, backed by the root `GPATH`/`GRTAGS`/
  `GTAGS` files, which are gitignored and regenerated locally).

## Load order / entry point

`init.lua` → `require 'config'` → `require 'lazy_nvim'`.

`lua/config/init.lua` requires, in this fixed order: `globals` → `options` → `commands` →
`autocmds` → `templates` → `keymaps` → `lsp`. Leader keys are set in `globals.lua`
(`mapleader = ','`, `maplocalleader = ' '`) and **must** stay ahead of plugin loading, which is why
they live in the first module required.

`lua/lazy_nvim.lua` bootstraps `lazy.nvim` and imports every spec under `lua/plugins/` (one file per
plugin, flat, not categorized into subfolders). Only `lua/plugins/*.lua` is auto-imported as plugin
specs — personal Lua modules that are *not* plugin specs live elsewhere (see below) and must not be
dropped into `lua/plugins/` or lazy.nvim will try to treat them as a plugin table and fail.

## Standalone scripts

`bin/` holds non-Neovim source that Neovim must not auto-load (e.g. `bin/epub_to_typr_phrases.py`, a
CLI script run by hand). Deliberately not `plugin/`, `autoload/`, etc. —
those directories are scanned/sourced by Neovim itself, and `bin/` is not, so plain Python (or other
non-vim/lua) helpers belong there instead.

## Non-plugin personal modules

- `lua/junyi/` — standalone user utilities, `require`d individually where needed (e.g.
  `junyi.make` backs the `:Make`/`:LMake` commands, `junyi.close_other_uis`). For lazy loading, a
  thin `plugin/*.lua` stub can define commands/keymaps that `require` the module only on first use —
  `plugin/last_diary.lua` → `junyi.last_diary` (`:DiaryPrev`/`:DiaryNext`) is the example.
- `lua/util/` — editor-level helper functions used across configs/keymaps (clipboard incl. OSC 52
  for non-tmux copy, quickfix helpers, treesitter utils, git-merge helpers, the Claude Code
  line-reference helper `util/claude.lua`).

## Native LSP setup (not nvim-lspconfig)

Servers are configured with Neovim's built-in `vim.lsp.config`/`vim.lsp.enable` runtimepath
convention, split into two layers:

- `lsp/<name>.lua` — base config table (`cmd`, `filetypes`, `root_markers`, `settings`), one file per
  server, auto-discovered by Neovim.
- `after/lsp/<name>.lua` — optional override/extension layered on top of the base config for the same
  server name, loaded after it (standard Neovim `after/` semantics applied to the `lsp/` runtime dir).
  `after/lsp/julials.lua` is the working example — it derives the Julia LSP environment path from a
  project's `Manifest.toml`.
- `lua/config/lsp.lua` calls `vim.lsp.enable '<name>'` for each server that should actually start, and
  owns the shared `LspAttach` autocmd (keymaps, document-highlight, inlay-hint toggle).

To add a server: create `lsp/<name>.lua`, then add `vim.lsp.enable '<name>'` in `lua/config/lsp.lua`.

Note: `lsp/stylua.lua` runs `stylua --lsp` as a real LSP server — a second, independent path to Lua
formatting alongside `conform.nvim`'s own `stylua` integration.

## Filetype config

`ftplugin/<ft>.{lua,vim}` holds per-filetype settings; `after/ftplugin/<ft>.*` holds overrides applied
after plugins load (same `after/` pattern as the LSP layer above). Language-specific depth exists for
Julia, LaTeX (`vimtex` + LuaSnip snippets + `tex-fmt`), Typst (`tinymist` LSP + `typst-preview.nvim`),
and Quarto/Markdown (`quarto-nvim`, `render-markdown.nvim`, `prettier`).

## Keymaps and commands

- Most keymaps are centralized in `lua/config/keymaps.lua`; plugin-specific keymaps are more often
  declared inside that plugin's own spec (`keys = {...}` in `lua/plugins/<name>.lua`) than added here.
- `which-key` leader groups are declared in `lua/plugins/which-key.lua`'s `opts.spec`: `<leader>f`
  Finder, `<leader>t` Toggle, `<leader>h` Git Hunk, plus a second leader under `<Tab>`. Add new
  leader-prefixed mappings under the matching group rather than inventing a new prefix.
- Custom `:Ex`-style commands are centralized in `lua/config/commands.lua` (`:E`, `:JuliaStackOpen`,
  `:Gtags`/`:Gtagsa`, `:GptCommit`, `:DiffRemote`, `:FixMath`, `:Make`/`:LMake`).

## Design notes for tricky subsystems

`doc/*.md` holds the user's own write-ups for non-obvious internals — check here before re-deriving
behavior from scratch: `codecompanion-source-code-analysis.md`, `indent-notes.md`,
`julia-stacktrace-gF.md`, `luasnip-latex-snippets-overview.md`, `luasnip-tex-condition-fix.md`,
`luasnip-ultisnips-fraction.md`, `mini-ai-default-textobjects.md`, `snacks_img.md`/`snacks_img2.md`,
`tabline.md`.

## Git commits in this repo

Follow the conventional-commit format from the user's global `~/.claude/CLAUDE.md` (type(scope):
summary header under 50 chars, 2-4 body bullets in imperative mood). Do **not** append a
`Co-Authored-By` / `Claude-Session` attribution footer to commits in this repository — the user has
explicitly opted out of it here.

# Julia LSP: project environment resolution and the `@sandbox` env

Notes on how the two Julia language servers in this config (`julials` = LanguageServer.jl,
`jetls` = JETLS.jl) decide which environment to analyze, and why a dedicated
`~/.julia/environments/sandbox` env was added for standalone scripts.

Related commits: `3288bee`, `f1b5e7e`, `59eb128` (julials), `69d6f2d` (jetls).

## TL;DR

- **LSP env vs. project env.** The env the server *runs in* (`lsp1.12` for julials, `apps/JETLS`
  for jetls) is a different thing from the env whose packages it *analyzes* (your project, or a
  fallback for standalone scripts).
- **julials** computes one `project_path` at startup. Fallback chain (`after/lsp/julials.lua`):
  `JULIA_PROJECT` → upward `Project.toml` (stops at `$HOME`) → `@sandbox` (if it exists) →
  first `Base.load_path()` entry → `@v#.#`.
- **jetls** picks the env per file: upward `Project.toml` (to `/`), temporarily `Pkg.activate`d.
  Standalone scripts use JETLS's hard-coded `LOAD_PATH = ["@", "@v#.#", "@stdlib"]`;
  `lsp/jetls.lua` points `"@"` at the sandbox through `cmd_env = { JULIA_PROJECT = '@sandbox' }`.
- **Both** skip the sandbox when it doesn't exist (e.g. on the VPS), and both respect a
  `JULIA_PROJECT` that is already set.

## 1. Two different directories

| | julials | jetls |
|---|---|---|
| Env that runs the server | `~/.julia/environments/lsp<ver>` (`--project=`, plus `julials.so` sysimage) | `~/.julia/environments/apps/JETLS` (set by the `~/.julia/bin/jetls` shim via `JULIA_LOAD_PATH`) |
| Env that is analyzed | `project_path`, passed to `LanguageServerInstance` | `Project.toml` found per file, or `LOAD_PATH` for standalone scripts |

The server env holds only the server packages (`LanguageServer`, `SymbolServer`, `StaticLint`).
It is kept separate so that it doesn't pollute your projects, and so that upgrading packages
there can't break the sysimage.

## 2. julials

### 2.1 The `project_path` chain

Upstream `nvim-lspconfig` uses this chain:

```julia
project_path = dirname(something(
    Base.load_path_expand(nonempty(ENV["JULIA_PROJECT"])),  # 1
    Base.current_project(),                                  # 2 upward Project.toml, $HOME boundary
    get(Base.load_path(), 1, nothing),                       # 3 respects JULIA_LOAD_PATH
    Base.load_path_expand("@v#.#"),                          # 4
))
```

It replaced the old one-liner
`dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))`, which:

- ignored `JULIA_PROJECT`, which `--project=` overrides at Julia startup;
- hard-coded `LOAD_PATH[2]`, which breaks when `JULIA_LOAD_PATH` is set: you get a `BoundsError`
  with a single entry, or the wrong env with `"/custom/env:"`.

### 2.2 Pitfall: `--project=<lsp env>` leaks into the fallback

Upstream starts julia **without** `--project`. This config passes `--project=lsp1.12` (needed for
the sysimage), so in a project-less directory step 3 resolved `"@"` to `lsp1.12`. Standalone
scripts were then analyzed against the server's own env.

Fix (`f1b5e7e`): clear the active project once the server packages are loaded.

```julia
using LanguageServer, SymbolServer, StaticLint
Base.set_active_project(nothing)
```

### 2.3 Why `using LinearAlgebra` still didn't complete

SymbolServer.jl only indexes packages listed in `project_path`'s `Project.toml`/`Manifest.toml`.
Its built-in set covers only `Main`, `Base` and `Core`. The `@stdlib` entry in `LOAD_PATH` makes
stdlibs *loadable* in a REPL, but SymbolServer doesn't index them. So a stdlib that isn't in the
fallback env's manifest gets no completion.

### 2.4 The `@sandbox` step

Rather than adding packages to the global `@v1.12`, a dedicated env holds the packages commonly
used in standalone scripts:

```sh
julia --project=@sandbox -e 'using Pkg; Pkg.add(["LinearAlgebra","SparseArrays","Statistics","Random","Printf","Dates","Test","PythonCall"])'
```

Design decisions:

- **Name:** `@sandbox`, i.e. `~/.julia/environments/sandbox`. Avoided `@scratch`, which is easily
  confused with Scratch.jl's scratchspaces.
- **Versioning:** none (unlike `lsp1.12`); run `Pkg.resolve` after upgrading Julia.
- **Position:** after the upward `Project.toml` lookup, before `JULIA_LOAD_PATH`.
- **Optional:** the step is skipped if the env doesn't exist (e.g. on the VPS).

```julia
## 3. Sandbox env for standalone scripts (~/.julia/environments/sandbox), if it exists
(p = Base.load_path_expand("@sandbox"); p !== nothing && isfile(p) ? p : nothing),
```

**Gotcha:** `Base.load_path_expand("@name")` returns `.../environments/name/Project.toml` even when
that directory does not exist, so the `isfile` check is required.

## 3. jetls

Source read from `~/.julia/packages/JETLSCore/*/src`.

### 3.1 `LOAD_PATH` is replaced

`jetls serve` runs inside `@with_cli_LOAD_PATH` (`app/app.jl`):

```julia
empty!(LOAD_PATH)
push!(LOAD_PATH, "@", "@v$(VERSION.major).$(VERSION.minor)", "@stdlib")
```

Consequences:

- `JULIA_LOAD_PATH` has no effect on analysis.
- The server's own env never leaks into analysis (unlike §2.2).
- `JULIA_PROJECT` still works: it sets the initial active project, which is what `"@"` resolves to.

### 3.2 Choosing the env per file: `find_analysis_env_path` (`utils/pkg.jl`)

1. `analysis_overrides` from the user config (path globs): disable analysis or force a module.
2. Julia's own `base/` and `Compiler/src` get special handling.
3. No workspace root → standalone script mode (`ScriptAnalysisEntry`); files outside the root are
   out of scope.
4. Otherwise `find_env_path`: search upward for `Project.toml`. This goes all the way to `/` (no
   `$HOME` boundary) and does not recognize `JuliaProject.toml`. The file is then classified as
   package `src/`, package `test/` (`test/Project.toml` maps back to the parent package), or a
   script in an env, and analyzed under a temporary `Pkg.activate(func, env_path)`.

`lsp/jetls.lua` uses `root_markers = { 'Project.toml' }`, so a project-less directory gives no
root, and the file is analyzed in script mode.

### 3.3 Stdlibs work out of the box

Script mode uses `LOAD_PATH = ["@", "@v1.12", "@stdlib"]`, and JETLS actually *loads* packages
instead of indexing a manifest. `using LinearAlgebra` therefore completes without any sandbox.

### 3.4 Pointing script mode at the sandbox (`lsp/jetls.lua`)

```lua
local cmd_env
if (vim.env.JULIA_PROJECT or '') == '' and vim.uv.fs_stat(vim.fn.expand '~/.julia/environments/sandbox/Project.toml') then
  cmd_env = { JULIA_PROJECT = '@sandbox' }
end
```

With this set, `Base.load_path()` in script mode becomes `sandbox → v1.12 → stdlib`. Real projects
are unaffected, because `Pkg.activate` takes over for them.

## 4. Verification (jetls, headless Neovim)

A probe script opened a `.jl` file in a project-less directory and polled
`textDocument/completion`. The JETLS child's environment was read from `/proc/<pid>/environ`.

| Case | `cmd_env` / process env | Result |
|---|---|---|
| No sandbox | `nil` | `norm` (LinearAlgebra) completes |
| Sandbox present | `JULIA_PROJECT=@sandbox` | `norm` completes |
| Shell has `JULIA_PROJECT=/tmp` | `nil`; process keeps `/tmp` | shell value respected |
| Sandbox with `PythonCall` | `JULIA_PROJECT=@sandbox` | `pyimport` completes |
| Control: shell `JULIA_PROJECT=<empty env>` | `nil` | `pyimport` **not** found |

Lesson: a stdlib-only sandbox can't prove anything, because stdlibs also resolve through
`@stdlib`. Test with a third-party package that exists only in the sandbox.

julials: the `project_path` chain was checked in isolation with a temporary `JULIA_DEPOT_PATH`
(no sandbox → `.../v1.12`; sandbox → `.../sandbox`), and in `lsp.log` (`@info "LSP Started"
project_path`).

## 5. Open issue

With `JULIA_PROJECT=@v1.12` set in the shell on a machine where `~/.julia/environments/v1.12`
doesn't exist, JETLS did not attach within 30 s (`NO CLIENT`). It is unclear whether it failed to
start or was just slow. This doesn't affect the normal path, since `cmd_env` is only set when the
sandbox exists.

local function has_project_toml()
  return vim.fn.filereadable(vim.fn.getcwd() .. '/Project.toml') == 1
end

-- 重点：使用 return 语法
return {
  -- 这里是普通 snippets
  parse(
    {
      trig = 'build',
      name = 'Julia Makie Sysimage Makefile',
      condition = has_project_toml,
    },
    [[
# ==========================================
# 配置区域 (按需修改)
# ==========================================

# 输出的系统镜像文件名
SYSIMAGE := ${1:GLMakieSysimage.so}

MAIN := ${2:35.jl}

# 需要打包进镜像的包列表
PKGS := ${3::GLMakie}

# 预编译脚本路径
PRECOMPILE_SCRIPT := ${4:precompile_makie.jl}

JULIA := julia
PROJECT := .

.PHONY: all build run clean help

all: run

run:
	$(JULIA) --project=$(PROJECT) $(MAIN)

build:
	@echo "🚀 正在构建 System Image: $(SYSIMAGE)..."
	@if [ -f "$(PRECOMPILE_SCRIPT)" ]; then \
		$(JULIA) --project=$(PROJECT) -e 'using PackageCompiler; create_sysimage(['$(PKGS)']; sysimage_path="$(SYSIMAGE)", precompile_execution_file="$(PRECOMPILE_SCRIPT)")'; \
	else \
		$(JULIA) --project=$(PROJECT) -e 'using PackageCompiler; create_sysimage(['$(PKGS)']; sysimage_path="$(SYSIMAGE)")'; \
	fi
	@echo "✅ 构建完成！"

clean:
	rm -f $(SYSIMAGE)
]]
  ),
}, {
  -- 这里是 autosnippets，必须返回，哪怕是空的
}

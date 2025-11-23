lua << EOF
require 'essentials'
require 'lazy_nvim'
require'lspconfig'.julials.setup({
      on_new_config = function(new_config,new_root_dir)
      server_path = "/home/junyi/.julia/packages/LanguageServer/Fwm1f/src/"
      cmd = {
        "julia",
        "--project="..server_path,
        "--startup-file=no",
        "--history-file=no",
        "--trace-compile=/home/junyi/.julia/environments/nvim-lspconfig/packagecompiler/tracecompilelsp.jl",
        -- "--trace-compile=./tracecompilelsp.jl",
        "-e", [[
          using Pkg;
          Pkg.instantiate()
          using LanguageServer; using SymbolServer;
          depot_path = get(ENV, "JULIA_DEPOT_PATH", "")
          project_path = dirname(something(Base.current_project(pwd()), Base.load_path_expand(LOAD_PATH[2])))
          # Make sure that we only load packages from this environment specifically.
          @info "Running mark language server" env=Base.load_path()[1] pwd() project_path depot_path
          server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path, depot_path);
          server.runlinter = true;
          run(server);
        ]]
    };
    new_config.cmd = cmd
    on_attach=require'completion'.on_attach
    end
})
EOF

" ============================================================================
" Claude Code 快捷键映射
" ============================================================================
" 功能：将生成的文件行号引用复制到剪贴板（智能检测环境）
" 使用：
"   Normal 模式: <leader>y  -> 复制当前行引用
"   Visual 模式: <leader>y  -> 复制选中行范围引用
" 
" 实际效果：
"   - 执行函数生成引用格式（如 @unix.vim:123-456）
"   - 在tmux中：自动复制到tmux剪贴板（可用 tmux paste-buffer 粘贴）
"   - 非tmux环境：自动复制到系统剪贴板（+ 寄存器）
"   - 可直接粘贴到 Claude Code 对话中进行精准讨论
" ============================================================================
nnoremap <leader>y :call utils#copy_to_smart_clipboard(claude#get_line_reference())<CR>
vnoremap <leader>y :<C-u>call utils#copy_to_smart_clipboard(claude#get_line_reference())<CR>

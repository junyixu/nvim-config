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

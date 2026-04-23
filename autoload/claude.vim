" ============================================================================
" Claude Code Integration Functions
" ============================================================================
" 目的：生成 Claude Code 可识别的文件行号引用格式 (@filename:line-range)
" 作用：避免将整个文件内容发送给 Claude，而是通过行号精准定位代码片段

" 输出格式：
"   单行: @filename:123
"   多行: @filename:123-456

" 使用场景：
"   - 讨论特定代码行时，提供精确引用
"   - 让 Claude 分析特定代码段而非整个文件
"   - 在代码审查中快速定位问题区域
"   - 复制文件路径信息用于外部工具引用

function! claude#get_line_reference() abort
    " 第一步：获取基本信息
    " 获取相对于 vim 工作目录的文件路径
    let l:filename = expand("%:.")      " 直接获取相对路径
    " 如果不以 ./ 开头，添加 ./ 前缀使格式更清晰
    let l:line_start = line(".")        " 光标当前所在行号
    let l:line_end = l:line_start       " 默认只处理单行

    " 第二步：检测是否来自 Visual 模式选择
    " 说明：'< 和 '> 是 Vim 自动设置的标记，记录最近一次 visual 选择的起止位置
    " 即使在 Ex 命令执行时，这些标记仍然有效，比 mode() 函数更可靠
    let l:visual_start = line("'<")     " Visual 选择的起始行
    let l:visual_end = line("'>")       " Visual 选择的结束行

    " 第三步：判断是否使用 Visual 选择范围
    " 条件：标记有效 且 (多行选择 或 选择的行不是当前光标行)
    " 这样可以正确处理从 Visual 模式调用和普通模式调用两种情况
    if l:visual_start > 0 && l:visual_end > 0 && (l:visual_start != l:visual_end || l:visual_start != line("."))
        let l:line_start = l:visual_start
        let l:line_end = l:visual_end
    endif

    " 第四步：构建 Claude Code 识别的引用格式
    let l:reference = '@' .. l:filename .. ':'

    " 第五步：根据行数生成不同格式
    if l:line_start == l:line_end
        " 单行：@filename:123
        let l:reference .= l:line_start
    else
        " 多行：@filename:123-456  
        let l:reference ..= l:line_start .. '-' .. l:line_end
    endif

    " 第六步：输出并返回结果
    echomsg "Generated reference: " .. l:reference
    return l:reference
endfunction
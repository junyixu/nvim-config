" autoload/diary.vim
" Diary Navigation - Lazy Loading Support

let s:python_loaded = 0

function! diary#load_python() abort
  if s:python_loaded
    return
  endif

  " Load Python code from plugin directory
  let s:py_file = expand('<script>:p:h:h') .. '/plugin/last_diary.py'
  execute 'py3file' s:py_file
  let s:python_loaded = 1
endfunction

function! diary#prev() abort
  call diary#load_python()
  python3 last_diary()
endfunction

function! diary#next() abort
  call diary#load_python()
  python3 next_diary()
endfunction

" 自动填充日记模板和日期
" 解决 vim-template 插件无法计算日期的问题
function! diary#fill_yesterday_tomorrow() abort
  " 只在 diary 目录且文件为 yyyy-mm-dd.md 格式时执行
  let filepath = expand('%:p')
  " 提取文件名中的日期
  let filename = expand('%:t:r')  " 去掉扩展名的文件名

  " 确保文件名不为空且格式正确
  if filename =~# '^\d\{4}-\d\{2}-\d\{2}$'
    " 检查是否为今天的日记（只有今天的日记才自动替换）
    let today = strftime('%Y-%m-%d')
    if filename !=# today
      " 不是今天的日记，不执行替换
      return
    endif

    " 解析年月日
    let parts = split(filename, '-')
    if len(parts) == 3
      let year = parts[0]
      let month = parts[1]
      let day = parts[2]

      " 计算昨天和明天
      let yesterday = s:calculate_date(year, month, day, -1)
      let tomorrow = s:calculate_date(year, month, day, 1)

      " 生成完整日期格式（带星期几，英文月份）
      let full_date = s:generate_full_date(year, month, day)

      " 替换模板中的占位符（只替换存在的占位符）
      if search('{{FULL_DATE}}', 'n')
        execute '%s/{{FULL_DATE}}/' . full_date . '/g'
      endif
      if search('{{YESTERDAY}}', 'n')
        execute '%s/{{YESTERDAY}}/' . yesterday . '/g'
      endif
      if search('{{TOMORROW}}', 'n')
        execute '%s/{{TOMORROW}}/' . tomorrow . '/g'
      endif
    endif
  endif
endfunction

" 计算日期加减
" @param year 年份字符串
" @param month 月份字符串
" @param day 日期字符串
" @param offset 偏移天数（负数为昨天，正数为明天）
" @return 格式化后的日期字符串 YYYY-MM-DD
function! s:calculate_date(year, month, day, offset) abort
  " 使用系统命令 date 计算日期
  let date_str = a:year . '-' . a:month . '-' . a:day
  let offset_str = a:offset
  if offset_str > 0
    let offset_str = '+' . offset_str
  endif

  " 使用 GNU date 命令计算新日期
  let cmd = 'date -d "' . date_str . ' ' . offset_str . ' days" +%Y-%m-%d'
  let result = system(cmd)

  " 去除换行符
  let result = substitute(result, '\n', '', 'g')

  return result
endfunction

" 生成完整的英文日期格式（带星期几）
" @param year 年份字符串
" @param month 月份字符串
" @param day 日期字符串
" @return 格式化后的完整日期字符串，如 "Monday, November 17, 2025"
function! s:generate_full_date(year, month, day) abort
  " 构建日期字符串并使用 LC_TIME=C 的 date 命令生成完整格式
  let date_str = a:year . '-' . a:month . '-' . a:day
  let cmd = 'LC_TIME=C date -d "' . date_str .'" +"%A, %B %d, %Y"'
  let result = system(cmd)

  " 去除换行符
  let result = substitute(result, '\n', '', 'g')

  return result
endfunction

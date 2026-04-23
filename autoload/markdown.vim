function markdown#toggle_todo()
  let line = getline('.')
  if line =~ '^\s*- \[ \]'
    call setline('.', substitute(line, '- \[ \]', '- [X]', ''))
  elseif line =~ '^\s*- \[X\]'
    call setline('.', substitute(line, '- \[X\]', '- [ ]', ''))
  else
    call markdown#add_todo()
  endif
endfunction

function markdown#add_todo()
  let line = getline('.')
  let indent = matchstr(line, '^\s*')
  let content = substitute(line, '^\s*', '', '')
  if content =~ '^- '
    " Line already starts with '- ', just insert checkbox
    call setline('.', substitute(line, '^\(\s*\)- ', '\1- [ ] ', ''))
  elseif content != ''
    " Non-empty line without '- ', add both
    call setline('.', indent . '- [ ] ' . content)
  endif
endfunction

fun GPG#encrypt()
  call system('gpg -a --recipient "Julian" --output xjy.en.txt --encrypt a.txt')
endf

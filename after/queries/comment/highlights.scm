; extends

; Bump treesitter priority above LSP semantic tokens (default 125)
; so @comment.todo / warning / error / note are not overridden by LSP.

((tag (name) @comment.todo)
  (#any-of? @comment.todo "TODO" "WIP")
  (#set! "priority" 200))

("text" @comment.todo
  (#any-of? @comment.todo "TODO" "WIP")
  (#set! "priority" 200))

((tag (name) @comment.note)
  (#any-of? @comment.note "NOTE" "XXX" "INFO" "DOCS" "PERF" "TEST")
  (#set! "priority" 200))

("text" @comment.note
  (#any-of? @comment.note "NOTE" "XXX" "INFO" "DOCS" "PERF" "TEST")
  (#set! "priority" 200))

((tag (name) @comment.warning)
  (#any-of? @comment.warning "HACK" "WARNING" "WARN" "FIX")
  (#set! "priority" 200))

("text" @comment.warning
  (#any-of? @comment.warning "HACK" "WARNING" "WARN" "FIX")
  (#set! "priority" 200))

((tag (name) @comment.error)
  (#any-of? @comment.error "FIXME" "BUG" "ERROR")
  (#set! "priority" 200))

("text" @comment.error
  (#any-of? @comment.error "FIXME" "BUG" "ERROR")
  (#set! "priority" 200))

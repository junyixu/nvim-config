; extends

((macrocall_expression
  (macro_identifier
    (identifier) @_macro)
  (macro_argument_list
    (binary_expression
      (string_literal
        (content) @injection.content))))
  (#any-of? @_macro "pyexec" "pyeval")
  (#set! injection.language "python"))

; extends

; 整段 section (标题 + 正文) 作为完整 class，比 shipped 的 heading-only 更适合 `aA`/`iA` 操作
(section) @class.outer

; 代码块作为 function-like 单元，让 `[m` / `]m` 在 .qmd 中跳代码块
(fenced_code_block) @function.outer

(fenced_code_block
  (code_fence_content) @function.inner)

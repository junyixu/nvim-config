; section = heading + body;  [[  ]]  跳标题
(section) @class.outer
(heading) @class.inner

; let 绑定 (含 `#let foo(args) = body` 函数定义);  [m  ]m  跳函数
(let) @function.outer
(let) @function.inner

; 调用;  [f  ]f
(call) @call.outer
(call) @call.inner

; 循环
(for) @loop.outer
(for) @loop.inner

; 条件分支 (if / else)
(branch) @conditional.outer
(branch) @conditional.inner

; 代码 / 内容块
(content) @block.outer
(raw_blck) @block.outer

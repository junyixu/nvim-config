local ls = require 'luasnip'

local parse = ls.parser.parse_snippet
local conds = require 'luasnip.extras.conditions'

-- Snippets ported from vim-snippets/UltiSnips/c.snippets
-- Snippets with Python/vim function evaluation are simplified or omitted.
local result = {
  parse({ trig = 'def', desc = '#define ...' }, '#define $1'),
  parse(
    { trig = '#ifndef', desc = '#ifndef ... #define ... #endif' },
    [[
#ifndef ${1:SYMBOL}
#define $1 ${2:value}
#endif /* ifndef $1 */
]]
  ),
  parse(
    { trig = '#if', desc = '#if #endif', condition = conds.line_begin },
    [[
#if ${1:0}
$0
#endif
]]
  ),
  parse(
    { trig = 'mark', desc = '#pragma mark (mark)' },
    [[
#if 0
${1:#pragma mark -
}#pragma mark $2
#endif

$0
]]
  ),
  parse(
    { trig = 'main', desc = 'main() (main)' },
    [[
int main(int argc, char *argv[])
{
	$0
	return 0;
}
]]
  ),
  parse(
    { trig = 'for', desc = 'for loop (for)' },
    [[
for (${2:i} = 0; $2 < ${1:count}; ${3:++$2}) {
	$0
}
]]
  ),
  parse(
    { trig = 'fori', desc = 'for int loop (fori)' },
    [[
for (${4:int} ${2:i} = 0; $2 < ${1:count}; ${3:++$2}) {
	$0
}
]]
  ),
  parse(
    { trig = 'eli', desc = 'else if .. (eli)' },
    [[
else if (${1:/* condition */}) {
	$0
}
]]
  ),
  parse(
    { trig = 'fun', desc = 'function', condition = conds.line_begin },
    [[
${1:void} ${2:function_name}($3)
{
	$0
}
]]
  ),
  parse({ trig = 'fund', desc = 'function declaration', condition = conds.line_begin }, [[${1:void} ${2:function_name}($3);]]),
  parse(
    { trig = 'st', desc = 'struct' },
    [[
struct ${1:name_t} {
	${0:/* data */}
};
]]
  ),
  parse({ trig = 'printf', desc = 'printf' }, [[printf("$1\n"$2);]]),
  parse({ trig = 'fprintf', desc = 'fprintf' }, [[fprintf(${1:stderr}, "${2:%s}\n", $3);]]),
}

return result

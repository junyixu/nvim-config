local ls = require 'luasnip'

local parse = ls.parser.parse_snippet
local conds = require 'luasnip.extras.conditions'

-- Snippets ported from vim-snippets/UltiSnips/cpp.snippets
-- Source `extends c`; configure inheritance via `ls.filetype_extend('cpp', {'c'})`
-- in your LuaSnip setup if you want C snippets available in C++.
-- Snippets with Python/vim regex transforms are simplified or omitted.
local result = {
  parse(
    { trig = 'main', desc = 'main' },
    [[
int main(int argc, char *argv[])
{
	$0
	return 0;
}
]]
  ),
  parse(
    { trig = 'cl', desc = 'class .. (class)' },
    [[
class ${1:name}
{
public:
	$1(${2:arguments});
	virtual ~$1();

private:
	${0:/* data */}
};
]]
  ),
  parse(
    { trig = 'ns', desc = 'namespace .. (namespace)' },
    [[
namespace ${1:name}
{
	$0
} /* $1 */
]]
  ),
  parse(
    { trig = 'readfile', desc = 'read file (readF)' },
    [[
std::vector<char> v;
if (FILE *fp = fopen(${1:"filename"}, "r"))
{
	char buf[1024];
	while(size_t len = fread(buf, 1, sizeof(buf), fp))
		v.insert(v.end(), buf, buf + len);
	fclose(fp);
}
]]
  ),
  parse(
    { trig = 'map', desc = 'std::map (map)' },
    [[std::map<${1:key}, ${2:value}> map$0;]]
  ),
  parse(
    { trig = 'vector', desc = 'std::vector (v)' },
    [[std::vector<${1:char}> v$0;]]
  ),
  parse(
    { trig = 'tp', desc = 'template <typename ..> (template)' },
    [[template <typename ${1:_InputIter}>]]
  ),
  parse(
    { trig = 'cla', desc = 'An entire .h generator', condition = conds.line_begin },
    [[
#ifndef ${2:CLASSNAME_H}
#define $2

class ${1:ClassName}
{
private:
	$3

public:
	$1();
	virtual ~$1();
};

#endif /* $2 */
]]
  ),
  parse(
    { trig = 'fnc', desc = 'Basic c++ doxygen function template', condition = conds.line_begin },
    [[
/**
* @brief: ${4:brief}
*
* @param: $3
*
* @return: $1
*/
${1:ReturnType} ${2:FunctionName}(${3:param})
{
	${0:FunctionBody}
}
]]
  ),
  parse(
    { trig = 'boost_test', desc = 'Boost test module', condition = conds.line_begin },
    [[
#define BOOST_TEST_MODULE ${1:TestModuleName}
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_CASE(${2:TestCaseName})
{
	${0:TestDefinition}
}
]]
  ),
  parse(
    { trig = 'boost_suite', desc = 'Boost test suite module', condition = conds.line_begin },
    [[
#define BOOST_TEST_MODULE ${1:TestModuleName}
#include <boost/test/included/unit_test.hpp>

BOOST_AUTO_TEST_SUITE(${2:SuiteName})

BOOST_AUTO_TEST_CASE(${3:TestCaseName})
{
	${0:TestDefinition}
}

BOOST_AUTO_TEST_SUITE_END()
]]
  ),
  parse(
    { trig = 'boost_test_fixture', desc = 'Boost test module with fixture', condition = conds.line_begin },
    [[
#define BOOST_TEST_MODULE ${1:TestModuleName}
#include <boost/test/included/unit_test.hpp>

struct ${2:FixtureName} {
	$2() {}
	virtual ~$2() {}
	/* define members here */
};

BOOST_FIXTURE_TEST_CASE(${3:SuiteName}, $2)
{
	${0:TestDefinition}
}
]]
  ),
  parse(
    { trig = 'boost_suite_fixture', desc = 'Boost test suite with fixture', condition = conds.line_begin },
    [[
#define BOOST_TEST_MODULE ${1:TestModuleName}
#include <boost/test/included/unit_test.hpp>

struct ${2:FixtureName} {
	$2() {}
	virtual ~$2() {}
	/* define members here */
};

BOOST_FIXTURE_TEST_SUITE(${3:SuiteName}, $2)

BOOST_AUTO_TEST_CASE(${4:TestCaseName})
{
	${0:TestDefinition}
}

BOOST_AUTO_TEST_SUITE_END()
]]
  ),
}

return result

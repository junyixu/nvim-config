-- GPTCommit.lua（KISS）
--
-- 功能：根据 `git diff` 调用 AI API（优先 Gemini）生成 commit message。
-- 依赖：git、curl。
--
-- 命令：`:GptCommit [path]`
--   - `path` 为空：使用当前 buffer 所在目录；若无文件则用 cwd。
--   - 生成后：插入到当前 buffer（光标行上方）。
--
-- 配置：
--   - `vim.g.gpt_commit_key`（或环境变量 `GITCOMMIT_API_KEY`）
--   - `vim.g.gpt_commit_model`（默认 `gemini-flash-latest`）
--   - `vim.g.gpt_commit_url`（默认优先使用 Gemini API）
--   - `vim.g.gpt_commit_staged`（默认 1：优先 staged；为空会 fallback 到 unstaged）
--   - `vim.g.gpt_commit_max_lines`（默认 160：限制喂给模型的 diff 行数）

local M = {}

local function build_prompt()
  return [[Generate a git commit message following conventional commit format, for my changes. eg:

<type>(scope): <brief summary>

- Explain technical improvement or benefit
- Note any interface or behavior changes

Requirements:
- Header: conventional commit format, under 80 chars
- Body: 2-3 bullet points starting with action verbs
- Focus on WHAT changed and WHY, not HOW
- Be specific
- <type> is one of feat, fix, docs, style, refactor, perf, test, chore
- Use meaningful scope if applicable, e.g.: feat(fugitive.vim)
- Use present tense, imperative mood
- Output only the commit message, no labels or formatting markers]]
end

-- 通用 curl 请求函数（来自 api_client.lua）
local function make_curl_request(url, headers, body)
  local curl = {
    'curl',
    '-sS',
    '-X',
    'POST',
    url,
    '-H',
    'Content-Type: application/json',
    '--data-binary',
    '@-',
    '-w',
    '\n%{http_code}',
  }

  -- 添加额外的 headers
  for _, header in ipairs(headers or {}) do
    table.insert(curl, '-H')
    table.insert(curl, header)
  end

  local res = vim.system(curl, { text = true, stdin = body }):wait()
  if res.code ~= 0 then
    local detail = vim.trim((res.stderr or '') ~= '' and res.stderr or (res.stdout or ''))
    return nil, ('curl failed (%d): %s'):format(res.code, detail)
  end

  local out = res.stdout or ''
  local resp_body, http_code = out:match '^([%s%S]*)\n(%d+)%s*$'
  http_code = tonumber(http_code)

  return resp_body, http_code
end

-- OpenAI 格式转换
local function openai_format_messages(model, messages)
  return vim.json.encode { model = model, messages = messages }
end

-- Gemini 格式转换（适配最新 API）
local function gemini_format_messages(messages)
  local contents = {}
  local system_instruction = nil

  for _, msg in ipairs(messages) do
    if msg.role == 'system' then
      -- 现代 Gemini API 推荐使用独立的 system_instruction 字段
      system_instruction = {
        parts = { { text = msg.content } }
      }
    elseif msg.role == 'user' then
      table.insert(contents, {
        role = "user",
        parts = { { text = msg.content } }
      })
    elseif msg.role == 'assistant' then
      -- 注意：Gemini 的助手角色叫 "model"
      table.insert(contents, {
        role = "model",
        parts = { { text = msg.content } }
      })
    end
  end

  return vim.json.encode {
    system_instruction = system_instruction,
    contents = contents,
    generationConfig = {
      temperature = 0.1,
      topP = 0.95,
      topK = 40,
      maxOutputTokens = 1024,
    }
  }
end

-- OpenAI 响应解析
local function openai_parse_response(resp_body)
  local ok, obj = pcall(vim.json.decode, resp_body)
  if not ok then
    return nil, ('Failed to decode response JSON: %s'):format(obj)
  end

  local choice = obj.choices and obj.choices[1]
  local content = choice and choice.message and choice.message.content
  content = type(content) == 'string' and vim.trim(content) or ''
  if content == '' then
    return nil, 'OpenAI response missing `choices[1].message.content`'
  end

  return content
end

-- Gemini 响应解析
local function gemini_parse_response(resp_body)
  local ok, obj = pcall(vim.json.decode, resp_body)
  if not ok then
    return nil, ('Failed to decode response JSON: %s'):format(obj)
  end

  local candidate = obj.candidates and obj.candidates[1]
  local content = candidate and candidate.content and candidate.content.parts and candidate.content.parts[1] and candidate.content.parts[1].text
  content = type(content) == 'string' and vim.trim(content) or ''
  if content == '' then
    return nil, 'Gemini response missing `candidates[0].content.parts[0].text`'
  end

  return content
end

-- OpenAI 请求
local function openai_request(key, model, messages)
  local url = vim.g.gpt_commit_url or 'https://api.openai.com/v1/chat/completions'
  local body = openai_format_messages(model, messages)
  local headers = { 'Authorization: Bearer ' .. key }

  local resp_body, http_code = make_curl_request(url, headers, body)
  if not resp_body then
    return nil, http_code  -- http_code 实际上是错误信息
  end

  if http_code ~= 200 then
    return nil, ('OpenAI HTTP %s: %s'):format(tostring(http_code), vim.trim(resp_body))
  end

  return openai_parse_response(resp_body)
end

-- Gemini 请求（使用最新的 API 格式）
local function gemini_request(key, model, messages)
  local base_url = vim.g.gpt_commit_url or 'https://generativelanguage.googleapis.com/v1beta/models/'
  local url = base_url .. model .. ':generateContent'
  local body = gemini_format_messages(messages)

  -- 根据最新的 Gemini API 文档，API key 通过 x-goog-api-key header 传递
  local headers = { 'x-goog-api-key: ' .. key }

  local resp_body, http_code = make_curl_request(url, headers, body)
  if not resp_body then
    return nil, http_code
  end

  if http_code ~= 200 then
    return nil, ('Gemini HTTP %s: %s'):format(tostring(http_code), vim.trim(resp_body))
  end

  return gemini_parse_response(resp_body)
end

-- 智能选择请求函数（根据 URL 或模型名，优先使用 Gemini）
local function smart_request(key, model, messages)
  local url = vim.g.gpt_commit_url or ''

  -- 如果 URL 包含 openai，使用 OpenAI 格式
  if url:match('openai') or url:match('chat/completions') then
    return openai_request(key, model, messages)
  end

  -- 如果 URL 包含 gemini 或 generativelanguage，使用 Gemini 格式
  if url:match('gemini') or url:match('generativelanguage') then
    return gemini_request(key, model, messages)
  end

  -- 根据模型名判断
  if model:match('^gpt%-') then
    return openai_request(key, model, messages)
  elseif model:match('^gemini%-') then
    return gemini_request(key, model, messages)
  end

  -- 默认使用 Gemini（因为你的配置中默认是 gemini-flash-latest）
  return gemini_request(key, model, messages)
end

-- 获取 git 仓库根目录（兼容 worktree 和普通仓库）
local function get_repo_root(start_path)
  local root_res = vim.system({ 'git', '-C', start_path, 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  return root_res.code == 0 and vim.trim(root_res.stdout or '') or ''
end

function M.generate(repo_path)
  local key = vim.g.gpt_commit_key or os.getenv 'GITCOMMIT_API_KEY' or os.getenv 'OPENAI_API_KEY' or ''
  if key == '' then
    return nil, 'Missing API key: set vim.g.gpt_commit_key or env OPENAI_API_KEY'
  end

  local model = vim.g.gpt_commit_model or 'gemini-flash-latest'
  local max_lines = tonumber(vim.g.gpt_commit_max_lines) or 160
  local staged = (vim.g.gpt_commit_staged == nil) or (vim.g.gpt_commit_staged == 1)

  local root = get_repo_root(repo_path)
  if root == '' then
    return nil, ('Not a git repository: %s'):format(repo_path)
  end

  local diff_cmd = { 'git', '-C', root, 'diff' }
  if staged then
    table.insert(diff_cmd, '--staged')
  end
  local diff_res = vim.system(diff_cmd, { text = true }):wait()
  if diff_res.code ~= 0 then
    return nil, 'Failed to run `git diff`'
  end
  local diff = diff_res.stdout or ''

  if diff == '' and staged then
    diff = (vim.system({ 'git', '-C', root, 'diff' }, { text = true }):wait().stdout or '')
  end
  if diff == '' then
    return nil, 'No changes'
  end

  local lines = vim.split(diff, '\n', { plain = true })
  if #lines > max_lines then
    diff = table.concat(lines, '\n', 1, max_lines)
  end

  local messages = {
    { role = 'system', content = build_prompt() },
    { role = 'user', content = diff },
  }

  return smart_request(key, model, messages)
end

function M.cmd(_)
  -- 直接使用当前工作目录，兼容 worktree 和普通仓库
  local cwd = vim.uv.cwd() or vim.fn.getcwd()

  vim.notify('Generating commit message...', vim.log.levels.INFO, { title = 'GPTCommit' })

  local msg, err = M.generate(cwd)
  if not msg then
    vim.notify(err or 'Failed to generate commit message.', vim.log.levels.ERROR, { title = 'GPTCommit' })
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, vim.split(msg, '\n', { plain = true, trimempty = true }))
  vim.cmd 'redraw'
  vim.notify('Commit message generated.', vim.log.levels.INFO, { title = 'GPTCommit' })
end

return M

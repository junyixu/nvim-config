-- GPTCommit.lua（KISS）
--
-- 功能：根据 `git diff` 调用 OpenAI Chat Completions 生成 commit message。
-- 依赖：git、curl。
--
-- 命令：`:GptCommit [path]`
--   - `path` 为空：使用当前 buffer 所在目录；若无文件则用 cwd。
--   - 生成后：插入到当前 buffer（光标行上方）。
--
-- 配置：
--   - `vim.g.gpt_commit_key`（或环境变量 `GITCOMMIT_API_KEY`）
--   - `vim.g.gpt_commit_model`（默认 `gemini-flash-latest`）
--   - `vim.g.gpt_commit_url`（默认 `https://api.openai.com/v1/chat/completions`）
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

-- 约定：curl 输出 body，并在末尾追加一行 http_code（用 -w '\n%{http_code}'）
local function openai_request(key, model, messages)
  local url = vim.g.gpt_commit_url or 'https://gemini-balance.str0x0b.xyz/v1/chat/completions'
  local body = vim.json.encode { model = model, messages = messages }

  local curl = {
    'curl',
    '-sS',
    '-X',
    'POST',
    url,
    '-H',
    'Content-Type: application/json',
    '-H',
    'Authorization: Bearer ' .. key,
    '--data-binary',
    '@-',
    '-w',
    '\n%{http_code}',
  }

  local res = vim.system(curl, { text = true, stdin = body }):wait()
  if res.code ~= 0 then
    local detail = vim.trim((res.stderr or '') ~= '' and res.stderr or (res.stdout or ''))
    return nil, ('curl failed (%d): %s'):format(res.code, detail)
  end

  local out = res.stdout or ''
  local resp_body, http_code = out:match '^([%s%S]*)\n(%d+)%s*$'
  http_code = tonumber(http_code)
  if http_code ~= 200 then
    return nil, ('OpenAI HTTP %s: %s'):format(tostring(http_code), vim.trim(resp_body or out))
  end

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

function M.generate(repo_path)
  local key = vim.g.gpt_commit_key or os.getenv 'GITCOMMIT_API_KEY' or os.getenv 'OPENAI_API_KEY' or ''
  if key == '' then
    return nil, 'Missing API key: set vim.g.gpt_commit_key or env OPENAI_API_KEY'
  end

  local model = vim.g.gpt_commit_model or 'gemini-flash-latest'
  local max_lines = tonumber(vim.g.gpt_commit_max_lines) or 160
  local staged = (vim.g.gpt_commit_staged == nil) or (vim.g.gpt_commit_staged == 1)

  local root_res = vim.system({ 'git', '-C', repo_path, 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  local root = root_res.code == 0 and vim.trim(root_res.stdout or '') or ''
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

  return openai_request(key, model, messages)
end

function M.cmd(_)
  local bufname = vim.api.nvim_buf_get_name(0)
  -- 常见场景：在 `.git/COMMIT_EDITMSG` 里执行，需要把 repo root 当作工作目录
  -- 例如：`/repo/.git/COMMIT_EDITMSG` -> `/repo`
  local path = bufname ~= '' and (bufname:match '^(.*)/%.git/' or vim.fs.dirname(bufname)) or (vim.uv.cwd() or vim.fn.getcwd())

  vim.notify('Generating commit message...', vim.log.levels.INFO, { title = 'GPTCommit' })

  local msg, err = M.generate(path)
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

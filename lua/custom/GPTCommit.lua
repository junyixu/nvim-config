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

local function trim(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function split_lines(s)
  if s == '' then
    return {}
  end
  return vim.split(s, '\n', { plain = true })
end

local function limit_lines(text, max_lines)
  local lines = split_lines(text)
  if #lines <= max_lines then
    return text
  end
  return table.concat(lines, '\n', 1, max_lines)
end

local function stat_type(path)
  local st = vim.uv.fs_stat(path)
  return st and st.type or nil
end

local function is_dir(path)
  return stat_type(path) == 'directory'
end

local function is_file(path)
  return stat_type(path) == 'file'
end

-- 执行外部命令（新版）：返回 (exit_code, stdout, stderr)
local function sys(cmd, input)
  local res = vim.system(cmd, { text = true, stdin = input }):wait()
  return res.code, res.stdout or '', res.stderr or ''
end

local function normalize_path(arg)
  local path = trim(arg or '')
  if path:sub(1, 1) == '@' then
    path = path:sub(2)
  end

  if path == '' then
    local bufname = vim.api.nvim_buf_get_name(0)
    -- 常见场景：在 `.git/COMMIT_EDITMSG` 里执行，需要把 repo root 当作工作目录
    -- 例如：`/repo/.git/COMMIT_EDITMSG` -> `/repo`
    path = bufname:match '^(.*)/%.git/' or vim.fs.dirname(bufname)
  end

  if path:sub(1, 1) ~= '/' then
    path = vim.fs.joinpath(vim.uv.cwd(), path)
  end

  path = vim.fs.normalize(path)
  if is_file(path) then
    return vim.fs.dirname(path)
  end
  return path
end

local function git_root(path)
  local code, out = sys { 'git', '-C', path, 'rev-parse', '--show-toplevel' }
  if code ~= 0 then
    return nil
  end
  local root = trim(out)
  return root ~= '' and vim.fs.normalize(root) or nil
end

local function git_diff(root, staged)
  local args = { 'git', '-C', root, 'diff' }
  if staged then
    table.insert(args, '--staged')
  end
  local code, out = sys(args)
  if code ~= 0 then
    return nil
  end
  return out
end

local function build_prompt()
  return table.concat({
    'Generate a git commit message following conventional commit format, for my changes. eg:',
    '',
    '<type>(scope): <brief summary>',
    '',
    '- Explain technical improvement or benefit',
    '- Note any interface or behavior changes',
    '',
    'Requirements:',
    '- Header: conventional commit format, under 80 chars',
    '- Body: 2-3 bullet points starting with action verbs',
    '- Focus on WHAT changed and WHY, not HOW',
    '- Be specific',
    '- <type> is one of feat, fix, docs, style, refactor, perf, test, chore',
    '- Use meaningful scope if applicable, e.g.: feat(fugitive.vim)',
    '- Use present tense, imperative mood',
    '- Output only the commit message, no labels or formatting markers',
  }, '\n')
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

  local code, out, err = sys(curl, body)
  if code ~= 0 then
    local detail = trim(err) ~= '' and trim(err) or trim(out)
    return nil, ('curl failed (%d): %s'):format(code, detail)
  end

  local lines = split_lines(out)
  local http_code = tonumber(lines[#lines])
  local resp_body = table.concat(lines, '\n', 1, math.max(#lines - 1, 0))

  if http_code ~= 200 then
    return nil, ('OpenAI HTTP %s: %s'):format(tostring(http_code), trim(resp_body))
  end

  local ok, obj = pcall(vim.json.decode, resp_body)
  if not ok then
    return nil, ('Failed to decode response JSON: %s'):format(obj)
  end

  local choice = obj.choices and obj.choices[1]
  local content = choice and choice.message and choice.message.content
  if type(content) ~= 'string' or trim(content) == '' then
    return nil, 'OpenAI response missing choices[1].message.content'
  end

  return trim(content), nil
end

function M.generate(repo_path)
  local key = vim.g.gpt_commit_key or os.getenv 'GITCOMMIT_API_KEY' or os.getenv 'OPENAI_API_KEY' or ''
  if key == '' then
    return nil, 'Missing API key: set vim.g.gpt_commit_key or env OPENAI_API_KEY'
  end

  local model = vim.g.gpt_commit_model or 'gemini-flash-latest'
  local max_lines = tonumber(vim.g.gpt_commit_max_lines) or 160
  local staged = (vim.g.gpt_commit_staged == nil) or (vim.g.gpt_commit_staged == 1)

  local root = git_root(repo_path)
  if not root then
    return nil, 'Not a git repository: ' .. repo_path
  end

  local diff = git_diff(root, staged)
  if not diff then
    return nil, 'Failed to run git diff'
  end

  if trim(diff) == '' and staged then
    diff = git_diff(root, false) or ''
  end
  if trim(diff) == '' then
    return nil, 'No changes'
  end

  diff = limit_lines(diff, max_lines)

  local messages = {
    { role = 'system', content = build_prompt() },
    { role = 'user', content = diff },
  }

  return openai_request(key, model, messages)
end

function M.cmd(args)
  local path = normalize_path(args)
  if not is_dir(path) then
    vim.notify('Directory does not exist: ' .. path, vim.log.levels.ERROR)
    return
  end

  if vim.bo.buftype ~= '' or not vim.bo.modifiable or vim.bo.readonly then
    vim.notify('Buffer is not writable', vim.log.levels.ERROR)
    return
  end

  vim.notify('Generating commit message...', vim.log.levels.INFO, { title = 'GPTCommit' })

  local msg, err = M.generate(path)
  if not msg then
    vim.notify(err or 'Unknown error', vim.log.levels.ERROR)
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, split_lines(msg))
  vim.cmd 'redraw'
  vim.notify('Commit message generated.', vim.log.levels.INFO, { title = 'GPTCommit' })
end

return M

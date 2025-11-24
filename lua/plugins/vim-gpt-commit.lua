-- skywind3000/vim-gpt-commit – GPT generated commit messages

return {
  'skywind3000/vim-gpt-commit',
  config = function()
    vim.g.gpt_commit_key = 'sk-jyxu'
    vim.g.gpt_commit_prompt = {
      'Generate a git commit message following conventional commit format, for my changes. eg:',
      '<type>(scope): <brief summary>\n',
      '- Add/Fix/Remove/Update specific feature',
      '- Explain technical improvement or benefit',
      '- Note any interface or behavior changes',
      'Requirements:',
      '- Header: conventional commit format, under 50 chars',
      '- Body: 2-4 bullet points starting with action verbs',
      '- Focus on WHAT changed and WHY, not HOW',
      '- Be specific',
      '- Use present tense, imperative mood',
      '- Output only the commit message, no labels or formatting markers',
    }
    vim.g.gpt_commit_model = 'gemini-flash-latest'
    vim.g.gpt_commit_max_line = 1000
  end,
}

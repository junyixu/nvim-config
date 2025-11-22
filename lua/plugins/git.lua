-- Git related plugins

return {
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  { -- Git wrapper
    'tpope/vim-fugitive',
    config = function()
      vim.cmd [[nnoremap <leader>gdv :Gvdiffsplit<cr>
nnoremap <leader>gds :Ghdiffsplit<cr>
]]
    end,
  },

  { -- GPT Commit plugin
    'skywind3000/vim-gpt-commit',
    config = function()
      -- GitHub Copilot API Key
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

      -- Optional configurations:
      -- vim.g.gpt_commit_url = 'https://api-proxy.me/gemini'
      vim.g.gpt_commit_model = 'gemini-flash-latest'
      -- vim.g.gpt_commit_concise = 1
      -- vim.g.gpt_commit_lang = ''
      vim.g.gpt_commit_max_line = 1000
    end,
  },
}

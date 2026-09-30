-- pi.nvim (pablopunk/pi.nvim): inline "ask" bridge to the pi coding agent.
-- Sends the current buffer (or visual selection) as context to the `pi` CLI and
-- shows the reply via notify (float fallback). This is NOT an interactive
-- terminal-split TUI like claudecode.nvim: there is no persistent session panel,
-- it is one-shot question/answer. For the full pi TUI, run `pi` in a terminal.
--
-- Requires the `pi` CLI. pi.nvim's own defaults target openrouter/free, so
-- provider+model are pinned to the same OpenAI (ChatGPT) OAuth that ~/.pi/agent
-- is authed for. pi loads the symlinked ~/.pi/agent/CLAUDE.md and skills itself,
-- so no system_prompt override here.
--
-- Keys live under <leader>ap ("pi"), a subgroup of the <leader>a AI group that
-- claudecode.nvim owns.
---@type LazySpec
return {
  "pablopunk/pi.nvim",
  cmd = { "PiAsk", "PiAskSelection", "PiCancel", "PiLog" },
  keys = {
    { "<leader>ap", nil, desc = "pi" },
    { "<leader>apa", "<cmd>PiAsk<cr>", desc = "Ask pi (buffer)" },
    { "<leader>apa", "<cmd>PiAskSelection<cr>", mode = "v", desc = "Ask pi (selection)" },
    { "<leader>apx", "<cmd>PiCancel<cr>", desc = "Cancel pi request" },
    { "<leader>apl", "<cmd>PiLog<cr>", desc = "Open pi session log" },
  },
  opts = {
    -- Absolute path to the npm-global install, so it resolves regardless of how
    -- nvim inherited PATH.
    binary = vim.fn.expand "~/.npm-global/bin/pi",
    provider = "openai",
    model = "gpt-6-sol",
    thinking = "medium",
    skills = true,
    extensions = true,
  },
  config = function(_, opts) require("pi").setup(opts) end,
}

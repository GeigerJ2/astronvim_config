-- pi.nvim (pablopunk/pi.nvim): inline "ask" bridge to the pi coding agent.
-- Sends the current buffer (or visual selection) as context to the `pi` CLI and
-- shows the reply via notify (float fallback): one-shot question/answer. The
-- full interactive pi TUI is the <leader>apt terminal toggle below (a persistent
-- snacks split, mirroring the claudecode one).
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
  dependencies = { "folke/snacks.nvim" },
  cmd = { "PiAsk", "PiAskSelection", "PiCancel", "PiLog" },
  keys = {
    { "<leader>ap", nil, desc = "pi" },
    { "<leader>apa", "<cmd>PiAsk<cr>", desc = "Ask pi (buffer)" },
    { "<leader>apa", "<cmd>PiAskSelection<cr>", mode = "v", desc = "Ask pi (selection)" },
    { "<leader>apx", "<cmd>PiCancel<cr>", desc = "Cancel pi request" },
    { "<leader>apl", "<cmd>PiLog<cr>", desc = "Open pi session log" },
    {
      "<leader>apt",
      function()
        -- Full pi TUI in a persistent, toggleable terminal (the real interactive
        -- agent, like the claudecode split). position=bottom + relative="editor"
        -- makes it a FULL-WIDTH bottom split under neo-tree/aerial, so tmux
        -- line-selection over the pi output does not cut across the sidebars.
        -- toggle reuses the same pi process, so the session persists across hides.
        require("snacks").terminal.toggle(vim.fn.expand "~/.pi/agent/bin/pi", {
          win = { position = "bottom", height = 0.45, relative = "editor" },
        })
      end,
      desc = "Toggle pi TUI (terminal split)",
    },
    {
      "<leader>apr",
      function()
        -- Same split as <leader>apt, but `pi --resume` so pi opens its session
        -- picker to attach a past session instead of starting fresh.
        require("snacks").terminal.toggle({ vim.fn.expand "~/.pi/agent/bin/pi", "--resume" }, {
          win = { position = "bottom", height = 0.45, relative = "editor" },
        })
      end,
      desc = "Resume pi TUI (session picker)",
    },
  },
  opts = {
    -- Absolute path to the managed install, so it resolves regardless of how
    -- nvim inherited PATH.
    binary = vim.fn.expand "~/.pi/agent/bin/pi",
    provider = "openai",
    model = "gpt-6.1-sol",
    thinking = "medium",
    skills = true,
    extensions = true,
  },
  config = function(_, opts) require("pi").setup(opts) end,
}

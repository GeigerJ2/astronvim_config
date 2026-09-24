-- Bridge Neovim to the Claude Code CLI (coder/claudecode.nvim). It runs a small
-- WebSocket server implementing Claude Code's IDE protocol, so the SAME `claude`
-- session (my skills, CLAUDE.md, MCP, code-review-graph) sees the active file,
-- visual selection, and diagnostics, and its edits come back as diffs to accept
-- in-editor. Additive: the tmux `claude` window still works as before.
--
-- Requires the `claude` CLI on PATH (terminal_cmd = nil uses "claude") and
-- snacks.nvim (ships with AstroNvim) for the terminal split.
--
-- Keys live under <leader>a ("AI"); pipeline.nvim moved to <leader>gp to free it.
---@type LazySpec
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal = {
      -- Bottom split at 33% height, not the default right vsplit: the right side
      -- is usually taken by aerial. Bottom placement needs the snacks provider
      -- (the native fallback only does left/right); snacks_win_opts overrides the
      -- provider's default position/size.
      provider = "snacks",
      -- position=bottom with relative="win" makes snacks use `belowright`, so the
      -- split sits under the editor column only and neo-tree keeps its full height
      -- on the left (relative="editor" would `botright` full-width, covering under
      -- neo-tree). height ~45% since Claude is used a lot.
      snacks_win_opts = {
        position = "bottom",
        height = 0.45,
        relative = "win",
        -- In the <Leader>gc / :ReviewCommits diffview tab, the split is wedged
        -- between the diff panes and the file-history panel, so 45% of the
        -- focused window comes out tiny. When Claude opens in a diffview tab, size
        -- it so the commit list (file-history panel) AND Claude together take the
        -- bottom half of the tab: claude = 50% of the tab minus the panel's 12
        -- rows (its win_config height in diffview.lua), leaving the diff panes the
        -- top half. Elsewhere the configured 45% stands. Scheduled so it runs
        -- after the diffview layout settles.
        on_win = function(self)
          local ok, lib = pcall(require, "diffview.lib")
          if not (ok and lib.get_current_view()) then return end
          local win = self.win
          vim.schedule(function()
            if win and vim.api.nvim_win_is_valid(win) then
              local usable = vim.o.lines - vim.o.cmdheight
              local file_history_rows = 12 -- mirrors file_history_panel.win_config in diffview.lua
              vim.api.nvim_win_set_height(win, math.max(6, math.floor(usable * 0.5) - file_history_rows))
            end
          end)
        end,
      },
      -- Land in terminal-normal mode, not insert, when the split is focused, so
      -- nvim keymaps (<leader> etc.) take precedence there. Press i/a to type to
      -- Claude, <C-\><C-n> to leave insert back to normal.
      auto_insert = false,
    },
    -- diff_opts = { layout = "vertical" }, -- "vertical" | "horizontal" | "unified"
  },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeSelectModel",
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
    "ClaudeCodeOpen",
    "ClaudeCodeClose",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
    },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}

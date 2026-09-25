-- Run CodeRabbit AI reviews locally, in nvim, instead of pushing to GitHub and
-- fetching its PR comments. Wraps the CodeRabbit CLI (`cr`); findings land as
-- buffer diagnostics (virtual text, signs, underline) with code actions, plus a
-- float summary and quickfix. Complements the GitHub CodeRabbit + /review-pr
-- flow: this is for a pass before pushing.
--
-- Prerequisites (one-time, outside nvim):
--   curl -fsSL https://cli.coderabbit.ai/install.sh | sh   (or: bash /tmp/install-coderabbit-cli.sh)
--   cr auth login
-- Verify wiring with :checkhealth coderabbit
---@type LazySpec
return {
  "smnatale/coderabbit.nvim",
  cmd = {
    "CodeRabbitReview",
    "CodeRabbitStop",
    "CodeRabbitClear",
    "CodeRabbitShow",
    "CodeRabbitRestore",
    "CodeRabbitQuickfix",
    "CodeRabbitHistory",
  },
  -- cli.binary points at the coderabbit-nvim shim (in ~/.local/bin via chezmoi):
  -- the plugin hardcodes `--no-color`, which CLI 0.8.x rejects, so the shim strips
  -- it and forwards to the real `coderabbit`. Drop this once the plugin is fixed.
  opts = { cli = { binary = "coderabbit-nvim" } },
  keys = {
    { "<Leader>gr", desc = "󰋚 CodeRabbit" },
    { "<Leader>grr", "<Cmd>CodeRabbitReview all<CR>", desc = "Review all changes" },
    { "<Leader>gru", "<Cmd>CodeRabbitReview uncommitted<CR>", desc = "Review uncommitted" },
    { "<Leader>grc", "<Cmd>CodeRabbitReview committed<CR>", desc = "Review committed (branch)" },
    { "<Leader>grs", "<Cmd>CodeRabbitShow<CR>", desc = "Show last review summary" },
    { "<Leader>grq", "<Cmd>CodeRabbitQuickfix<CR>", desc = "Findings to quickfix" },
    { "<Leader>grh", "<Cmd>CodeRabbitHistory<CR>", desc = "Review history" },
    { "<Leader>grx", "<Cmd>CodeRabbitClear<CR>", desc = "Clear findings" },
    { "<Leader>grX", "<Cmd>CodeRabbitStop<CR>", desc = "Stop running review" },
  },
}

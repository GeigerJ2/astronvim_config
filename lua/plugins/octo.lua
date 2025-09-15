---@type LazySpec
return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  cmd = "Octo",
  opts = {
    enable_builtin = true,
  },
  keys = {
    { "<leader>O", "<cmd>Octo<cr>", desc = "Octo" },
    -- { "<leader>Op", "<cmd>Octo pr list<cr>", desc = "List PRs" },
    -- { "<leader>Oi", "<cmd>Octo issue list<cr>", desc = "List Issues" },
    -- { "<leader>Or", "<cmd>Octo pr list review-requested<cr>", desc = "PRs waiting for review" },
  },
}

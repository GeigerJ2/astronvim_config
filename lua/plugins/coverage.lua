-- plugins/coverage.lua
return {
  "andythigpen/nvim-coverage",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>tc", "<cmd>Coverage<cr>", desc = "Load coverage" },
    { "<leader>tC", "<cmd>CoverageHide<cr>", desc = "Hide coverage" },
    { "<leader>ts", "<cmd>CoverageSummary<cr>", desc = "Coverage summary" },
    { "<leader>tl", "<cmd>CoverageLoad<cr>", desc = "Load coverage file" },
    { "<leader>tt", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage" },
  },
  config = function()
    require("coverage").setup({
      commands = true, -- create commands
      auto_reload = true,
      highlights = {
        -- customize highlight groups created by the plugin
        covered = { fg = "#C3E88D" },   -- supports style, fg, bg, sp (see :h highlight-gui)
        uncovered = { fg = "#F07178" },
      },
      signs = {
        -- use your own highlight groups or text markers
        covered = { hl = "CoverageCovered", text = "▎" },
        uncovered = { hl = "CoverageUncovered", text = "▎" },
      },
      summary = {
        -- customize the summary pop-up
        min_coverage = 80.0,      -- minimum coverage threshold (used for highlighting)
      },
      lang = {
        -- customize language specific settings
        python = {
          -- Can specify coverage file path or let it auto-detect
          coverage_file = ".coverage", -- or "coverage.xml"
        },
        javascript = {
          coverage_file = "coverage/lcov.info",
        },
        typescript = {
          coverage_file = "coverage/lcov.info",
        },
      },
    })
  end,
}

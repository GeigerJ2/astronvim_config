---@type LazySpec
return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
    keys = {
      -- Extract refactors (visual mode)
      {
        "<Leader>re",
        function() require("refactoring").refactor("Extract Function") end,
        mode = "v",
        desc = "Extract function",
      },
      {
        "<Leader>rE",
        function() require("refactoring").refactor("Extract Function To File") end,
        mode = "v",
        desc = "Extract function to file",
      },
      {
        "<Leader>rv",
        function() require("refactoring").refactor("Extract Variable") end,
        mode = "v",
        desc = "Extract variable",
      },
      -- Inline (both modes)
      {
        "<Leader>ri",
        function() require("refactoring").refactor("Inline Variable") end,
        mode = { "n", "v" },
        desc = "Inline variable",
      },
      {
        "<Leader>rI",
        function() require("refactoring").refactor("Inline Function") end,
        desc = "Inline function",
      },
      -- Block extract (normal mode)
      {
        "<Leader>rb",
        function() require("refactoring").refactor("Extract Block") end,
        desc = "Extract block",
      },
      {
        "<Leader>rB",
        function() require("refactoring").refactor("Extract Block To File") end,
        desc = "Extract block to file",
      },
      -- Debug helpers
      {
        "<Leader>rp",
        function() require("refactoring").debug.printf({ below = true }) end,
        desc = "Debug print",
      },
      {
        "<Leader>rdv",
        function() require("refactoring").debug.print_var() end,
        mode = { "n", "v" },
        desc = "Debug print variable",
      },
      {
        "<Leader>rdc",
        function() require("refactoring").debug.cleanup() end,
        desc = "Debug print cleanup",
      },
      -- Telescope picker for all refactors
      {
        "<Leader>rr",
        function() require("telescope").extensions.refactoring.refactors() end,
        mode = "v",
        desc = "Refactoring menu",
      },
    },
    config = function(_, opts)
      require("refactoring").setup(opts)
      require("telescope").load_extension("refactoring")
    end,
  },
}

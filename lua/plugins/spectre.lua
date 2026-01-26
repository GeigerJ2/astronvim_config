return {
  "nvim-pack/nvim-spectre",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    {
      "<leader>H",
      function() require("spectre").toggle() end,
      desc = "󰛔 Search & Replace (Spectre)",
    },
    {
      "<leader>Hw",
      function() require("spectre").open_visual { select_word = true } end,
      desc = "Search current word",
    },
  },
  config = function() require("spectre").setup() end,
}

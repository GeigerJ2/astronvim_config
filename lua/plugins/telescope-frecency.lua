---@type LazySpec
return {
  {
    "nvim-telescope/telescope-frecency.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function() require("telescope").load_extension("frecency") end,
    keys = {
      {
        "<Leader>fo",
        function() require("telescope").extensions.frecency.frecency({ workspace = "CWD" }) end,
        desc = "Find frecent files (cwd)",
      },
      {
        "<Leader>fO",
        function() require("telescope").extensions.frecency.frecency() end,
        desc = "Find frecent files (all)",
      },
    },
  },
}

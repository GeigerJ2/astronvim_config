---@type LazySpec
return {
  {
    "debugloop/telescope-undo.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function() require("telescope").load_extension("undo") end,
    keys = {
      { "<Leader>fu", "<cmd>Telescope undo<cr>", desc = "Find undo history" },
    },
  },
}

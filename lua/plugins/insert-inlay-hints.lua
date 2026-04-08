---@type LazySpec
return {
  "AbysmalBiscuit/insert-inlay-hints.nvim",
  dir = "/home/geiger_j/dev/lua/insert-inlay-hints.nvim",
  lazy = true,
  cmd = {
    "InsertHints",
    "InsertHintsPlugin",
  },
  keys = {
    { "<Leader>ic", "<cmd>InsertHints closest<cr>", desc = "Insert closest inlay hint" },
    { "<Leader>il", "<cmd>InsertHints line<cr>", desc = "Insert inlay hints on line" },
    { "<Leader>iv", "<cmd>InsertHints visual<cr>", mode = "v", desc = "Insert inlay hints in selection" },
    { "<Leader>ia", "<cmd>InsertHints all<cr>", desc = "Insert all inlay hints in buffer" },
  },
  opts = {},
}

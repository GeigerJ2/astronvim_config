return {
  "ellisonleao/glow.nvim",
  opts = {
    border = "none",
    width = 999,
    height = 999,
    width_ratio = 1.0,
    height_ratio = 1.0,
  },
  keys = {
    {
      "<leader>mg",
      function()
        vim.cmd "tabnew %"
        vim.cmd "Glow"
      end,
      desc = "Glow fullscreen (new tab)",
    },
  },
}

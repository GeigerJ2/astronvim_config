-- In your user/plugins config
return {
  {
    "declancm/maximize.nvim",
    config = function() require("maximize").setup() end,
    keys = {
      { "<leader>z", "<cmd>lua require('maximize').toggle()<cr>", desc = "Toggle Maximize" },
    },
  },
}

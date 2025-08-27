return {
  "ruifm/gitlinker.nvim",
  keys = {
    {
      "<leader>gy",
      function()
        require("gitlinker").get_buf_range_url("n", {
          action_callback = require("gitlinker.actions").copy_to_clipboard,
        })
      end,
      desc = "Copy git permalink",
      mode = "n",
    },
    {
      "<leader>gy",
      function()
        require("gitlinker").get_buf_range_url("v", {
          action_callback = require("gitlinker.actions").copy_to_clipboard,
        })
      end,
      desc = "Copy git permalink",
      mode = "v",
    },
  },
}

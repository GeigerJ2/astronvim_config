-- In your user/plugins config
return {
  {
    "declancm/maximize.nvim",
    config = function() require("maximize").setup() end,
    keys = {
      -- `<Leader>Z` (capital) avoids the `timeoutlen` delay from
      -- `<Leader>z{j,k,z}` fold mappings in `polish.lua`.
      { "<leader>Z", "<cmd>lua require('maximize').toggle()<cr>", desc = "Toggle Maximize" },
      -- <M-z>: same toggle, but also bound in terminal mode so it works from the
      -- claude split (where <leader>/Space goes to Claude). <cmd> keeps terminal
      -- insert, so Claude stays interactive while fullscreen. Press again to
      -- restore. (F11/Alt-Enter avoided: Windows Terminal grabs those.)
      {
        "<M-z>",
        "<cmd>lua require('maximize').toggle()<cr>",
        mode = { "n", "t" },
        desc = "Toggle Maximize (fullscreen)",
      },
    },
  },
}

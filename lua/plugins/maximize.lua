-- In your user/plugins config
return {
  {
    "declancm/maximize.nvim",
    config = function() require("maximize").setup() end,
    keys = {
      -- `<Leader>Z` (capital) avoids the `timeoutlen` delay from
      -- `<Leader>z{j,k,z}` fold mappings in `polish.lua`.
      { "<leader>Z", "<cmd>lua require('maximize').toggle()<cr>", desc = "Toggle Maximize" },
    },
  },
}

-- In your user/plugins config
-- With a single window there is nothing to maximize; calling toggle anyway
-- makes `:only` echo "Already only one window" behind a hit-enter prompt.
local function toggle_maximize()
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then require("maximize").toggle() end
end
return {
  {
    "declancm/maximize.nvim",
    config = function() require("maximize").setup() end,
    keys = {
      -- `<Leader>Z` (capital) avoids the `timeoutlen` delay from
      -- `<Leader>z{j,k,z}` fold mappings in `polish.lua`.
      { "<leader>Z", toggle_maximize, desc = "Toggle Maximize" },
      -- <M-z>: same toggle, but also bound in terminal mode so it works from the
      -- claude split (where <leader>/Space goes to Claude). <cmd> keeps terminal
      -- insert, so Claude stays interactive while fullscreen. Press again to
      -- restore. (F11/Alt-Enter avoided: Windows Terminal grabs those.)
      {
        "<M-z>",
        "<cmd>lua if #vim.api.nvim_tabpage_list_wins(0) > 1 then require('maximize').toggle() end<cr>",
        mode = { "n", "t" },
        desc = "Toggle Maximize (fullscreen)",
      },
    },
  },
}

-- goto-preview: `gd` without leaving the window. `gpd` opens the definition
-- in a floating preview that never touches the layout, which is what makes it
-- usable in octo review buffers and diffview splits, where a real `gd` jump
-- lands in odd places (file-history panel, another tab). Needs an attached
-- LSP client, so it works in normal buffers and octo's right (local-file)
-- pane, but not in diffview diffs or octo's left (base) pane.
---@type LazySpec
return {
  {
    "rmagatti/goto-preview",
    opts = {
      -- keep the cursor where the review is; <CR> inside the preview jumps there
      focus_on_open = false,
      dismiss_on_move = false,
      border = { "rounded", "rounded", "rounded", "rounded" },
    },
    keys = {
      {
        "gpd",
        function() require("goto-preview").goto_preview_definition() end,
        desc = "Preview definition (float)",
      },
      {
        "gpt",
        function() require("goto-preview").goto_preview_type_definition() end,
        desc = "Preview type definition (float)",
      },
      {
        "gP",
        function() require("goto-preview").close_all_win() end,
        desc = "Close preview floats",
      },
    },
  },
}

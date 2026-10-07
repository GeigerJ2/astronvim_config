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
      -- 8-cell table: the plugin forwards it untouched to nvim_open_win,
      -- which rejects the "rounded" string form here.
      border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
      -- the plugin anchors a 120x15 float at the symbol, which jumps around
      -- the screen; recenter on the editor at 70% size instead. <C-w>w focuses
      -- the float (scroll with j/k, <C-d>/<C-u>, <C-f>/<C-b>, <C-w>p jumps
      -- back), gP closes it.
      post_open_hook = function(_, win)
        local width = math.floor(vim.o.columns * 0.7)
        local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.7)
        vim.api.nvim_win_set_config(win, {
          relative = "editor",
          width = width,
          height = height,
          row = math.max(0, math.floor((vim.o.lines - vim.o.cmdheight - height) / 2)),
          col = math.max(0, math.floor((vim.o.columns - width) / 2)),
        })
      end,
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

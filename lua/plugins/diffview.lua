-- Make diffview's diff view feel like the octo review buffer (which is tuned in
-- octo.lua): wrapped + fully-unfolded diff windows, and hunk/file navigation on
-- the same keys. gitsigns' ]g/[g don't work in diffview (it doesn't attach to
-- diffview's blob buffers), so map ]g/[g here to Vim's native diff-change jump
-- (]c/[c), which is the real hunk navigation inside a diff.
---@type LazySpec
return {
  "sindrets/diffview.nvim",
  opts = function(_, opts)
    local actions = require "diffview.actions"

    opts.enhanced_diff_hunks = true

    -- Per diff-window look, mirroring the octo.lua show_diff tweaks.
    opts.hooks = vim.tbl_extend("force", opts.hooks or {}, {
      diff_buf_win_enter = function(_, winid)
        vim.wo[winid].wrap = true
        vim.wo[winid].linebreak = true
        vim.wo[winid].breakindent = true
        vim.wo[winid].smoothscroll = true
        vim.wo[winid].foldlevel = 99 -- start fully unfolded (diff folds context at 0)
      end,
    })

    opts.keymaps = opts.keymaps or {}
    local view = opts.keymaps.view or {}
    vim.list_extend(view, {
      -- ]g/[g: next/prev change (gitsigns' hunk keys don't fire in diffview).
      { "n", "]g", function() vim.cmd "normal! ]czz" end, { desc = "Next change" } },
      { "n", "[g", function() vim.cmd "normal! [czz" end, { desc = "Prev change" } },
      -- ]q/[q: cycle files across the whole diff, like octo review.
      { "n", "]q", actions.select_next_entry, { desc = "Next file" } },
      { "n", "[q", actions.select_prev_entry, { desc = "Prev file" } },
    })
    opts.keymaps.view = view

    return opts
  end,
}

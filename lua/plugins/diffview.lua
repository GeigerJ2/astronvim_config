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
      -- ]C/[C: next/prev commit in a file-history / :PRCommits review.
      { "n", "]C", actions.select_next_commit, { desc = "Next commit" } },
      { "n", "[C", actions.select_prev_commit, { desc = "Prev commit" } },
    })
    opts.keymaps.view = view

    -- Selecting an entry in either panel should drop the cursor into the diff so
    -- ]g works immediately, instead of leaving the cursor on the file/commit
    -- list. focus_entry is select_entry's focus-the-diff twin: view:set_file(_,
    -- true) vs false. It still toggles folds on folder/commit headers, so it's
    -- safe to bind on the same keys. Also expose ]C/[C there.
    for _, panel in ipairs { "file_panel", "file_history_panel" } do
      local maps = opts.keymaps[panel] or {}
      vim.list_extend(maps, {
        { "n", "<cr>", actions.focus_entry, { desc = "Open diff and focus it" } },
        { "n", "o", actions.focus_entry, { desc = "Open diff and focus it" } },
        { "n", "]C", actions.select_next_commit, { desc = "Next commit" } },
        { "n", "[C", actions.select_prev_commit, { desc = "Prev commit" } },
      })
      opts.keymaps[panel] = maps
    end

    return opts
  end,
}

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

    -- Force the two diff panes to an exact 50/50 split. diffview builds the
    -- layout with `aboveleft vsp` (diff_2_hor) in an async coroutine and opens
    -- the file panel separately; on a wide screen that sequence settles
    -- off-center (seen ~40/160 on the workstation), non-deterministically,
    -- because the split happens across several event-loop ticks (and the real
    -- terminal reports its final width late). `equalalways` doesn't fix it (it
    -- only re-equalizes on split/close). A single scheduled re-center loses the
    -- race, so instead we re-center on *every* window resize until it settles.
    -- The guard stops our own nvim_win_set_width from recursing via WinResized;
    -- the 1-col tolerance treats floor()'s odd-width remainder as centered.
    local centering = false
    local function center_diff_split(view)
      if centering then return end
      local layout = view and view.cur_layout
      local a = layout and layout.a and layout.a.id
      local b = layout and layout.b and layout.b.id
      if not (a and b and vim.api.nvim_win_is_valid(a) and vim.api.nvim_win_is_valid(b)) then return end
      -- Only when the panes are actually side by side (same row); skip vertical
      -- or single-window layouts, where a width split is meaningless.
      if vim.api.nvim_win_get_position(a)[1] ~= vim.api.nvim_win_get_position(b)[1] then return end
      local wa, wb = vim.api.nvim_win_get_width(a), vim.api.nvim_win_get_width(b)
      local half = math.floor((wa + wb) / 2)
      if math.abs(wa - half) <= 1 then return end -- already centered; avoid churn/ping-pong
      centering = true
      vim.api.nvim_win_set_width(a, half)
      centering = false
    end

    -- Re-center every open view (get_current_view only sees the focused tab, but
    -- the rev flow parks :PRCommits in a background tab), on any resize.
    local function center_all()
      local ok, lib = pcall(require, "diffview.lib")
      if not ok then return end
      for _, view in ipairs(lib.views or {}) do center_diff_split(view) end
    end

    -- Per diff-window look, mirroring the octo.lua show_diff tweaks.
    opts.hooks = vim.tbl_extend("force", opts.hooks or {}, {
      diff_buf_win_enter = function(_, winid)
        vim.wo[winid].wrap = true
        vim.wo[winid].linebreak = true
        vim.wo[winid].breakindent = true
        vim.wo[winid].smoothscroll = true
        vim.wo[winid].foldlevel = 99 -- start fully unfolded (diff folds context at 0)
      end,
      -- Kick a first center once a/b exist (view_opened is too early; the diff
      -- windows are created async afterwards). WinResized then keeps it centered
      -- through the rest of the async layout and any terminal-size settle.
      view_post_layout = function(view) vim.schedule(function() center_diff_split(view) end) end,
    })

    vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
      group = vim.api.nvim_create_augroup("diffview_center_split", { clear = true }),
      desc = "Keep diffview's two diff panes at an exact 50/50 split",
      callback = function() vim.schedule(center_all) end,
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
      -- g=: force the two diff panes back to 50/50 (same as native <C-w>=).
      { "n", "g=", function() center_all() end, { desc = "Center diff panes 50/50" } },
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

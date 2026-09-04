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

    -- Per diff-window look, mirroring the octo.lua show_diff tweaks. The 50/50
    -- pane balancing is handled for both diffview and octo review together by the
    -- equalize_diff_panes autocmd in astrocore.lua (it runs <C-w>= on the review
    -- tab after the async layout / terminal settle).
    opts.hooks = vim.tbl_extend("force", opts.hooks or {}, {
      diff_buf_win_enter = function(_, winid)
        vim.wo[winid].wrap = true
        vim.wo[winid].linebreak = true
        vim.wo[winid].breakindent = true
        vim.wo[winid].smoothscroll = true
        vim.wo[winid].foldlevel = 99 -- start fully unfolded (diff folds context at 0)
      end,
    })

    -- `L` (open_commit_log) pops the commit message in a centred float. Diffview's own default
    -- caps it at `math.min(100, columns)` x `math.min(24, lines)` (see
    -- ui/panels/commit_log_panel.lua `default_config_float`), and 24 rows is the pinch: commit
    -- bodies wrap at 72 columns, so width is rarely the constraint, but a long body scrolls out of
    -- a 24-row box. Grow it, mostly vertically, and keep it centred so it stays where the eye is.
    --
    -- A function, not a table: `Panel:get_config()` calls `win_config` when it's callable, so this
    -- is recomputed on every open and follows terminal resizes.
    opts.commit_log_panel = opts.commit_log_panel or {}
    opts.commit_log_panel.win_config = function()
      local usable_height = vim.o.lines - vim.o.cmdheight
      -- 72-col bodies plus `git log`'s 4-space indent and a little slack; no point going wider.
      local width = math.min(120, math.floor(vim.o.columns * 0.9))
      local height = math.floor(usable_height * 0.8)
      return {
        type = "float",
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((usable_height - height) / 2),
      }
    end

    -- ]g / [g: next/prev change, cascading past the ends of a file.
    --
    -- gitsigns' hunk keys don't fire in diffview (it doesn't attach to diffview's blob buffers),
    -- so these drive Vim's native diff-change motion instead. Plain ]c stops dead at the last
    -- change in a file, which mid-review means reaching for ]q on every file boundary. When the
    -- cursor doesn't move, fall through to the next entry -- exactly what ]q does.
    --
    -- In a file-history view (`:PRCommits`) that fall-through crosses commits for free: the panel
    -- walks files by offset (`set_file_by_offset` -> `_get_entry_by_file_offset`), so running off
    -- the end of one commit's files lands on the next commit's first file.
    local function change_or_entry(motion, select_entry)
      return function()
        local before = vim.api.nvim_win_get_cursor(0)
        pcall(vim.cmd, "normal! " .. motion)
        if vim.api.nvim_win_get_cursor(0)[1] ~= before[1] then
          vim.cmd "normal! zz"
        else
          select_entry()
        end
      end
    end

    opts.keymaps = opts.keymaps or {}
    local view = opts.keymaps.view or {}
    vim.list_extend(view, {
      { "n", "]g", change_or_entry("]c", actions.select_next_entry), { desc = "Next change (or file)" } },
      { "n", "[g", change_or_entry("[c", actions.select_prev_entry), { desc = "Prev change (or file)" } },
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

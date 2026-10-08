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

    -- Land on the first change when a diff buffer is first displayed, so file
    -- selection lands on the hunk instead of the top of the file. The visited
    -- flag keeps later visits (and manual positions) intact; the jump is
    -- scheduled so it runs after diffview settles the layout. Mirrors the
    -- octo `octo_first_change` autocmd.
    local function goto_first_change(bufnr, winid)
      if vim.b[bufnr].diffview_first_change_done then return end
      vim.b[bufnr].diffview_first_change_done = true
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then return end
        vim.api.nvim_win_call(winid, function()
          vim.cmd "normal! gg"
          if vim.fn.diff_hlID(1, 1) == 0 then vim.cmd "silent! normal! ]c" end
          vim.cmd "normal! zz"
        end)
      end)
    end

    opts.enhanced_diff_hunks = true

    -- Per diff-window look, mirroring the octo.lua show_diff tweaks. The 50/50
    -- pane balancing is handled for both diffview and octo review together by the
    -- equalize_diff_panes autocmd in astrocore.lua (it runs <C-w>= on the review
    -- tab after the async layout / terminal settle).
    opts.hooks = vim.tbl_extend("force", opts.hooks or {}, {
      diff_buf_win_enter = function(bufnr, winid)
        vim.wo[winid].wrap = true
        vim.wo[winid].linebreak = true
        vim.wo[winid].breakindent = true
        vim.wo[winid].smoothscroll = true
        vim.wo[winid].foldlevel = 99 -- start fully unfolded (diff folds context at 0)
        goto_first_change(bufnr, winid)
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

    -- The file-history panel (:ReviewCommits, <Leader>gc) is the commit list at the
    -- bottom. Its diff windows are where the review happens, so halve the panel's
    -- default 16-row height to give the diff more room; the list stays scrollable.
    opts.file_history_panel = opts.file_history_panel or {}
    opts.file_history_panel.win_config =
      vim.tbl_extend("force", opts.file_history_panel.win_config or {}, { height = 12 })

    -- ]g / [g: next/prev change, cascading past the ends of a file.
    --
    -- gitsigns' hunk keys don't fire in diffview (it doesn't attach to diffview's blob buffers),
    -- so these drive Vim's native diff-change motion instead. Plain ]c stops dead at the last
    -- change in a file, which mid-review means reaching for ]q on every file boundary. When the
    -- cursor doesn't move, fall through to the next entry -- exactly what ]q does.
    --
    -- In a file-history view (`:ReviewCommits`) that fall-through crosses commits for free: the panel
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

    -- Position tracking across file-history refetches (`R`, :DiffviewRefresh).
    -- Refetching is how a folded-in change (amend / rebase --autosquash) shows
    -- up, but diffview wipes cur_item on update and the mid-stream render jumps
    -- to the first commit's first file, losing your place. Snapshot the position
    -- by commit INDEX + file PATH (the SHAs are rewritten, so the old entry
    -- object is gone, but the Nth commit -- same count -- and the path survive),
    -- then re-select after the refetch. set_file(_, false) reopens that diff and
    -- highlights the entry without leaving the panel.
    local function snapshot_fh_pos(panel)
      local cur_entry, cur_file = panel.cur_item[1], panel.cur_item[2]
      local idx
      if cur_entry then
        for i, e in ipairs(panel.entries) do
          if e == cur_entry then
            idx = i
            break
          end
        end
      end
      return { idx = idx, path = cur_file and cur_file.path or nil }
    end

    local function restore_fh_pos(view, panel, snap)
      if snap.idx == nil and snap.path == nil then return end
      local entries = panel.entries
      if not entries or #entries == 0 then return end
      local entry = (snap.idx and entries[snap.idx]) or entries[1]
      local file
      if entry and entry.files then
        if snap.path then
          for _, f in ipairs(entry.files) do
            if f.path == snap.path then
              file = f
              break
            end
          end
        end
        file = file or entry.files[1]
      end
      if file then view:set_file(file, false) end
    end

    local function refresh_keep_pos()
      local vlib = require "diffview.lib"
      local v = vlib.get_current_view()
      if not (v and v.panel and v.panel.update_entries) then return end
      local panel, snap = v.panel, snapshot_fh_pos(v.panel)
      panel:update_entries(function() restore_fh_pos(v, panel, snap) end)
    end

    -- Make every file-history refetch position-preserving, including
    -- :DiffviewRefresh (whose listener otherwise leaves you on the topmost
    -- commit). An empty snapshot (fresh open) restores nothing.
    local FileHistoryPanel =
      require("diffview.scene.views.file_history.file_history_panel").FileHistoryPanel
    local orig_update_entries = FileHistoryPanel.update_entries
    FileHistoryPanel.update_entries = function(self, callback)
      local snap = snapshot_fh_pos(self)
      return orig_update_entries(self, function(entries, status, msg)
        if callback then callback(entries, status, msg) end
        restore_fh_pos(self.parent, self, snap)
      end)
    end

    opts.keymaps = opts.keymaps or {}
    local view = opts.keymaps.view or {}
    vim.list_extend(view, {
      { "n", "]g", change_or_entry("]c", actions.select_next_entry), { desc = "Next change (or file)" } },
      { "n", "[g", change_or_entry("[c", actions.select_prev_entry), { desc = "Prev change (or file)" } },
      -- ]q/[q: cycle files across the whole diff, like octo review.
      { "n", "]q", actions.select_next_entry, { desc = "Next file" } },
      { "n", "[q", actions.select_prev_entry, { desc = "Prev file" } },
      -- ]C/[C: next/prev commit in a file-history / :ReviewCommits review.
      { "n", "]C", actions.select_next_commit, { desc = "Next commit" } },
      { "n", "[C", actions.select_prev_commit, { desc = "Prev commit" } },
      -- L: commit message float, like in the file-history panel.
      { "n", "L", actions.open_commit_log, { desc = "Show commit message" } },
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

    -- Open the commit under the cursor as a full diff (`<sha>^!`: all files at
    -- once, like the GitHub commit view) and land in the right pane so ]g
    -- walks the changes immediately. `y` (built-in) copies its hash.
    local function open_commit_full()
      local vlib = require "diffview.lib"
      local v = vlib.get_current_view()
      local panel = v and v.panel
      if not (panel and panel.get_item_at_cursor) then return end
      local item = panel:get_item_at_cursor()
      local hash = item and item.commit and item.commit.hash
      if not hash or hash == "" then
        vim.notify("No commit under cursor", vim.log.levels.WARN)
        return
      end
      vim.cmd("DiffviewOpen " .. hash .. "^!")
      vim.schedule(function()
        local cur = vlib.get_current_view()
        local layout = cur and cur.cur_layout
        local main = layout and layout.get_main_win and layout:get_main_win()
        local winid = type(main) == "number" and main or (main and main.id)
        if type(winid) == "number" and vim.api.nvim_win_is_valid(winid) then
          vim.api.nvim_set_current_win(winid)
        end
      end)
    end

    -- Position-preserving refresh, only for the commit-review panel.
    local fhp = opts.keymaps.file_history_panel or {}
    vim.list_extend(fhp, {
      { "n", "R", refresh_keep_pos, { desc = "Refresh, keep position" } },
      { "n", "gd", open_commit_full, { desc = "Open full commit diff (all files)" } },
    })
    opts.keymaps.file_history_panel = fhp

    return opts
  end,
}

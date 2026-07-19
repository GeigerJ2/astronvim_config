-- `Z` = recursive expand-all that *survives* buffer switches.
--
-- AstroNvim enables `filesystem.follow_current_file`. On every buffer
-- switch neo-tree's `show_only_explicitly_opened()` collapses any expanded
-- directory that is neither an ancestor of the current file nor present in
-- `state.explicitly_opened_nodes`. The built-in `expand_all_nodes` never
-- registers nodes there, so a `Z` expand is undone on the next switch.
--
-- This mirrors the built-in (`neo-tree/sources/common/commands.lua`
-- `expand_all_nodes`) but, in the async completion callback, pins every
-- expanded directory into `explicitly_opened_nodes` so follow-current-file
-- leaves the whole tree open. A later `z` (close-all) or a manual collapse
-- naturally returns those branches to normal follow behaviour.
local function expand_all_sticky(state)
  local renderer = require "neo-tree.ui.renderer"
  local node_expander = require "neo-tree.sources.common.node_expander"
  local async = require "plenary.async"

  -- The filesystem source loads directories lazily; its prefetcher is what
  -- lets the recursive expander descend into not-yet-scanned dirs. Without
  -- it the no-op default_prefetcher is used and only already-loaded (top)
  -- nodes expand -- i.e. "only one level". This mirrors exactly what
  -- neo-tree's own filesystem `expand_all_nodes` passes.
  local prefetcher = nil
  if state.name == "filesystem" then
    local ok_fs, fs = pcall(require, "neo-tree.sources.filesystem")
    if ok_fs then prefetcher = fs.prefetcher end
  end

  local root_nodes = state.tree:get_nodes()
  renderer.position.set(state, nil)

  local task = function()
    for _, root in pairs(root_nodes) do
      node_expander.expand_directory_recursively(state, root, prefetcher)
    end
  end

  async.run(task, function()
    state.explicitly_opened_nodes = state.explicitly_opened_nodes or {}
    for _, id in ipairs(renderer.get_expanded_nodes(state.tree)) do
      state.explicitly_opened_nodes[id] = true
    end
    renderer.redraw(state)
  end)
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    -- `Z`: recursive expand-all that survives buffer switches (see the
    -- expand_all_sticky comment above for the why). Top-level `commands`
    -- and `window.mappings` are merged into every source by neo-tree.
    opts.commands = opts.commands or {}
    opts.commands.expand_all_sticky = expand_all_sticky
    opts.window = opts.window or {}
    opts.window.mappings = opts.window.mappings or {}
    -- Mirror the built-in `z` (close_all_nodes). `Z` recursively expands
    -- every node and pins them, so follow_current_file doesn't re-collapse
    -- the tree when you switch buffers. Can be slow on huge trees (scans
    -- every subdir); respects filters.
    opts.window.mappings["Z"] = "expand_all_sticky"

    -- Override neo-tree's [g / ]g (default: prev_git_modified / next_git_modified)
    -- so they cycle through every file changed in the current PR -- the union of
    --   1. files committed on this branch since it diverged from base
    --   2. files with uncommitted modifications, staged or unstaged
    --   3. untracked files
    -- rather than only files reported by `git status` (which misses everything in
    -- 1 once it's been committed).

    -- Resolve the auto-detected base branch (origin/main -> origin/master ->
    -- main -> master) once per call. Returns the ref name or nil.
    local function detect_base()
      for _, ref in ipairs { "origin/main", "origin/master", "main", "master" } do
        vim.fn.system { "git", "rev-parse", "--verify", "--quiet", ref }
        if vim.v.shell_error == 0 then return ref end
      end
      return nil
    end

    -- Order paths the way neo-tree renders the tree top-to-bottom: at each level
    -- subdirectories come before sibling files, then case-insensitive name. This
    -- makes ]g / [g walk the visible tree in order, instead of raw ASCII order
    -- (which puts uppercase root files like README.md above lowercase dirs).
    local function tree_order(a, b)
      local pa = vim.split(a, "/", { plain = true })
      local pb = vim.split(b, "/", { plain = true })
      for i = 1, math.min(#pa, #pb) do
        if pa[i] ~= pb[i] then
          local a_is_dir, b_is_dir = i < #pa, i < #pb -- more components after => a dir here
          if a_is_dir ~= b_is_dir then return a_is_dir end -- dirs before files
          return pa[i]:lower() < pb[i]:lower()
        end
      end
      return #pa < #pb
    end

    -- Returns absolute paths of all PR files in tree order, deduped. nil + reason
    -- on failure (not in a repo, no base, etc.).
    local function get_pr_files()
      local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
      if vim.v.shell_error ~= 0 or not root or root == "" then
        return nil, "not a git repository"
      end
      local base = detect_base()
      if not base then return nil, "no base branch (origin/main, main, ...) found" end
      local merge_base = vim.fn.systemlist({ "git", "merge-base", "HEAD", base })[1]
      if vim.v.shell_error ~= 0 or not merge_base or merge_base == "" then
        return nil, "no merge-base with " .. base
      end

      local committed = vim.fn.systemlist { "git", "diff", "--name-only", merge_base .. "..HEAD" }
      local porcelain = vim.fn.systemlist { "git", "status", "--porcelain" }

      local seen, files = {}, {}
      local function add(rel)
        if rel and rel ~= "" and not seen[rel] then
          seen[rel] = true
          table.insert(files, root .. "/" .. rel)
        end
      end
      for _, rel in ipairs(committed) do add(rel) end
      for _, line in ipairs(porcelain) do
        -- Porcelain lines are "XY <path>" or "XY <old> -> <new>" for renames.
        local renamed = line:match "^.. .+ %-> (.+)$"
        add(renamed or line:match "^.. (.+)$")
      end
      table.sort(files, tree_order)
      return files
    end

    -- (root, merge_base) for the current repo/PR branch, or nil on any failure.
    local function pr_context()
      local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
      if vim.v.shell_error ~= 0 or root == nil or root == "" then return nil end
      local base = detect_base()
      if base == nil then return nil end
      local mb = vim.fn.systemlist({ "git", "merge-base", "HEAD", base })[1]
      if vim.v.shell_error ~= 0 or mb == nil or mb == "" then return nil end
      return root, mb
    end

    -- Point gitsigns' diff base at the PR merge-base, globally so files opened
    -- later inherit it too. Guarded so holding ]g doesn't re-diff on every press.
    -- Reset anytime with `:Gitsigns change_base` (back to HEAD).
    local last_gitsigns_base
    local function sync_gitsigns_base()
      local _, mb = pr_context()
      if mb == nil or mb == last_gitsigns_base then return end
      local ok, gs = pcall(require, "gitsigns")
      if ok then
        gs.change_base(mb, true)
        last_gitsigns_base = mb
      end
    end

    -- The main editor window: the one showing a normal (buftype="") buffer, i.e.
    -- NOT neo-tree / aerial / help / other plugin panes (those are "nofile"). nil
    -- if only the tree is open. Picking by buftype (not "first non-neo-tree win")
    -- matters once aerial auto-opens, else its pane gets mistaken for the editor.
    local function editor_win()
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then return w end
      end
      return nil
    end

    -- Open a path as a plain buffer in the editor window, so PR files are read
    -- full-width -- no octo side-by-side split. Splits if the tree is the only win.
    local function open_in_editor(path)
      local w = editor_win()
      if w then
        vim.api.nvim_win_call(w, function() vim.cmd("edit " .. vim.fn.fnameescape(path)) end)
      else
        vim.cmd("botright vsplit " .. vim.fn.fnameescape(path))
      end
    end

    local function navigate_pr(direction)
      return function(state)
        local files, err = get_pr_files()
        if not files or #files == 0 then
          vim.notify("No PR files: " .. (err or "list is empty"), vim.log.levels.WARN)
          return
        end
        -- Cycle relative to the file open in the editor (what you're reading). If
        -- none is open yet, the first ]g opens files[1] and [g opens the last.
        local ew = editor_win()
        local current = ew and vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(ew)) or ""
        -- Cycle by position in the tree-ordered list, wrapping at the ends.
        local idx
        for i, f in ipairs(files) do
          if f == current then
            idx = i
            break
          end
        end
        local target
        if idx == nil then
          target = direction == "next" and files[1] or files[#files]
        elseif direction == "next" then
          target = files[idx + 1] or files[1]
        else
          target = files[idx - 1] or files[#files]
        end
        if not target then return end
        -- Point gitsigns at the PR base so the opened file shows a colored sign
        -- column of everything the PR changed (vs HEAD, committed changes would
        -- show nothing). Then open the file plain in the editor window.
        sync_gitsigns_base()
        open_in_editor(target)
        -- Move the tree cursor onto the target so the selection follows what's
        -- open. neo-tree's reveal command loses the cursor when it has to expand
        -- collapsed parent dirs on a cold scan (the re-render resets to the top,
        -- so the FIRST ]g never moved). Drive navigate directly and re-focus the
        -- node in its completion callback, i.e. AFTER the scan + render settle.
        -- We stay in the tree window throughout, so focus never leaves it.
        require("neo-tree.sources.manager").navigate(state, nil, target, function()
          require("neo-tree.ui.renderer").focus_node(state, target)
        end, false)
      end
    end

    opts.filesystem = opts.filesystem or {}
    -- Open `nvim <dir>` (what `rev` runs) as a left SIDEBAR + an empty main
    -- window, instead of replacing the current window (AstroNvim's default is
    -- "open_current"). With open_current the tree lives in the main window, so a
    -- later neo-tree focus/reveal -- e.g. ]g's navigate_pr, or opening a file --
    -- spawns a SECOND neo-tree in the sidebar position, duplicating the tree.
    -- Starting as a sidebar keeps a single tree; files open in the main window.
    opts.filesystem.hijack_netrw_behavior = "open_default"
    opts.filesystem.window = opts.filesystem.window or {}
    opts.filesystem.window.mappings = vim.tbl_deep_extend(
      "force",
      opts.filesystem.window.mappings or {},
      {
        ["[g"] = { navigate_pr "prev", desc = "Prev PR-changed file" },
        ["]g"] = { navigate_pr "next", desc = "Next PR-changed file" },
        -- `/` fuzzy-search that KEEPS the filter on <CR>: type to filter the tree
        -- live, press Enter to close the input while keeping the matches, then
        -- browse them with j/k and open with <CR>. <Esc> aborts (restores the
        -- full tree); <C-x> clears a kept filter. (Shift-Enter is the built-in key
        -- for "keep filter" but terminals can't distinguish it from Enter.)
        ["/"] = { "fuzzy_finder", config = { keep_filter_on_submit = true } },
      }
    )

    -- === Per-file PR diff stats in the tree: +added / -removed vs the base ===
    -- Cache abspath -> {added, removed}, refreshed before each render (git diff
    -- --numstat is cheap). numstat of <merge-base> vs the working tree is the
    -- whole-PR change (committed + uncommitted) per tracked file.
    local pr_stats = {}
    local function refresh_pr_stats()
      pr_stats = {}
      local root, mb = pr_context()
      if root == nil then return end
      for _, line in ipairs(vim.fn.systemlist { "git", "diff", "--numstat", mb }) do
        local a, r, path = line:match "^(%S+)\t(%S+)\t(.+)$" -- binary files show "-\t-"
        if path then pr_stats[root .. "/" .. path] = { added = a, removed = r } end
      end
    end

    opts.event_handlers = opts.event_handlers or {}
    table.insert(opts.event_handlers, { event = "before_render", handler = refresh_pr_stats })

    -- Register pr_stats under the filesystem source, NOT top-level: neo-tree
    -- resolves a renderer's component names against the source's components
    -- table, so a top-level component renders as "Component pr_stats not found".
    opts.filesystem.components = opts.filesystem.components or {}
    opts.filesystem.components.pr_stats = function(_, node, _)
      if node.type ~= "file" then return {} end
      local s = pr_stats[node.path]
      if s == nil then return {} end
      return {
        { text = "+" .. s.added, highlight = "NeoTreeGitAdded" },
        { text = " -" .. s.removed .. " ", highlight = "NeoTreeGitDeleted" },
      }
    end

    -- Append pr_stats (right-aligned) to the file renderer's container, copying
    -- the live default so icons / name / git-status stay intact. Set on the
    -- filesystem source too: neo-tree filters out unknown components when it
    -- copies a *global* renderer into a source, which would drop pr_stats.
    local file_renderer = vim.deepcopy(require("neo-tree.defaults").renderers.file)
    for _, comp in ipairs(file_renderer) do
      if comp[1] == "container" and comp.content then
        table.insert(comp.content, { "pr_stats", zindex = 15, align = "right" })
        break
      end
    end
    opts.filesystem.renderers = opts.filesystem.renderers or {}
    opts.filesystem.renderers.file = file_renderer

    return opts
  end,
}

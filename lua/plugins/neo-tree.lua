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
    -- Hide completely untracked files in :PRTree. The git_status source hardcodes
    -- `untracked_files = "all"`, which pollutes a merge-base view (:PRTree) with
    -- scratch like COMMIT_MESSAGES.md. When a git_base is set (PRTree passes one;
    -- the normal Git tab does not), force `untracked_files = "no"` so only the PR's
    -- tracked changes show. Wrap once; the normal Git tab keeps its untracked.
    local git = require "neo-tree.git"
    if not git._prtree_no_untracked then
      local orig_status = git.status
      git.status = function(path, base_lookup, skip_bubbling, status_opts)
        if base_lookup ~= nil and next(base_lookup) ~= nil then
          status_opts = status_opts or {}
          status_opts.untracked_files = "no"
        end
        return orig_status(path, base_lookup, skip_bubbling, status_opts)
      end
      git._prtree_no_untracked = true
    end

    -- The git_status source (PRTree + the Git tab) maps `gg` to
    -- git_commit_and_push, which pops a "Commit message:" prompt instead of
    -- jumping to the top. Restore `gg` = go-to-top there; commits go through
    -- lazygit (<Leader>gg) / gcwd, never the tree. (gc/gp/ga/gu/gr stay.)
    opts.git_status = opts.git_status or {}
    opts.git_status.window = opts.git_status.window or {}
    opts.git_status.window.mappings = opts.git_status.window.mappings or {}
    opts.git_status.window.mappings["gg"] = function() vim.cmd "normal! gg" end

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

    -- The changed-file list, tree ordering and merge-base lookup live in
    -- lua/pr_files.lua, shared with ]q / [q in a normal buffer (polish.lua).
    local pr_files = require "pr_files"
    local get_pr_files = pr_files.list
    local pr_context = pr_files.context

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

    local function navigate_pr(direction)
      return function(state)
        local files, err = get_pr_files()
        if not files or #files == 0 then
          vim.notify("No PR files: " .. (err or "list is empty"), vim.log.levels.WARN)
          return
        end
        -- Cycle relative to the file under the TREE cursor, so ]g / [g just walk
        -- the changed files in the tree without opening anything (open with <CR>).
        local node = state.tree and state.tree:get_node()
        local cur = node and node.path or nil
        local target
        if cur ~= nil then
          target = pr_files.step(files, cur, direction)
        else
          target = direction == "next" and files[1] or files[#files]
        end
        if not target then return end
        -- Keep gitsigns pointed at the PR base so a file opened later (via <CR>)
        -- shows the whole-PR change in its sign column, not just vs HEAD.
        sync_gitsigns_base()
        -- Move the tree cursor onto target without opening it. navigate scans the
        -- (possibly cold) subdir so the node exists; expand_to_node then force-opens
        -- the ancestor dirs so the cursor lands even on the first visit, where a
        -- plain focus_node would bail and leave the cursor at the top level.
        local renderer = require "neo-tree.ui.renderer"
        require("neo-tree.sources.manager").navigate(state, nil, target, function()
          renderer.expand_to_node(state, target)
          renderer.focus_node(state, target, true)
        end, false)
      end
    end

    opts.filesystem = opts.filesystem or {}

    -- Show the contents of `github/` even though it's git-excluded.
    --
    -- `github/` (no dot) is untracked scratch space holding GitHub-bound drafts: PR bodies,
    -- issue drafts, review replies. It lives in the main worktree and is symlinked into every
    -- linked worktree, and it's excluded via `/github` in the repo's `info/exclude` so a stray
    -- `git add -A` can't sweep a draft into a commit. That exclude is exactly why AstroNvim's
    -- `hide_gitignored = true` collapsed it to "(N hidden items)".
    --
    -- `always_show_by_pattern` wins over the gitignore filter (renderer.lua checks
    -- `fby.always_show` before `hide_gitignored`). A pattern containing a separator is matched
    -- against the full path rather than the basename, via `string.find` -- so this is a plain
    -- substring test. The leading slash keeps it from also matching `.github/`, which would
    -- otherwise contain the substring `github/`.
    opts.filesystem.filtered_items = opts.filesystem.filtered_items or {}
    local always_show_by_pattern = opts.filesystem.filtered_items.always_show_by_pattern or {}
    table.insert(always_show_by_pattern, "/github/")
    opts.filesystem.filtered_items.always_show_by_pattern = always_show_by_pattern

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

    -- ]q / [q in the PRTree (git_status source): cycle PR files and open each in
    -- the editor, matching octo review and diffview / <Leader>gc muscle memory.
    -- Reuses navigate_pr, so it walks the same PR-file set and keeps the tree
    -- cursor synced. (git_status also keeps its default [g / ]g.)
    opts.git_status.window.mappings["]q"] = { navigate_pr "next", desc = "Next PR file" }
    opts.git_status.window.mappings["[q"] = { navigate_pr "prev", desc = "Prev PR file" }

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

    local function pr_stats_component(_, node, _)
      if node.type ~= "file" then return {} end
      local s = pr_stats[node.path]
      if s == nil then return {} end
      return {
        { text = "+" .. s.added, highlight = "NeoTreeGitAdded" },
        { text = " -" .. s.removed .. " ", highlight = "NeoTreeGitDeleted" },
      }
    end

    -- Copy the live default file renderer (so icons / name / git-status stay
    -- intact) and append pr_stats, right-aligned, to its container.
    local function file_renderer_with_stats()
      local renderer = vim.deepcopy(require("neo-tree.defaults").renderers.file)
      for _, comp in ipairs(renderer) do
        if comp[1] == "container" and comp.content then
          table.insert(comp.content, { "pr_stats", zindex = 15, align = "right" })
          break
        end
      end
      return renderer
    end

    -- Register on each source that shows PR files, NOT top-level: neo-tree
    -- resolves a renderer's component names against the source's own components
    -- table (a top-level component renders as "Component pr_stats not found"),
    -- and filters out unknown components when copying a global renderer into a
    -- source. filesystem = the rev/wt sidebar; git_status = :PRTree.
    for _, src in ipairs { "filesystem", "git_status" } do
      opts[src] = opts[src] or {}
      opts[src].components = opts[src].components or {}
      opts[src].components.pr_stats = pr_stats_component
      opts[src].renderers = opts[src].renderers or {}
      opts[src].renderers.file = file_renderer_with_stats()
    end

    return opts
  end,
}

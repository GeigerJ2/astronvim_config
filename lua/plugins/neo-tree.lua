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

    -- Returns absolute paths of all PR files, sorted, deduped. nil + reason on
    -- failure (not in a repo, no base, etc.).
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
      table.sort(files)
      return files
    end

    local function navigate_pr(direction)
      return function(state)
        local files, err = get_pr_files()
        if not files or #files == 0 then
          vim.notify("No PR files: " .. (err or "list is empty"), vim.log.levels.WARN)
          return
        end
        local node = state.tree:get_node()
        local current = node and node.path or ""
        local target
        if direction == "next" then
          for _, f in ipairs(files) do
            if f > current then
              target = f
              break
            end
          end
          target = target or files[1]
        else
          for i = #files, 1, -1 do
            if files[i] < current then
              target = files[i]
              break
            end
          end
          target = target or files[#files]
        end
        if target then
          -- Reveal the file in the existing neo-tree window, expanding any
          -- collapsed parent directories along the way.
          require("neo-tree.command").execute {
            action = "focus",
            source = "filesystem",
            reveal_file = target,
            reveal_force_cwd = false,
          }
        end
      end
    end

    opts.filesystem = opts.filesystem or {}
    opts.filesystem.window = opts.filesystem.window or {}
    opts.filesystem.window.mappings = vim.tbl_deep_extend(
      "force",
      opts.filesystem.window.mappings or {},
      {
        ["[g"] = { navigate_pr "prev", desc = "Prev PR-changed file" },
        ["]g"] = { navigate_pr "next", desc = "Next PR-changed file" },
      }
    )

    return opts
  end,
}

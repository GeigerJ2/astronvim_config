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
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      -- Top-level `commands` are merged into every source by neo-tree.
      commands = {
        expand_all_sticky = expand_all_sticky,
      },
      window = {
        mappings = {
          -- Mirror the built-in `z` (close_all_nodes). `Z` recursively
          -- expands every node and pins them, so follow_current_file
          -- doesn't re-collapse the tree when you switch buffers. Can be
          -- slow on huge trees (scans every subdir); respects filters.
          ["Z"] = "expand_all_sticky",
        },
      },
    },
  },
}

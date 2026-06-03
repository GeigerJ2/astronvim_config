-- Register a custom resession extension that restores neo-tree panels, which
-- are otherwise dropped from saved sessions (see lua/resession/extensions/
-- neotree.lua). lazy.nvim deep-merges this `opts` into AstroNvim's resession
-- spec, so the existing `astrocore` and `quickfix` extensions are preserved.

---@type LazySpec
return {
  "stevearc/resession.nvim",
  opts = {
    extensions = {
      neotree = {},
    },
  },
}

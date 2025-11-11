-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.rust" },
  -- { import = "astrocommunity.pack.python-ruff" },
  { import = "astrocommunity.git.diffview-nvim" },
  { import = "astrocommunity.git.neogit" },
  { import = "astrocommunity.git.gist-nvim" },
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.test.neotest" },
  { import = "astrocommunity.markdown-and-latex.glow-nvim" },
  -- import any community contributed plugins here
}
-- import/override with your plugins folder

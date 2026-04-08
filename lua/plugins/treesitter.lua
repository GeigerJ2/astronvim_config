-- Customize Treesitter
-- Treesitter config is now handled via AstroCore in v6.
-- nvim-treesitter is just a parser download utility.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      indent = true,
      auto_install = true,
      ensure_installed = {
        "python",
        "bash",
        "rust",
        "toml",
        "yaml",
        "json",
        "fish",
        "dockerfile",
        "lua",
        "vim",
      },
    },
  },
}

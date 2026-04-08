-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    -- c, lua, vim, vimdoc, query, markdown, markdown_inline are
    -- bundled with nvim 0.12 — do NOT list them here or they'll
    -- override the bundled (ABI-compatible) versions
    ensure_installed = {
      "python",
      "bash",
      "rust",
      "toml",
      "yaml",
      "json",
      "fish",
      "dockerfile",
    },
  },
}

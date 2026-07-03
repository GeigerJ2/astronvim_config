-- AstroUI provides the basis for configuring the AstroNvim User Interface
-- Configuration documentation can be found with `:h astroui`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    -- change colorscheme
    colorscheme = "astrodark",
    -- AstroUI allows you to easily modify highlight groups easily for any and all colorschemes
    -- folding = {
    --   enabled = true, -- Enable folding
    --   methods = { "lsp", "treesitter", "indent" }, -- Use LSP folding first, then fallback to treesitter and indent
    -- },
    folding = {
      -- whether a buffer should have folding can be true/false for global enable/disable or fun(bufnr:integer):boolean
      enabled = function(bufnr) return require("astrocore.buffer").is_valid(bufnr) end,
      -- a priority list of fold methods to try using, available methods are "lsp", "treesitter", and "indent"
      methods = { "lsp", "treesitter", "indent" },
    },
    highlights = {
      -- Single source of truth for diff-related highlight overrides (applies to
      -- all themes). DiffAdd/DiffDelete/DiffChange/DiffText are deliberately NOT
      -- overridden: those are the groups :Octo review's diff mode uses, and a
      -- solid background there hid the syntax highlighting — left at the
      -- colorscheme default so syntax shows through. The GitHub-style red/green
      -- backgrounds are scoped to diffview via its own DiffviewDiff* groups.
      init = {
        DiffviewDiffAdd = { bg = "#0d2818" },
        DiffviewDiffDelete = { bg = "#3d0f0f", fg = "#6e3535" },
        DiffviewDiffChange = { bg = "#1a3a4d" },
        DiffviewDiffText = { bg = "#1a4a1a" },
        -- Folded / collapsed hunk-separator lines.
        Folded = { bg = "#1c1c1c", fg = "#555555", italic = true },
        DiffviewFoldColumn = { bg = "#1c1c1c", fg = "#555555" },
      },
    },
    -- Icons can be configured throughout the interface
    icons = {
      -- configure the loading of the lsp in the status line
      LSPLoading1 = "⠋",
      LSPLoading2 = "⠙",
      LSPLoading3 = "⠹",
      LSPLoading4 = "⠸",
      LSPLoading5 = "⠼",
      LSPLoading6 = "⠴",
      LSPLoading7 = "⠦",
      LSPLoading8 = "⠧",
      LSPLoading9 = "⠇",
      LSPLoading10 = "⠏",
    },
  },
}

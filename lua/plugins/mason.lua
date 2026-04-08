-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- language servers
        "lua-language-server",
        "basedpyright",
        "pyright",
        "python-lsp-server",
        "ruff",
        "marksman",
        "bash-language-server",
        "clangd",
        "fish-lsp",
        "gopls",
        "json-lsp",
        "rust-analyzer",
        "taplo",
        "yaml-language-server",

        -- formatters
        "stylua",
        "fixjson",
        "prettierd",
        "shellharden",
        "tex-fmt",
        "yamlfmt",

        -- linters
        "mypy",
        "selene",
        "luacheck",
        "shellcheck",
        "yamllint",

        -- debuggers
        "debugpy",
        "codelldb",
        "bash-debug-adapter",

        -- other
        "ast-grep",
        "biome",
        "jq",

        -- tree-sitter-cli installed via cargo (mason's binary needs glibc 2.39)
      },
    },
  },
}

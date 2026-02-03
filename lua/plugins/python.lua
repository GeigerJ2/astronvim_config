-- Python LSP and linter configuration
return {
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "pyright" },
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = {
      ensure_installed = { "mypy", "ruff" },
      -- Disable auto-setup for mypy so we can configure it manually
      handlers = {
        mypy = function() end,
      },
    },
  },
}

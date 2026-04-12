-- Python LSP and linter configuration
return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- Only list servers here that should auto-install AND auto-enable.
      -- pyright and pylsp are installed via mason-tool-installer but
      -- toggled on manually via <Leader>lpl / <Leader>lpr.
      ensure_installed = { "basedpyright" },
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

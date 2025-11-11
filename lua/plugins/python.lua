-- Override python-ruff pack to keep basedpyright language services enabled
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      config = {
        basedpyright = {
          before_init = function(_, config)
            -- Ensure correct Python path
            local python_path = vim.fn.exepath "python3" or vim.fn.exepath "python"
            if config.settings and config.settings.python then config.settings.python.pythonPath = python_path end
          end,
          settings = {
            basedpyright = {
              -- CRITICAL: Override the community pack's setting
              disableLanguageServices = false,
              analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
                diagnosticMode = "openFilesOnly",
                diagnosticSeverityOverrides = {
                  reportGeneralTypeIssues = "error",
                  reportIncompatibleMethodOverride = "error",
                  reportOptionalMemberAccess = "warning",
                  reportOptionalSubscript = "warning",
                  reportPrivateImportUsage = "none",
                  reportUnusedFunction = "information",
                  reportUnusedImport = "information",
                  reportUnusedVariable = "information",
                },
              },
            },
          },
        },
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "basedpyright" },
    },
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = {
      ensure_installed = { "mypy", "ruff" },
    },
  },
}

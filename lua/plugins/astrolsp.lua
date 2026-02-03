-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      codelens = true, -- enable/disable codelens refresh on start
      inlay_hints = false, -- enable/disable inlay hints on start
      semantic_tokens = true, -- enable/disable semantic token highlighting
      fold = true, -- enable LSP folding
    },
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = false, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          -- "go",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 1000, -- default format timeout
      -- filter = function(client) -- fully override the default formatting function
      --   return true
      -- end
    },
    -- enable servers that you already have installed without mason
    servers = {
      "pyright",
      "ruff",
    },
    -- customize language server configuration options passed to `lspconfig`
    ---@diagnostic disable: missing-fields
    config = {
      -- clangd = { capabilities = { offsetEncoding = "utf-8" } },
      pyright = {
        before_init = function(_, config)
          -- Auto-detect Python path from various sources (uv, hatch, venv)
          local python_path = nil

          -- 1. Check VIRTUAL_ENV environment variable (active venv)
          local venv = vim.env.VIRTUAL_ENV
          if venv then python_path = venv .. "/bin/python" end

          -- 2. Check for local .venv in project root (uv/hatch/venv)
          if not python_path then
            local root = config.root_dir or vim.fn.getcwd()
            local local_venv = root .. "/.venv/bin/python"
            if vim.fn.executable(local_venv) == 1 then python_path = local_venv end
          end

          -- 3. Check for hatch environments
          if not python_path then
            local root = config.root_dir or vim.fn.getcwd()
            local handle = io.popen("cd " .. root .. " && hatch env find 2>/dev/null")
            if handle then
              local hatch_path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
              handle:close()
              if hatch_path ~= "" then python_path = hatch_path .. "/bin/python" end
            end
          end

          -- 4. Check for uv managed environment
          if not python_path then
            local root = config.root_dir or vim.fn.getcwd()
            local handle = io.popen("cd " .. root .. " && uv run which python 2>/dev/null")
            if handle then
              local uv_path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
              handle:close()
              if uv_path ~= "" and vim.fn.executable(uv_path) == 1 then python_path = uv_path end
            end
          end

          -- 5. Fallback to system python
          if not python_path then python_path = vim.fn.exepath "python3" or vim.fn.exepath "python" end

          -- Set the python path
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          config.settings.python.pythonPath = python_path

          vim.notify("Using Python: " .. python_path, vim.log.levels.INFO)
        end,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              autoImportCompletions = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      },
      ruff = {
        settings = {
          configurationPreference = "filesystemFirst",
          args = { "--ignore=PLC0415" },
          basedpyright = {
            disableLanguageServices = false,
          },
        },
      },
    },
    -- customize how language servers are attached
    handlers = {},
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
      lsp_codelens_refresh = {
        cond = "textDocument/codeLens",
        {
          event = { "InsertLeave", "BufEnter" },
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
          end,
        },
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
        ["<Leader>lb"] = {
          function() require("telescope.builtin").diagnostics { bufnr = 0 } end,
          desc = "Search buffer diagnostics",
        },
        ["<Leader>lq"] = {
          function() vim.diagnostic.setloclist() end,
          desc = "Buffer diagnostics to loclist",
        },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    on_attach = function(client, bufnr)
      -- this would disable semanticTokensProvider for all clients
      -- client.server_capabilities.semanticTokensProvider = nil
    end,
  },
}

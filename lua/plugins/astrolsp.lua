-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

-- Shared Python path detection (used by pyright and basedpyright)
local function detect_python_path(root_dir)
  -- 1. Check VIRTUAL_ENV environment variable (active venv)
  local venv = vim.env.VIRTUAL_ENV
  if venv then return venv .. "/bin/python" end

  local root = root_dir or vim.fn.getcwd()

  -- 2. Check for local .venv in project root (uv/hatch/venv)
  local local_venv = root .. "/.venv/bin/python"
  if vim.fn.executable(local_venv) == 1 then return local_venv end

  -- 3. Check for hatch environments
  local handle = io.popen("cd " .. root .. " && hatch env find 2>/dev/null")
  if handle then
    local hatch_path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
    handle:close()
    if hatch_path ~= "" then return hatch_path .. "/bin/python" end
  end

  -- 4. Check for uv managed environment
  handle = io.popen("cd " .. root .. " && uv run which python 2>/dev/null")
  if handle then
    local uv_path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
    handle:close()
    if uv_path ~= "" and vim.fn.executable(uv_path) == 1 then return uv_path end
  end

  -- 5. Fallback to system python
  return vim.fn.exepath "python3" or vim.fn.exepath "python"
end

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
        allow_filetypes = {},
        ignore_filetypes = {},
      },
      disabled = {},
      timeout_ms = 1000, -- default format timeout
    },
    -- enable servers that you already have installed without mason
    -- basedpyright is the default; pyright is configured but not auto-started (toggle with <leader>lpl)
    servers = {
      "basedpyright",
      "pyright",
      "ruff",
      "marksman",
    },
    -- customize language server configuration options passed to `lspconfig`
    ---@diagnostic disable: missing-fields
    config = {
      basedpyright = {
        before_init = function(_, config)
          local python_path = detect_python_path(config.root_dir)
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          config.settings.python.pythonPath = python_path
          vim.notify("basedpyright using Python: " .. python_path, vim.log.levels.INFO)
        end,
        settings = {
          basedpyright = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
              useLibraryCodeForTypes = true,
            },
          },
        },
      },
      pyright = {
        autostart = false, -- only started via <leader>lpl toggle
        before_init = function(_, config)
          local python_path = detect_python_path(config.root_dir)
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          config.settings.python.pythonPath = python_path
          vim.notify("pyright using Python: " .. python_path, vim.log.levels.INFO)
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
        capabilities = {
          general = {
            positionEncodings = { "utf-16" },
          },
        },
        settings = {
          configurationPreference = "filesystemFirst",
          args = { "--ignore=PLC0415" },
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
        ["<Leader>lps"] = {
          function()
            for _, client in ipairs(vim.lsp.get_clients { name = "pyright" }) do
              client:stop()
            end
            vim.cmd "LspStart basedpyright"
            vim.notify("Switched to basedpyright (strict)", vim.log.levels.INFO)
          end,
          desc = "LSP: strict (basedpyright)",
        },
        ["<Leader>lpl"] = {
          function()
            for _, client in ipairs(vim.lsp.get_clients { name = "basedpyright" }) do
              client:stop()
            end
            vim.cmd "LspStart pyright"
            vim.notify("Switched to pyright (lenient)", vim.log.levels.INFO)
          end,
          desc = "LSP: lenient (pyright)",
        },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    on_attach = function(client, bufnr) end,
  },
}

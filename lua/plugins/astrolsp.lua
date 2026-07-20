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

  -- 2. Check for local .venv in project root (uv/plain venv)
  local local_venv = root .. "/.venv/bin/python"
  if vim.fn.executable(local_venv) == 1 then return local_venv end

  -- 3. Check for hatch-style nested venvs (.venv/<env_name>/bin/python)
  local venv_dir = root .. "/.venv"
  if vim.fn.isdirectory(venv_dir) == 1 then
    local entries = vim.fn.readdir(venv_dir)
    for _, entry in ipairs(entries) do
      local candidate = venv_dir .. "/" .. entry .. "/bin/python"
      if vim.fn.executable(candidate) == 1 then return candidate end
    end
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

-- Query major.minor version from a Python interpreter
local function detect_python_version(python_path)
  local handle = io.popen(python_path .. ' -c "import sys; print(f\'{sys.version_info.major}.{sys.version_info.minor}\')" 2>/dev/null')
  if handle then
    local version = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
    handle:close()
    if version ~= "" then return version end
  end
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
      -- pyright and pylsp are NOT listed here; they are toggled on manually
      -- via <Leader>lpl and <Leader>lpr (vim.lsp.enable has no autostart concept)
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
          local version = detect_python_version(python_path)
          if version then
            config.settings.basedpyright = config.settings.basedpyright or {}
            config.settings.basedpyright.analysis = config.settings.basedpyright.analysis or {}
            config.settings.basedpyright.analysis.pythonVersion = version
          end
          vim.notify("basedpyright using Python " .. (version or "?") .. ": " .. python_path, vim.log.levels.INFO)
        end,
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
              useLibraryCodeForTypes = true,
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
                callArgumentNamesMatching = true,
                functionReturnTypes = true,
                genericTypes = true,
              },
              diagnosticSeverityOverrides = {
                -- basedpyright-only rules (no mypy equivalent)
                reportAny = "information",
                reportExplicitAny = "information",
                reportUnknownVariableType = "information",
                reportUnknownMemberType = "information",
                reportUnknownParameterType = "information",
                reportUnknownArgumentType = "information",
                reportUnknownReturnType = "information",
                reportUnknownLambdaType = "information",
                reportUnusedCallResult = "information",
                reportUninitializedInstanceVariable = "information",
                reportImplicitOverride = "information",
                reportDeprecated = "information",
                reportShadowedImports = "information",
                reportCallInDefaultInitializer = "information",
                reportImplicitStringConcatenation = "information",
                reportMissingSuperCall = "information",
                reportPropertyTypeMismatch = "information",
                reportUnnecessaryTypeIgnoreComment = "information",
                reportUntypedFunctionDecorator = "information",
                reportUntypedClassDecorator = "information",
                reportUntypedNamedTuple = "information",
                reportTypeCommentUsage = "information",
                reportMissingModuleSource = "information",
                reportIncompleteStub = "information",
                -- mypy relaxations from pyproject.toml (strict=true with overrides)
                reportMissingParameterType = "information", -- disallow_untyped_defs = false
                reportMissingReturnType = "information", -- disallow_untyped_defs = false
                reportUntypedBaseClass = "information", -- disallow_subclassing_any = false
                reportMissingTypeArgument = "information", -- disallow_any_generics = false
                -- ruff handles these (avoid duplicate diagnostics)
                reportUnusedImport = "information",
                reportUnusedVariable = "information",
                reportUnusedExpression = "information",
                reportUnannotatedClassAttribute = "information",
              },
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
      pylsp = {
        autostart = false, -- toggle on with <Leader>lpr when needed for refactoring
        before_init = function(_, config)
          local python_path = detect_python_path(config.root_dir)
          config.settings = config.settings or {}
          config.settings.pylsp = config.settings.pylsp or {}
          config.settings.pylsp.plugins = config.settings.pylsp.plugins or {}
          config.settings.pylsp.plugins.jedi = { environment = python_path }
        end,
        settings = {
          pylsp = {
            plugins = {
              -- disable features handled by basedpyright/ruff
              pycodestyle = { enabled = false },
              pyflakes = { enabled = false },
              mccabe = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              rope_completion = { enabled = false },
              jedi_completion = { enabled = false },
              jedi_definition = { enabled = false },
              jedi_hover = { enabled = false },
              jedi_references = { enabled = false },
              jedi_signature_help = { enabled = false },
              jedi_symbols = { enabled = false },
              -- rope: unique refactoring capabilities
              pylsp_rope = {
                enabled = true,
                -- disable features covered by ruff or refactoring.nvim
                organize_imports = false,
                extract_method = false,
                extract_global_method = false,
                extract_variable = false,
                extract_global_variable = false,
                -- keep unique rope features
                introduce_parameter = true,
                convert_local_to_field = true,
                use_function = true,
                generate_code = true,
                inline = true,
              },
              rope_rename = { enabled = true },  -- rename symbols and modules
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
          args = { "--ignore=PLC0415", "--extend-exclude=*.pyi" },
        },
      },
    },
    -- customize how language servers are attached
    handlers = {
      -- Prevent pyright and pylsp from auto-starting; they are toggled
      -- manually via <Leader>lpl and <Leader>lpr
      pyright = false,
      pylsp = false,
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
      lsp_codelens_refresh = {
        cond = "textDocument/codeLens",
        {
          event = { "InsertLeave", "BufEnter" },
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.enable(true, { bufnr = args.buf }) end
          end,
        },
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        ["g<C-d>"] = {
          function()
            vim.cmd "vsplit"
            vim.lsp.buf.definition()
          end,
          desc = "Go to definition in vsplit",
          cond = "textDocument/definition",
        },
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
              vim.lsp.stop(client.id)
            end
            vim.lsp.enable("basedpyright")
            vim.notify("Switched to basedpyright (strict)", vim.log.levels.INFO)
          end,
          desc = "LSP: strict (basedpyright)",
        },
        ["<Leader>lpl"] = {
          function()
            for _, client in ipairs(vim.lsp.get_clients { name = "basedpyright" }) do
              vim.lsp.stop(client.id)
            end
            vim.lsp.enable("pyright")
            vim.notify("Switched to pyright (lenient)", vim.log.levels.INFO)
          end,
          desc = "LSP: lenient (pyright)",
        },
        ["<Leader>lpr"] = {
          function()
            local clients = vim.lsp.get_clients { name = "pylsp" }
            if #clients > 0 then
              for _, client in ipairs(clients) do
                vim.lsp.stop(client.id)
              end
              vim.notify("pylsp stopped", vim.log.levels.INFO)
            else
              vim.lsp.enable("pylsp")
              vim.notify("pylsp started (rope refactoring)", vim.log.levels.INFO)
            end
          end,
          desc = "Toggle pylsp (rope refactoring)",
        },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    on_attach = function(client, bufnr) end,
  },
}

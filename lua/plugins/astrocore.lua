-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        relativenumber = true, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "auto", -- sets vim.opt.signcolumn to auto
        wrap = true, -- Enable line wrapping
        linebreak = true, -- Break at word boundaries
        showbreak = "↪ ", -- Show indicator for wrapped lines
        breakindent = true, -- Preserve indentation for wrapped
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    commands = {
      CommitMsg = {
        function(opts)
          local pr_num = opts.args
          local tmpfile = vim.fn.tempname() .. ".COMMIT_EDITMSG"
          vim.cmd("edit " .. tmpfile)
          vim.bo.filetype = "gitcommit"

          local title = "title"

          if pr_num ~= "" then
            local handle = io.popen("gh pr view " .. pr_num .. " --json title --jq .title 2>/dev/null")
            if handle then
              local result = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
              if result ~= "" then
                title = result .. " (#" .. pr_num .. ")"
              else
                vim.notify("Could not fetch PR #" .. pr_num, vim.log.levels.WARN)
              end
              handle:close()
            end
          end

          vim.api.nvim_buf_set_lines(0, 0, -1, false, { title, "", "" })
          vim.api.nvim_win_set_cursor(0, { 3, 0 })
        end,
        nargs = "?", -- Optional argument
        desc = "Edit commit message (optional PR number)",
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- navigate buffer tabs
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
        ["<Leader>vb"] = { "<C-v>", desc = "Visual block mode" },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,
        ["<leader>gm"] = {
          function()
            local tmpfile = vim.fn.tempname() .. ".COMMIT_EDITMSG"
            vim.cmd("edit " .. tmpfile)
            vim.bo.filetype = "gitcommit"
            vim.api.nvim_buf_set_lines(0, 0, -1, false, { "title", "", "" })
            vim.api.nvim_win_set_cursor(0, { 3, 0 })
          end,
          desc = "Edit commit message (scratch)",
        },
        ["<leader>f<CR>"] = { "<cmd>Telescope resume<cr>", desc = "Resume previous search" },
        ["<leader>lf"] = {
          function()
            require("telescope.builtin").lsp_document_symbols {
              symbols = { "function", "method" },
            }
          end,
          desc = "Search functions/methods",
        },
        ["<leader>lc"] = {
          function()
            require("telescope.builtin").lsp_document_symbols {
              symbols = { "class", "struct" },
            }
          end,
          desc = "Search classes",
        },
        -- ["<leader>lF"] = {
        --   function()
        --     require("telescope.builtin").lsp_workspace_symbols {
        --       symbols = { "function", "method" },
        --     }
        --   end,
        --   desc = "Search functions (workspace)",
        -- },
        -- ["<leader>lC"] = {
        --   function()
        --     require("telescope.builtin").lsp_workspace_symbols {
        --       symbols = { "class", "struct" },
        --     }
        --   end,
        --   desc = "Search classes (workspace)",
        -- },
        vim.api.nvim_create_user_command("DiffViewPR", function()
          -- Get the base branch from GitHub PR
          local base_branch = vim.fn.system("gh pr view --json baseRefName -q .baseRefName 2>/dev/null"):gsub("\n", "")

          if vim.v.shell_error ~= 0 or base_branch == "" then
            -- Fallback: try upstream/main, then origin/main, then main
            local base = vim.fn.system("git rev-parse --verify upstream/main 2>/dev/null"):gsub("\n", "")
            if vim.v.shell_error ~= 0 then
              base = vim.fn.system("git rev-parse --verify origin/main 2>/dev/null"):gsub("\n", "")
              if vim.v.shell_error ~= 0 then
                base = "main"
              else
                base = "origin/main"
              end
            else
              base = "upstream/main"
            end
            base_branch = base
          else
            -- Prepend upstream/ or origin/ if needed
            local remote_base =
              vim.fn.system("git rev-parse --verify upstream/" .. base_branch .. " 2>/dev/null"):gsub("\n", "")
            if vim.v.shell_error ~= 0 then
              base_branch = "origin/" .. base_branch
            else
              base_branch = "upstream/" .. base_branch
            end
          end

          local merge_base = vim.fn.system("git merge-base HEAD " .. base_branch):gsub("\n", "")
          vim.cmd("DiffviewOpen " .. merge_base .. "...HEAD")
        end, {}),
      },
    },
  },
}

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

-- Resolve the merge-base of HEAD against the PR's base branch.
-- Tries `gh pr view` first, then falls back to upstream/main → origin/main → main.
-- Returns the merge-base SHA as a trimmed string (or "" if everything fails).
local function resolve_pr_merge_base()
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
    local _ = vim.fn.system("git rev-parse --verify upstream/" .. base_branch .. " 2>/dev/null"):gsub("\n", "")
    if vim.v.shell_error ~= 0 then
      base_branch = "origin/" .. base_branch
    else
      base_branch = "upstream/" .. base_branch
    end
  end

  return vim.fn.system("git merge-base HEAD " .. base_branch):gsub("\n", "")
end

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
        signcolumn = "auto:2", -- allow 2 sign columns (e.g. git + coverage)
        wrap = true, -- Enable line wrapping
        linebreak = true, -- Break at word boundaries
        showbreak = "↪ ", -- Show indicator for wrapped lines
        breakindent = true, -- Preserve indentation for wrapped
        clipboard = "unnamedplus", -- yank goes to system clipboard automatically
        scrolloff = 5, -- keep 5 lines above/below cursor (zt/zb stop 5 lines short of the edge)
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
        -- Clipboard provider designed to "just work" across all our
        -- attach contexts (local Konsole, SSH from WSL, with/without tmux).
        --
        -- Strategy at copy time, in order:
        --   1. Inside tmux: bypass tmux's own OSC 52 forwarding (unreliable
        --      on this server) and write the escape sequence directly to
        --      every attached client's pty.
        --   2. SSH'd (no tmux): write OSC 52 to /dev/tty so the bytes flow
        --      through the SSH pty up to the user's terminal.
        --   3. Truly local: prefer the native X/Wayland clipboard tool;
        --      fall back to OSC 52 on /dev/tty if none available.
        --
        -- Rationale for /dev/tty rather than io.stderr: /dev/tty is always
        -- the controlling terminal regardless of how stderr is wired.
        clipboard = (function()
          local function emit_osc(data)
            local b64 = (vim.base64 and vim.base64.encode and vim.base64.encode(data))
              or vim.fn.system({ "base64", "-w0" }, data):gsub("[\n\r]", "")
            return "\027]52;c;" .. b64 .. "\027\\"
          end
          local function write_tty(path, payload)
            local fd = io.open(path, "w")
            if fd then
              fd:write(payload)
              fd:close()
            end
          end
          -- Treat both unset (nil) and empty string as "not set". vim.env.<X>
          -- returns nil for missing vars; comparing nil to "" with ~= yields
          -- true, which incorrectly suggests the var is populated.
          local function has_env(name)
            local v = vim.env[name]
            return v ~= nil and v ~= ""
          end
          local function copy(_)
            return function(lines, _)
              local data = table.concat(lines, "\n")
              local osc = emit_osc(data)
              -- OSC 52 channel: route to attached tmux clients if in tmux,
              -- otherwise to the controlling terminal.
              if vim.env.TMUX then
                local out = vim.fn.system { "tmux", "list-clients", "-F", "#{client_tty}" }
                for tty in out:gmatch "[^\n]+" do
                  if tty ~= "" then write_tty(tty, osc) end
                end
              else
                write_tty("/dev/tty", osc)
              end
              -- Local X/Wayland clipboard as redundant channel: fills in for
              -- terminals that don't honor OSC 52 (e.g. Konsole with the
              -- toggle off). Harmless when irrelevant.
              if has_env "WAYLAND_DISPLAY" and vim.fn.executable "wl-copy" == 1 then
                vim.fn.system({ "wl-copy" }, data)
              elseif has_env "DISPLAY" and vim.fn.executable "xclip" == 1 then
                vim.fn.system({ "xclip", "-selection", "clipboard" }, data)
              end
            end
          end
          local function paste(_)
            -- Prefer the live system clipboard so that <C-r>+ / "+p reflect
            -- whatever any other app (or CopyQ) put there, not just vim's
            -- own last yank. Falls back to the unnamed register only if no
            -- clipboard tool is available (true SSH-no-X case).
            if has_env "WAYLAND_DISPLAY" and vim.fn.executable "wl-paste" == 1 then
              local out = vim.fn.system { "wl-paste", "--no-newline" }
              if vim.v.shell_error == 0 then return { vim.fn.split(out, "\n", true), "v" } end
            elseif has_env "DISPLAY" and vim.fn.executable "xclip" == 1 then
              local out = vim.fn.system { "xclip", "-selection", "clipboard", "-o" }
              if vim.v.shell_error == 0 then return { vim.fn.split(out, "\n", true), "v" } end
            end
            return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" }
          end
          return {
            name = "tty-osc52",
            copy = { ["+"] = copy "+", ["*"] = copy "*" },
            paste = { ["+"] = paste, ["*"] = paste },
          }
        end)(),
      },
    },
    commands = {
      TabDir = {
        function(opts)
          local dir = opts.args
          if vim.fn.isdirectory(dir) == 0 then
            vim.notify("Not a directory: " .. dir, vim.log.levels.ERROR)
            return
          end
          vim.cmd "tabnew"
          vim.cmd("tcd " .. vim.fn.fnameescape(dir))
          vim.cmd("edit " .. vim.fn.fnameescape(dir))
        end,
        nargs = 1,
        complete = "dir",
        desc = "Open directory in new tab with its own working directory",
      },
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

        -- copy file path / name (overrides snacks "Find projects" on <Leader>fp)
        ["<Leader>fp"] = { "<Cmd>CopyRelativeFilePath<CR>", desc = "Copy relative file path" },
        ["<Leader>fP"] = { "<Cmd>CopyAbsoluteFilePath<CR>", desc = "Copy absolute file path" },
        ["<Leader>fn"] = { "<Cmd>CopyFileName<CR>", desc = "Copy file name" },
        ["<Leader>fh"] = { "<Cmd>CopyRelativeFilePathFromHome<CR>", desc = "Copy file path from home" },

        -- add a directory as a new tab rooted there, so a saved session can span
        -- multiple project roots (see :SessionAddDir in polish.lua)
        ["<Leader>Sa"] = {
          function()
            vim.ui.input(
              { prompt = "Add dir to session: ", default = vim.fn.getcwd() .. "/", completion = "dir" },
              function(dir)
                if dir and dir ~= "" then vim.cmd("SessionAddDir " .. vim.fn.fnameescape(dir)) end
              end
            )
          end,
          desc = "Add directory as new tab (session root)",
        },

        -- diffview against PR base (see :DiffViewPR / :DiffMergeBase user commands below)
        ["<Leader>gd"] = { "<Cmd>DiffViewPR<CR>", desc = "Diff full PR vs base" },
        ["<Leader>gD"] = { "<Cmd>DiffViewPR %<CR>", desc = "Diff current file vs PR base" },
        ["<Leader>gv"] = { "<Cmd>DiffMergeBase<CR>", desc = "Vsplit current file at PR base (gitsigns)" },
        ["<Leader>gx"] = { "<Cmd>DiffviewClose<CR>", desc = "Close diffview" },

        -- peek fold content in scrollable floating window
        ["zp"] = {
          function()
            local line = vim.fn.line "."
            if vim.fn.foldclosed(line) == -1 then return end
            local fold_start = vim.fn.foldclosed(line)
            local fold_end = vim.fn.foldclosedend(line)
            local lines = vim.api.nvim_buf_get_lines(0, fold_start - 1, fold_end, false)
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            local ft = vim.bo.filetype
            vim.bo[buf].filetype = ft
            vim.bo[buf].modifiable = false
            pcall(vim.treesitter.start, buf, vim.treesitter.language.get_lang(ft) or ft)
            local win_width = vim.api.nvim_win_get_width(0)
            local height = math.min(#lines, 20)
            local win = vim.api.nvim_open_win(buf, true, {
              relative = "win",
              win = 0,
              row = vim.fn.winline(),
              col = 0,
              width = win_width - 2,
              height = height,
              style = "minimal",
              border = "rounded",
            })
            for _, key in ipairs { "q", "<Esc>", "zp" } do
              vim.keymap.set("n", key, function()
                pcall(vim.api.nvim_win_close, win, true)
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end, { buffer = buf, nowait = true })
            end
          end,
          desc = "Peek fold",
        },

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
        ["<C-v>"] = { '"+p', desc = "Paste from system clipboard" },
        ["<Leader>|"] = { "<cmd>vsplit #<CR>", desc = "Vsplit with previous buffer" },

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
        ["<leader>fj"] = { function() require("telescope").extensions.projects.projects {} end, desc = "Find projects" },
        ["<leader>f<CR>"] = { "<cmd>Telescope resume<cr>", desc = "Resume previous search" },
        -- Filtered document-symbol pickers. Capitalized to avoid shadowing
        -- AstroNvim's default `<Leader>lf` (vim.lsp.buf.format) and
        -- `<Leader>lc` is intentionally left free. Use `<Leader>ls` for the
        -- unfiltered symbols picker.
        ["<leader>lF"] = {
          function()
            require("telescope.builtin").lsp_document_symbols {
              symbols = { "function", "method" },
            }
          end,
          desc = "Search functions/methods",
        },
        ["<leader>lC"] = {
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
        -- Open the full PR (or one file of it) in a Diffview tab.
        --   :DiffViewPR              → all files
        --   :DiffViewPR <path>       → just that file
        --   :DiffViewPR %            → just the current buffer
        vim.api.nvim_create_user_command("DiffViewPR", function(opts)
          local merge_base = resolve_pr_merge_base()
          local path_arg = opts.args ~= "" and (" -- " .. opts.args) or ""
          vim.cmd("DiffviewOpen " .. merge_base .. "...HEAD" .. path_arg)
        end, { nargs = "?", complete = "file" }),
        -- Open the current buffer's file at the PR merge-base in a vsplit alongside
        -- the working copy, with diff highlights. Run again to toggle closed.
        vim.api.nvim_create_user_command("DiffMergeBase", function()
          local merge_base = resolve_pr_merge_base()
          if merge_base == "" then
            vim.notify("DiffMergeBase: could not resolve PR base branch", vim.log.levels.ERROR)
            return
          end
          require("gitsigns").diffthis(merge_base)
        end, {}),
      },
      v = {
        ["<Leader>fv"] = {
          function()
            local saved = vim.fn.getreg '"'
            vim.cmd 'noau normal! "vy'
            local selected = vim.fn.getreg "v"
            vim.fn.setreg('"', saved)
            require("telescope.builtin").grep_string { search = selected }
          end,
          desc = "Search selected text",
        },
        -- Replace selection with system clipboard contents; send the
        -- replaced text to the black hole so it doesn't clobber "+.
        ["<C-v>"] = { '"_d"+P', desc = "Paste from system clipboard" },
      },
      i = {
        ["<C-v>"] = { "<C-r><C-o>+", desc = "Paste from system clipboard" },
      },
      c = {
        ["<C-v>"] = { "<C-r>+", desc = "Paste from system clipboard" },
      },
    },
  },
}

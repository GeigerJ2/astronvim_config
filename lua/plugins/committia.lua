-- Replaces rhysd/committia.vim with native autocommands to avoid
-- "Failed to retrieve git-dir" errors on COMMIT_EDITMSG.
return {
  {
    "AstroNvim/astrocore",
    opts = {
      autocmds = {
        gitcommit_setup = {
          {
            event = "FileType",
            pattern = "gitcommit",
            callback = function()
              vim.opt_local.colorcolumn = "50,72"

              -- 4-space indentation
              vim.opt_local.tabstop = 4
              vim.opt_local.shiftwidth = 4
              vim.opt_local.softtabstop = 4
              vim.opt_local.expandtab = true

              -- Dynamic textwidth: 50 for subject line, 72 for body
              vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = 0,
                callback = function()
                  local line_num = vim.fn.line "."
                  vim.opt_local.textwidth = line_num == 1 and 50 or 72
                end,
              })

              -- Format commit message keybinding
              vim.keymap.set("n", "<leader>lf", function()
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local formatted = {}

                for i, line in ipairs(lines) do
                  if i == 1 then
                    line = line:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.$", "")
                    if #line > 50 then line = line:sub(1, 47) .. "..." end
                    table.insert(formatted, line)
                  elseif i == 2 then
                    table.insert(formatted, "")
                  else
                    if #line > 72 then
                      local words = {}
                      for word in line:gmatch "%S+" do
                        table.insert(words, word)
                      end

                      local current_line = ""
                      for _, word in ipairs(words) do
                        if #current_line + #word + 1 <= 72 then
                          current_line = current_line == "" and word or current_line .. " " .. word
                        else
                          if current_line ~= "" then table.insert(formatted, current_line) end
                          current_line = word
                        end
                      end
                      if current_line ~= "" then table.insert(formatted, current_line) end
                    else
                      table.insert(formatted, line)
                    end
                  end
                end

                vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
              end, { buffer = true, desc = "Format commit message" })
            end,
          },
        },
        -- Squash-merge drafts (SQUASH_EDITMSG): append the PR number to the
        -- subject line, mirroring what the GitHub squash UI does (`... (#123)`),
        -- so the file can be copy-pasted verbatim. Filename-scoped so it never
        -- touches a real COMMIT_EDITMSG.
        squash_pr_number = {
          {
            event = { "BufReadPost", "BufWritePre" },
            pattern = "*SQUASH_EDITMSG",
            callback = function(args)
              if vim.fn.executable "gh" == 0 then return end
              local subject = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)[1]
              -- Skip if empty or the subject already ends with `(#<num>)`.
              if not subject or subject == "" or subject:match "%(#%d+%)%s*$" then return end
              local dir = vim.fn.fnamemodify(args.file, ":p:h")
              local res = vim
                .system({ "gh", "pr", "view", "--json", "number", "--jq", ".number" }, { cwd = dir, text = true })
                :wait()
              if res.code ~= 0 then return end
              local num = vim.trim(res.stdout or "")
              if not num:match "^%d+$" then return end
              vim.api.nvim_buf_set_lines(args.buf, 0, 1, false, { subject .. " (#" .. num .. ")" })
            end,
          },
        },
      },
    },
  },
}

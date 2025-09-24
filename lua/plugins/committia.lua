return {
  "rhysd/committia.vim",
  ft = "gitcommit",
  config = function()
    vim.g.committia_hooks = {}
    vim.g.committia_hooks.edit_open = function(info)
      -- Set up visual guides
      vim.opt_local.colorcolumn = "50,72"

      -- Dynamic textwidth based on cursor position
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = info.edit_bufnr,
        callback = function()
          local line_num = vim.fn.line "."
          if line_num == 1 then
            vim.opt_local.textwidth = 50
          else
            vim.opt_local.textwidth = 72
          end
        end,
      })

      -- Format entire buffer function (same as in polish.lua)
      local function format_git_commit()
        local lines = vim.api.nvim_buf_get_lines(info.edit_bufnr, 0, -1, false)
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

        vim.api.nvim_buf_set_lines(info.edit_bufnr, 0, -1, false, formatted)
      end

      -- Add format keymap
      vim.keymap.set("n", "<leader>lf", format_git_commit, {
        buffer = info.edit_bufnr,
      })

      -- Start in insert mode if empty
      if info.vcs == "git" and vim.fn.getline(1) == "" then vim.cmd "startinsert" end
    end
  end,
}

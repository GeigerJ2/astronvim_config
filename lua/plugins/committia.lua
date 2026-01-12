return {
  "rhysd/committia.vim",
  ft = "gitcommit",
  config = function()
    -- Delay hook setup to ensure committia is fully loaded
    vim.defer_fn(function()
      vim.g.committia_hooks = {}
      vim.g.committia_hooks.edit_open = function(info)
        -- Basic setup that should always work
        vim.schedule(function()
          vim.opt_local.colorcolumn = "50,72"

          -- Set up dynamic textwidth
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = 0,
            callback = function()
              local line_num = vim.fn.line "."
              vim.opt_local.textwidth = line_num == 1 and 50 or 72
            end,
          })

          -- Simple format command using your polish.lua function
          vim.keymap.set("n", "<leader>lf", function()
            -- Call the format function from polish.lua
            local format_git_commit = function()
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
            end
            format_git_commit()
          end, { buffer = true, desc = "Format commit message" })
        end)
      end
    end, 100) -- 100ms delay
  end,
}

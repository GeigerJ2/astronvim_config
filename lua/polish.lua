-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
--
-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
-- Function to format the entire git commit buffer

local function format_git_commit()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local formatted = {}

  for i, line in ipairs(lines) do
    if i == 1 then
      -- Subject line: trim whitespace, remove trailing period, max 50 chars
      line = line:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.$", "")
      if #line > 50 then line = line:sub(1, 47) .. "..." end
      table.insert(formatted, line)
    elseif i == 2 then
      -- Keep line 2 blank (separator)
      table.insert(formatted, "")
    else
      -- Body lines: word wrap at 72 characters
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

  -- Replace buffer content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    -- Set visual guides
    vim.opt_local.colorcolumn = "50,72"

    -- Different textwidth based on line number
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = 0,
      callback = function()
        local line_num = vim.fn.line "."
        if line_num == 1 then
          vim.opt_local.textwidth = 50 -- Subject line
        else
          vim.opt_local.textwidth = 72 -- Body lines
        end
      end,
    })

    -- Format entire buffer command
    vim.keymap.set("n", "<leader>lf", format_git_commit, {
      buffer = true,
      desc = "Format entire commit message",
    })
  end,
})

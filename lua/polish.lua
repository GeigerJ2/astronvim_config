-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
--
-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- GitHub-style diff colors (applied after colorscheme loads)
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#0d2818" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3d0f0f" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1a3a4d" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#1a4a1a", bold = true })
    vim.api.nvim_set_hl(0, "DiffviewDiffAdd", { bg = "#0d2818" })
    vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { bg = "#3d0f0f", fg = "#6e3535" })
    vim.api.nvim_set_hl(0, "DiffviewDiffChange", { bg = "#1a3a4d" })
    vim.api.nvim_set_hl(0, "DiffviewDiffText", { bg = "#1a4a1a" })
    vim.api.nvim_set_hl(0, "Folded", { bg = "#1c1c1c", fg = "#555555", italic = true })
  end,
})
-- Also apply immediately for current session
vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#0d2818" })
vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3d0f0f" })
vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1a3a4d" })
vim.api.nvim_set_hl(0, "DiffText", { bg = "#1a4a1a", bold = true })
vim.api.nvim_set_hl(0, "DiffviewDiffAdd", { bg = "#0d2818" })
vim.api.nvim_set_hl(0, "DiffviewDiffDelete", { bg = "#3d0f0f", fg = "#6e3535" })
vim.api.nvim_set_hl(0, "DiffviewDiffChange", { bg = "#1a3a4d" })
vim.api.nvim_set_hl(0, "DiffviewDiffText", { bg = "#1a4a1a" })
vim.api.nvim_set_hl(0, "Folded", { bg = "#1c1c1c", fg = "#555555", italic = true })

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

    -- Set tab width to 4 spaces
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true

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

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

-- Persist fold state across sessions (uses :mkview / :loadview).
-- Saves automatically on multiple events; restores on multiple events.
-- Drop "curdir" so views are not tied to the cwd they were created in
-- (e.g. opening the same file from a different worktree still loads folds).
vim.opt.viewoptions:remove "curdir"

local fold_persistence = vim.api.nvim_create_augroup("persistent_folds", { clear = true })

local function should_persist()
  return vim.bo.buftype == "" and vim.bo.modifiable and vim.fn.expand "%:p" ~= "" and vim.fn.filereadable(vim.fn.expand "%:p") == 1
end

-- Save on any event that signals "buffer is leaving the screen or being written".
-- mkview! forces overwrite (the bang matters — without it, an existing view file
-- can prevent the new one from being written depending on nvim version).
vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave", "BufWinLeave", "BufHidden" }, {
  group = fold_persistence,
  callback = function()
    if should_persist() then pcall(vim.cmd, "silent! mkview!") end
  end,
})

-- Load on any event that signals "buffer is now visible / readable".
-- BufWinEnter alone misses the very first :e of a file in some cases.
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
  group = fold_persistence,
  callback = function()
    if should_persist() then pcall(vim.cmd, "silent! loadview") end
  end,
})

-- Manual commands for debugging: :SaveFolds / :LoadFolds.
-- If these work but the autocmds don't, the issue is event timing, not mkview.
vim.api.nvim_create_user_command("SaveFolds", function() vim.cmd "silent! mkview!" end, {})
vim.api.nvim_create_user_command("LoadFolds", function() vim.cmd "silent! loadview" end, {})

-- Fold all sections that do NOT contain the cursor, in a given line range.
-- Walks each line, attempts `zc` (close innermost fold at line). If the closed
-- fold turns out to span the cursor, undoes with `zo` and moves on.
-- Skips past already-closed folds for efficiency. Works with any foldmethod
-- (manual / marker / expr / treesitter) since it only operates on existing
-- folds, never creates them.
local function fold_range_excluding_cursor(start_line, end_line)
  if start_line > end_line then return end
  local cursor = vim.fn.line "."
  local saved_view = vim.fn.winsaveview()
  local saved_lz = vim.opt.lazyredraw:get()
  vim.opt.lazyredraw = true

  local line = start_line
  while line <= end_line do
    local fold_end = vim.fn.foldclosedend(line)
    if fold_end ~= -1 then
      line = fold_end + 1
    elseif vim.fn.foldlevel(line) == 0 then
      line = line + 1
    else
      vim.fn.cursor(line, 1)
      vim.cmd "silent! normal! zc"
      local cs = vim.fn.foldclosed(line)
      local ce = vim.fn.foldclosedend(line)

      if cs == -1 then
        line = line + 1
      elseif cs <= cursor and cursor <= ce then
        -- The just-closed fold spans the cursor; reopen and skip this line.
        vim.cmd "silent! normal! zo"
        line = line + 1
      else
        line = ce + 1
      end
    end
  end

  vim.opt.lazyredraw = saved_lz
  vim.fn.winrestview(saved_view)
end

local function fold_above_cursor()
  local cursor = vim.fn.line "."
  if cursor <= 1 then return end
  fold_range_excluding_cursor(1, cursor - 1)
end

local function fold_below_cursor()
  local cursor = vim.fn.line "."
  fold_range_excluding_cursor(cursor + 1, vim.fn.line "$")
end

vim.keymap.set("n", "<leader>zk", fold_above_cursor, { desc = "Fold all above cursor (level-aware)" })
vim.keymap.set("n", "<leader>zj", fold_below_cursor, { desc = "Fold all below cursor (level-aware)" })
vim.keymap.set("n", "<leader>zz", "zMzv", { desc = "Fold all but cursor's path (zMzv)" })

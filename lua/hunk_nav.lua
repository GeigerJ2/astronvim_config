local M = {}

local function center(line)
  vim.cmd "normal! m'"
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.cmd "silent! normal! zvzz"
end

local function gitsigns(direction)
  local top, bottom = vim.fn.line "w0", vim.fn.line "w$"
  local hunks = require("gitsigns").get_hunks() or {}
  local target
  for _, hunk in ipairs(hunks) do
    local first = math.max(1, hunk.added.start)
    local last = math.max(first, hunk.added.start + hunk.added.count - 1)
    if direction == "next" and first > bottom then
      target = first
      break
    elseif direction == "prev" and last < top then
      target = last
    end
  end
  if target then center(target) end
end

local function diff(direction, select_entry)
  local view = vim.fn.winsaveview()
  local edge = vim.fn.line(direction == "next" and "w$" or "w0")
  if direction == "prev" then
    -- `[c` inside a long change returns its start; skip that visible change.
    while edge > 1 and vim.fn.diff_hlID(edge, 1) ~= 0 and vim.fn.diff_hlID(edge - 1, 1) ~= 0 do
      edge = edge - 1
    end
  end
  -- Probe without moving the other diff pane when no target exists.
  local scrollbind, cursorbind = vim.wo.scrollbind, vim.wo.cursorbind
  vim.wo.scrollbind, vim.wo.cursorbind = false, false
  vim.api.nvim_win_set_cursor(0, { edge, 0 })
  pcall(vim.cmd, "keepjumps normal! " .. (direction == "next" and "]c" or "[c"))
  local target = vim.fn.line "."
  vim.fn.winrestview(view)
  vim.wo.scrollbind, vim.wo.cursorbind = scrollbind, cursorbind
  if (direction == "next" and target > edge) or (direction == "prev" and target < edge) then
    center(target)
  elseif select_entry then
    select_entry()
  elseif vim.b.octo_diff_props ~= nil then
    local queue_key = direction == "next" and "]q" or "[q"
    if next(vim.fn.maparg(queue_key, "n", false, true)) ~= nil then pcall(vim.cmd, "normal " .. queue_key) end
  end
end

--- Jump past visible hunks without wrapping, using the active window's diff.
---@param direction "next"|"prev"
---@param select_entry? fun() File-boundary action for Diffview.
function M.jump(direction, select_entry)
  if vim.wo.diff then
    diff(direction, select_entry)
  else
    gitsigns(direction)
  end
end

return M

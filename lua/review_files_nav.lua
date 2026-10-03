-- ]q / [q in a normal buffer: open the next / previous changed file (see
-- pr_files.lua). With a quickfix window open the keys keep their default meaning,
-- the next / previous quickfix item.
local pr_files = require "pr_files"

local M = {}

local function quickfix_open()
  return vim.fn.getqflist({ winid = 0 }).winid ~= 0
end

--- @param direction "next"|"prev"
function M.step(direction)
  if quickfix_open() then
    local ok, err = pcall(vim.cmd, (vim.v.count1 .. (direction == "next" and "cnext" or "cprev")))
    if not ok then vim.notify((tostring(err):gsub("^.-:", "")), vim.log.levels.WARN) end
    return
  end

  local files, reason = pr_files.list()
  if files == nil or #files == 0 then
    vim.notify("No changed files: " .. (reason or "none"), vim.log.levels.WARN)
    return
  end
  local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p")
  local target = current ~= "" and pr_files.step(files, current, direction, true) or files[1]
  if target == nil then
    vim.notify("No changed files on disk", vim.log.levels.WARN)
    return
  end
  if target == current then
    vim.notify("Only changed file", vim.log.levels.INFO)
    return
  end
  local ok, err = pcall(vim.cmd.edit, vim.fn.fnameescape(target))
  if not ok then vim.notify(tostring(err), vim.log.levels.ERROR) end
end

return M

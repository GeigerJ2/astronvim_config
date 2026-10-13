-- A one-pager `delta` view in a new tab: the output of any command that prints a
-- diff (`git show <sha>`, `cat file.patch`), piped through delta, in a terminal
-- buffer. Used by :PatchView (polish.lua) and the whole-commit key of the
-- :ReviewCommits panel (plugins/diffview.lua).
--
-- Keys in the view: `q` closes the tab; `]q` / `[q` jump to the next / previous
-- file header (the same keys octo, diffview and the PR tree use for files).
local M = {}

-- The lines delta starts a file (or commit) section with: its file labels
-- (Δ modified, added:, removed:, renamed:) and the commit header.
local FILE_HEADER = [[^\(commit\|added:\|removed:\|renamed:\|Δ\)]]

local function jump(flags)
  return function()
    for _ = 1, vim.v.count1 do
      vim.fn.search(FILE_HEADER, flags)
    end
  end
end

--- @param producer string[] argv of a command that prints a diff to stdout
function M.open(producer)
  vim.cmd "tabnew"
  local buf = vim.api.nvim_get_current_buf()
  -- "$@" runs the argv as given, so paths and refs need no shell quoting.
  vim.fn.termopen(vim.list_extend({ "sh", "-c", '"$@" | delta --paging=never', "sh" }, producer))
  vim.bo[buf].buflisted = false
  vim.cmd "stopinsert"
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
  end
  map("q", "<Cmd>tabclose<CR>", "Close diff view")
  map("]q", jump "W", "Next file")
  map("[q", jump "bW", "Previous file")
  return buf
end

return M

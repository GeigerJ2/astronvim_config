-- Gutter for the :ReviewCommits (<Leader>gc) diffview panes.
--
-- gitsigns does not attach to diffview's blob buffers, so those panes only show
-- diff mode for the single commit being viewed. This overlay draws sign-column
-- marks (in gitsigns' colours) in the right-hand commit pane for the hunks of
-- `git diff -U0 <base> <commit> -- <file>`. The base depends on the mode:
--   "commit" (default): the commit's parent, so the gutter shows only what this
--                       commit changed.
--   "pr":               the PR merge-base, so it shows every line the PR changed
--                       up to this commit.
-- <Leader>gB (astrocore.lua) switches between them while a diffview tab is focused.
-- The merge-base comes from vim.g.review_pr_base, which :ReviewCommits sets.
local M = {}

local ns = vim.api.nvim_create_namespace "review_pr_gutter"
M.mode = "commit" -- "commit" | "pr"

local SIGN = { add = "▎", change = "▎", delete = "▁", topdelete = "▔" }
local HL = {
  add = "GitSignsAdd",
  change = "GitSignsChange",
  delete = "GitSignsDelete",
  topdelete = "GitSignsTopdelete",
}

--- Parse `git diff -U0` output into { start = <line>, count = <n>, kind = <kind> }.
function M.parse_hunks(diff)
  local hunks = {}
  for line in diff:gmatch "[^\n]+" do
    local old_count, new_start, new_count = line:match "^@@ %-%d+,?(%d*) %+(%d+),?(%d*) @@"
    if new_start then
      old_count = old_count == "" and 1 or tonumber(old_count)
      new_count = new_count == "" and 1 or tonumber(new_count)
      local start = tonumber(new_start)
      if new_count == 0 then
        table.insert(hunks, { start = math.max(start, 1), count = 1, kind = start == 0 and "topdelete" or "delete" })
      else
        table.insert(hunks, { start = start, count = new_count, kind = old_count == 0 and "add" or "change" })
      end
    end
  end
  return hunks
end

local function current_view()
  local ok, lib = pcall(require, "diffview.lib")
  return ok and lib.get_current_view() or nil
end

local function mark(buf, hunks)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local last = vim.api.nvim_buf_line_count(buf)
  for _, hunk in ipairs(hunks) do
    for line = hunk.start, math.min(hunk.start + hunk.count - 1, last) do
      vim.api.nvim_buf_set_extmark(buf, ns, math.max(line, 1) - 1, 0, {
        sign_text = SIGN[hunk.kind],
        sign_hl_group = HL[hunk.kind],
        priority = 10,
      })
    end
  end
end

--- Redraw the overlay on the commit pane(s) of the current diffview tab.
function M.refresh()
  local view = current_view()
  local base = vim.g.review_pr_base
  if view == nil or base == nil or base == "" then return end
  local file = view:infer_cur_file()
  local sha = file and file.revs and file.revs.b and file.revs.b.commit
  local parent = file and file.revs and file.revs.a and file.revs.a.commit
  if sha == nil then return end
  local diff_base = M.mode == "pr" and base or parent
  if diff_base == nil then return end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    -- Buffer names carry an abbreviated sha: .../<sha11>/<path>.
    if vim.startswith(name, "diffview://") and name:find("/" .. sha:sub(1, 7), 1, true) then
      local cmd = { "git", "-C", view.adapter.ctx.toplevel, "diff", "-U0", "--no-color", diff_base, sha, "--", file.path }
      vim.system(cmd, { text = true }, function(res)
        vim.schedule(function()
          if res.code == 0 and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == name then
            mark(buf, M.parse_hunks(res.stdout or ""))
          end
        end)
      end)
    end
  end
end

--- True in a diffview tab started by :ReviewCommits (the overlay applies there).
function M.active()
  local base = vim.g.review_pr_base
  return base ~= nil and base ~= "" and current_view() ~= nil
end

function M.toggle()
  M.mode = M.mode == "commit" and "pr" or "commit"
  M.refresh()
  vim.notify(
    M.mode == "pr" and "review gutter: whole PR (merge-base to this commit)" or "review gutter: this commit only",
    vim.log.levels.INFO
  )
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("review_pr_gutter", { clear = true }),
    pattern = "DiffviewDiffBufWinEnter",
    callback = function() vim.schedule(M.refresh) end,
  })
end

return M

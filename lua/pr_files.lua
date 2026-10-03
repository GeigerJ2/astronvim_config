-- The files a PR (or branch) changes, shared by every "next changed file" key:
-- neo-tree's PR tree (]g, ]q), and ]q / [q in a normal buffer (polish.lua).
--
-- A file counts as changed when it is
--   1. committed on this branch since it diverged from the base branch,
--   2. modified in the working tree or index, or
--   3. untracked.
-- Using the diff against the merge-base keeps files that are already committed in
-- the list, which `git status` alone would drop.
local M = {}

--- The auto-detected base branch (origin/main, origin/master, main, master), or nil.
function M.detect_base()
  for _, ref in ipairs { "origin/main", "origin/master", "main", "master" } do
    vim.fn.system { "git", "rev-parse", "--verify", "--quiet", ref }
    if vim.v.shell_error == 0 then return ref end
  end
  return nil
end

--- Order paths the way neo-tree renders the tree top to bottom: at each level
--- subdirectories come before sibling files, then case-insensitive name. Walking
--- the list therefore follows the visible tree, not raw ASCII order (which puts
--- uppercase root files like README.md above lowercase directories).
--- `tree_order(a, b)` is true when `a` sorts before `b`.
function M.tree_order(a, b)
  local pa = vim.split(a, "/", { plain = true })
  local pb = vim.split(b, "/", { plain = true })
  for i = 1, math.min(#pa, #pb) do
    if pa[i] ~= pb[i] then
      local a_is_dir, b_is_dir = i < #pa, i < #pb -- more components after => a dir here
      if a_is_dir ~= b_is_dir then return a_is_dir end -- dirs before files
      return pa[i]:lower() < pb[i]:lower()
    end
  end
  return #pa < #pb
end

--- (root, merge_base) for the current repository's branch, or nil on any failure.
function M.context()
  local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 or root == nil or root == "" then return nil end
  local base = M.detect_base()
  if base == nil then return nil end
  local mb = vim.fn.systemlist({ "git", "merge-base", "HEAD", base })[1]
  if vim.v.shell_error ~= 0 or mb == nil or mb == "" then return nil end
  return root, mb
end

--- Absolute paths of all changed files in tree order, deduplicated. Returns nil
--- and a reason on failure (not a repository, no base branch, no merge-base).
function M.list()
  local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 or not root or root == "" then return nil, "not a git repository" end
  local base = M.detect_base()
  if not base then return nil, "no base branch (origin/main, main, ...) found" end
  local merge_base = vim.fn.systemlist({ "git", "merge-base", "HEAD", base })[1]
  if vim.v.shell_error ~= 0 or not merge_base or merge_base == "" then return nil, "no merge-base with " .. base end

  local committed = vim.fn.systemlist { "git", "diff", "--name-only", merge_base .. "..HEAD" }
  local porcelain = vim.fn.systemlist { "git", "status", "--porcelain" }

  local seen, files = {}, {}
  local function add(rel)
    if rel and rel ~= "" and not seen[rel] then
      seen[rel] = true
      table.insert(files, root .. "/" .. rel)
    end
  end
  for _, rel in ipairs(committed) do add(rel) end
  for _, line in ipairs(porcelain) do
    -- Porcelain lines are "XY <path>" or "XY <old> -> <new>" for renames.
    local renamed = line:match "^.. .+ %-> (.+)$"
    add(renamed or line:match "^.. (.+)$")
  end
  table.sort(files, M.tree_order)
  return files
end

--- The changed file that comes after (or before) `current` in tree order, wrapping
--- at the ends. When `current` is not itself a changed file, the nearest changed
--- file in the travel direction. `exists_only` skips deleted files.
function M.step(files, current, direction, exists_only)
  local candidates = files
  if exists_only then
    candidates = vim.tbl_filter(function(f) return vim.uv.fs_stat(f) ~= nil end, files)
  end
  if #candidates == 0 then return nil end
  for i, f in ipairs(candidates) do
    if f == current then
      if direction == "next" then return candidates[i + 1] or candidates[1] end
      return candidates[i - 1] or candidates[#candidates]
    end
  end
  if direction == "next" then
    for _, f in ipairs(candidates) do
      if M.tree_order(current, f) then return f end
    end
    return candidates[1]
  end
  for i = #candidates, 1, -1 do
    if M.tree_order(candidates[i], current) then return candidates[i] end
  end
  return candidates[#candidates]
end

return M

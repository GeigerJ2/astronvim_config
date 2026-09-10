-- Show which git worktree the current buffer belongs to, in the statusline.
-- A repo like aiida-core is developed across a main checkout plus many linked
-- worktrees under <repo>.worktrees/; the branch (already in the statusline)
-- doesn't say which physical worktree you're in, and with related branches
-- checked out side by side that's exactly what gets confused.
--
-- Label: "<repo>" in the main checkout, "<repo>/<subpath>" in a linked worktree
-- (the subpath under <repo>.worktrees/, so nested worktrees stay distinct).
-- Resolved off the buffer's directory and cached per buffer: the statusline
-- redraws constantly, so git runs once when a buffer is first entered (and on
-- :cd), never on redraw.
---@type LazySpec
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local function git(dir, args)
      local cmd = { "git", "-C", dir }
      vim.list_extend(cmd, args)
      local out = vim.fn.system(cmd)
      if vim.v.shell_error ~= 0 then
        return nil
      end
      return vim.trim(out)
    end

    -- dir-keyed cache: worktree topology doesn't change within a session.
    local cache = {}
    local function worktree_label(dir)
      if dir == nil or dir == "" then
        return ""
      end
      local cached = cache[dir]
      if cached ~= nil then
        return cached
      end

      local top = git(dir, { "rev-parse", "--show-toplevel" })
      if top == nil then
        cache[dir] = "" -- not a work tree; remember so we don't re-shell
        return ""
      end
      -- Linked worktrees share the main checkout's common git dir; its parent
      -- is the main worktree.
      local common = git(dir, { "rev-parse", "--path-format=absolute", "--git-common-dir" })
      local main = common ~= nil and vim.fs.dirname(common) or top
      local repo = vim.fs.basename(main)

      local label
      if top == main then
        label = repo
      else
        local wt_root = main .. ".worktrees/"
        local under_wt_root = top:sub(1, #wt_root) == wt_root
        label = repo .. "/" .. (under_wt_root and top:sub(#wt_root + 1) or vim.fs.basename(top))
      end

      cache[dir] = label
      return label
    end

    local function buf_dir(buf)
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and vim.fn.filereadable(name) == 1 then
        return vim.fs.dirname(name)
      end
      return vim.fn.getcwd()
    end

    local function refresh(buf)
      vim.b[buf].git_worktree_label = worktree_label(buf_dir(buf))
    end

    local group = vim.api.nvim_create_augroup("git_worktree_statusline", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
      group = group,
      desc = "Resolve the buffer's git worktree for the statusline",
      callback = function(args)
        -- A buffer's worktree is fixed; only recompute on an explicit :cd.
        if args.event == "BufEnter" and vim.b[args.buf].git_worktree_label ~= nil then
          return
        end
        refresh(args.buf)
      end,
    })
    refresh(0) -- current buffer, since its BufEnter already fired before setup

    local worktree = {
      condition = function()
        if (vim.b.git_worktree_label or "") == "" then
          return false
        end
        -- On a file buffer the branch component already implies the worktree, so
        -- the label is only worth showing where no branch appears: the neo-tree
        -- window and no-name / Untitled buffers.
        return vim.bo.filetype == "neo-tree" or vim.api.nvim_buf_get_name(0) == ""
      end,
      provider = function()
        return " 󰙅 " .. vim.b.git_worktree_label .. " "
      end,
      hl = { fg = "fg" },
    }

    if type(opts.statusline) == "table" then
      table.insert(opts.statusline, math.min(3, #opts.statusline + 1), worktree)
    end
  end,
}

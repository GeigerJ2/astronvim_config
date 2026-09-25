-- Default the diff base to the PR merge-base, per buffer, so the gutter shows the
-- whole-PR diff and gitsigns hunk-nav (]g/[g) works in PR-review buffers (octo's
-- local files, diffview blobs) where the changes are already committed and would
-- otherwise show no hunks vs HEAD.
--
-- Trade-off: blame (<Leader>gl) on a PR-touched line reports "Not Committed Yet",
-- because gitsigns short-circuits blame for a line inside a changed-vs-base hunk
-- (cache.lua get_blame -> get_blame_nc). Toggle the current buffer to HEAD with
-- <Leader>gB (astrocore.lua) when you need accurate blame; a fresh buffer defaults
-- back to the merge-base. (Chosen because ]g hunk-nav is used more than blame.)
return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    local orig_on_attach = opts.on_attach
    opts.attach_to_untracked = true
    opts.on_attach = function(bufnr)
      if orig_on_attach then orig_on_attach(bufnr) end
      local file = vim.api.nvim_buf_get_name(bufnr)
      if file == "" then return end
      local dir = vim.fn.fnamemodify(file, ":h")

      local head = vim.system({ "git", "-C", dir, "rev-parse", "--verify", "main" }, { text = true }):wait()
      local branch = head.code == 0 and "main" or "master"
      local mb = vim.system({ "git", "-C", dir, "merge-base", branch, "HEAD" }, { text = true }):wait()
      local base = (mb.code == 0 and mb.stdout ~= "") and vim.trim(mb.stdout) or branch

      -- change_base needs the buffer's gitsigns cache to exist; retry until it does.
      local function apply_base()
        local cache = require("gitsigns.cache").cache
        if cache[bufnr] and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
          vim.cmd("Gitsigns change_base " .. base)
          vim.b[bufnr].gitsigns_pr_base = true -- <Leader>gB reads this to toggle
        else
          vim.defer_fn(apply_base, 100)
        end
      end
      vim.defer_fn(apply_base, 100)
    end
    return opts
  end,
}

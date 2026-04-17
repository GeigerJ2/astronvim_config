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

      local function apply_base()
        local cache = require("gitsigns.cache").cache
        if cache[bufnr] and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
          vim.cmd("Gitsigns change_base " .. base)
        else
          vim.defer_fn(apply_base, 100)
        end
      end
      vim.defer_fn(apply_base, 100)
    end
    return opts
  end,
}

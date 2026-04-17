return {
  "lewis6991/gitsigns.nvim",
  opts = {
    attach_to_untracked = true,
    on_attach = function(bufnr)
      local file = vim.api.nvim_buf_get_name(bufnr)
      if file == "" then return end
      local dir = vim.fn.fnamemodify(file, ":h")

      local obj = vim.system({ "git", "-C", dir, "rev-parse", "--verify", "main" }, { text = true }):wait()
      local base = obj.code == 0 and "main" or "master"
      require("gitsigns").change_base(base, false)
    end,
  },
}

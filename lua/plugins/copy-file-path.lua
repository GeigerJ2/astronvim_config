return {
  "h3pei/copy-file-path.nvim",
  config = function()
    -- The plugin automatically sets up commands when loaded
    -- Optional: Add keybindings for common operations
    vim.keymap.set("n", "<leader>fp", "<cmd>CopyRelativeFilePath<cr>", {
      desc = "Copy relative file path",
    })
    vim.keymap.set("n", "<leader>fP", "<cmd>CopyAbsoluteFilePath<cr>", {
      desc = "Copy absolute file path",
    })
    vim.keymap.set("n", "<leader>fn", "<cmd>CopyFileName<cr>", {
      desc = "Copy file name",
    })
    vim.keymap.set("n", "<leader>fh", "<cmd>CopyRelativeFilePathFromHome<cr>", {
      desc = "Copy file path from home",
    })
  end,
}

return {
  "h3pei/copy-file-path.nvim",
  -- The plugin auto-registers :CopyRelativeFilePath / :CopyAbsoluteFilePath /
  -- :CopyFileName / :CopyRelativeFilePathFromHome on load.
  -- Keybindings live in plugins/astrocore.lua so they override AstroNvim defaults
  -- (snacks.nvim claims <Leader>fp for "Find projects" otherwise).
  cmd = {
    "CopyRelativeFilePath",
    "CopyAbsoluteFilePath",
    "CopyFileName",
    "CopyRelativeFilePathFromHome",
  },
}

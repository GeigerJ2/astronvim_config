---@type LazySpec
return {
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        extensions = {
          file_browser = {
            respect_gitignore = true,
            -- fd flags to exclude __pycache__ and .pyc even outside git repos
            find_command = { "fd", "--type", "f", "--exclude", "__pycache__", "--exclude", "*.pyc" },
          },
        },
      })
      require("telescope").load_extension("file_browser")
    end,
    keys = {
      {
        "<Leader>fe",
        "<cmd>Telescope file_browser path=%:p:h select_buffer=true depth=false<cr>",
        desc = "File browser (current dir, recursive)",
      },
      {
        "<Leader>fE",
        "<cmd>Telescope file_browser<cr>",
        desc = "File browser (cwd)",
      },
    },
  },
}

return {
  {
    "SmiteshP/nvim-navic",
    opts = { lsp = { auto_attach = true } },
  },
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = { "SmiteshP/nvim-navic", "nvim-tree/nvim-web-devicons" },
    opts = {
      create_autocmd = false, -- We manage updates ourselves to skip octo review_diff windows
      show_modified = true,
    },
    config = function(_, opts)
      require("barbecue").setup(opts)

      -- Replicate barbecue's default autocmd, but skip octo review_diff buffers
      -- so their winbar (set in octo.lua) is not overwritten
      vim.api.nvim_create_autocmd({
        "WinResized",
        "BufWinEnter",
        "CursorMoved",
        "InsertLeave",
        "BufModifiedSet",
      }, {
        group = vim.api.nvim_create_augroup("barbecue.updater", {}),
        callback = function()
          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname:match "^octo://" then return end
          require("barbecue.ui").update()
        end,
      })
    end,
  },
}

---@type LazySpec
return {
  {
    "nvim-telescope/telescope-smart-history.nvim",
    dependencies = { "kkharji/sqlite.lua" },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-smart-history.nvim",
    },
    opts = function(_, opts)
      opts.defaults = opts.defaults or {}
      opts.defaults.cache_picker = {
        num_pickers = 20,
        limit_entries = 1000,
      }
      opts.defaults.history = {
        path = vim.fn.stdpath("data") .. "/databases/telescope_history.sqlite3",
        limit = 100,
      }
      opts.defaults.layout_strategy = "flex"
      opts.defaults.layout_config = vim.tbl_deep_extend("force", opts.defaults.layout_config or {}, {
        width = 0.95,
        height = 0.95,
      })
      return opts
    end,
    -- Load the extension after telescope is set up
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "AstroNvimSetup",
        callback = function()
          require("telescope").load_extension("smart_history")
        end,
      })
    end,
  },
}

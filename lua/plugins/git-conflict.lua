---@type LazySpec
return {
  "akinsho/git-conflict.nvim",
  version = "*",
  lazy = false,  -- load immediately
  event = "BufReadPre", -- Load when opening files
  config = function()
    require("git-conflict").setup {
      default_mappings = true, -- Enable default keybindings
      default_commands = true, -- Enable commands
      disable_diagnostics = false, -- Keep diagnostics enabled
      list_opener = "copen", -- Use quickfix for conflict list
      highlights = {
        incoming = "DiffAdd", -- Green for incoming changes
        current = "DiffText", -- Blue for current changes
      },
    }

    -- Optional: Add a keymap to list all conflicts
    vim.keymap.set("n", "<leader>gx", "<cmd>GitConflictListQf<cr>", { desc = "List git conflicts in quickfix" })
  end,
}

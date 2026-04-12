return {
  "m00qek/baleia.nvim",
  cmd = { "BaleiaColorize", "BaleiaLogs" },
  keys = {
    {
      "<leader>uA",
      function()
        local baleia = require("baleia").setup()
        baleia.once(vim.api.nvim_get_current_buf())
      end,
      desc = "Colorize ANSI escape codes",
    },
  },
  config = function()
    local baleia = require("baleia").setup()
    vim.api.nvim_create_user_command("BaleiaColorize", function()
      baleia.once(vim.api.nvim_get_current_buf())
    end, { bang = true })
    vim.api.nvim_create_user_command("BaleiaLogs", baleia.logger.show, { bang = true })
  end,
}

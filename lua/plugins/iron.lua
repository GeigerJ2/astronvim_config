-- Interactive REPL: send code to a running Python/etc. session
---@type LazySpec
return {
  "Vigemus/iron.nvim",
  keys = {
    { "<leader>rs", desc = "REPL: Start" },
    { "<leader>rr", desc = "REPL: Restart" },
    { "<leader>rf", desc = "REPL: Send file" },
    { "<leader>rl", desc = "REPL: Send line" },
    { "<leader>rc", desc = "REPL: Send motion" },
    { "<leader>rq", desc = "REPL: Close" },
    { "<leader>rl", mode = "v", desc = "REPL: Send selection" },
  },
  config = function()
    local iron = require "iron.core"
    local view = require "iron.view"

    iron.setup {
      config = {
        scratch_repl = true,
        repl_definition = {
          python = require("iron.fts.python").ipython,
        },
        repl_open_cmd = view.split.vertical.botright "40%",
      },
      keymaps = {
        toggle_repl = "<leader>rs",
        restart_repl = "<leader>rr",
        send_file = "<leader>rf",
        send_line = "<leader>rl",
        visual_send = "<leader>rl",
        send_motion = "<leader>rc",
        exit = "<leader>rq",
      },
      highlight = { italic = true },
      ignore_blank_lines = true,
    }
  end,
}

return {
  "linrongbin16/gitlinker.nvim",
  cmd = "GitLink",
  config = function()
    require("gitlinker").setup()
  end,
  keys = {
    {
      "<leader>gy",
      function()
        -- Check if upstream exists, otherwise use origin
        local handle = io.popen("git remote 2>/dev/null | grep -q '^upstream$' && echo 'upstream' || echo 'origin'")
        local remote = handle:read("*l")
        handle:close()
        
        require("gitlinker").link({
          remote = remote,
        })
      end,
      desc = "Copy git permalink",
      mode = { "n", "v" },
    },
  },
}

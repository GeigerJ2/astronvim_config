-- ~/.config/nvim/lua/plugins/indent-blankline.lua
return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "User AstroFile",
  opts = {
    indent = { 
      char = "│",
    },
    scope = {
      enabled = true,
      show_start = true,
      show_end = true,
    }
  },
}

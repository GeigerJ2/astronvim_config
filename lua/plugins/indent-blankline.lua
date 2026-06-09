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
      -- Scope markers (the `▎` char + start/end underlines) add a lot of
      -- visual noise on deeply-nested files like Sirocco YAML configs.
      -- Keep plain indent guides, drop the scope decoration.
      enabled = false,
    }
  },
}

-- In ~/.config/nvim/lua/plugins/nvim-cmp.lua
return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-emoji',
  },
  opts = function(_, opts)
    -- AstroNvim-friendly way
    opts.sources = opts.sources or {}
    table.insert(opts.sources, { name = 'emoji' })
  end
}

return {
  'topaxi/pipeline.nvim',
  keys = {
    { '<leader>a', '<cmd>Pipeline<cr>', desc = 'Open pipeline.nvim' },
  },
  -- optional, you can also install and use `yq` instead.
  build = 'make',
  ---@type pipeline.Config
  opts = {},
}

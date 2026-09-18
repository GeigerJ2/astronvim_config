return {
  'topaxi/pipeline.nvim',
  keys = {
    -- moved off <leader>a (now the claudecode.nvim "AI" prefix) into the git cluster
    { '<leader>gp', '<cmd>Pipeline<cr>', desc = 'Open pipeline.nvim (CI)' },
  },
  -- optional, you can also install and use `yq` instead.
  build = 'make',
  ---@type pipeline.Config
  opts = {},
}

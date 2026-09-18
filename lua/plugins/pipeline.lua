return {
  'topaxi/pipeline.nvim',
  keys = {
    -- <leader>a is now the claudecode.nvim "AI" prefix, so pipeline lives on a
    -- top-level, mnemonic key of its own (shows as "P" in the leader menu).
    { '<leader>P', '<cmd>Pipeline<cr>', desc = 'Open pipeline.nvim (CI)' },
  },
  -- optional, you can also install and use `yq` instead.
  build = 'make',
  ---@type pipeline.Config
  opts = {},
}

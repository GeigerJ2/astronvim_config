---@type LazySpec
return {
  'xiyaowong/telescope-emoji.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('telescope').load_extension('emoji')
  end
}

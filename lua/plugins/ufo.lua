---@type LazySpec
return {
  "kevinhwang91/nvim-ufo",
  dependencies = "kevinhwang91/promise-async",
  event = "BufReadPost",
  config = function()
    -- Fold settings
    vim.o.foldcolumn = "1"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    -- Key mappings
    vim.keymap.set("n", "z1", function() vim.opt.foldlevel = 1 end, { desc = "Fold to level 1" })
    vim.keymap.set("n", "z2", function() vim.opt.foldlevel = 2 end, { desc = "Fold to level 2" })
    vim.keymap.set("n", "z3", function() vim.opt.foldlevel = 3 end, { desc = "Fold to level 3" })
    vim.keymap.set("n", "z4", function() vim.opt.foldlevel = 4 end, { desc = "Fold to level 4" })
    vim.keymap.set("n", "z5", function() vim.opt.foldlevel = 5 end, { desc = "Fold to level 5" })
    vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
    vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
    vim.keymap.set("n", "zp", require("ufo").peekFoldedLinesUnderCursor, { desc = "Peek fold" })

    -- Simple setup with just treesitter and indent
    require("ufo").setup {
      provider_selector = function(bufnr, filetype, buftype) return { "lsp", "treesitter"} end,
    }
  end,
}

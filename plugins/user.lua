return {
    -- "dccsillag/magma-nvim", "nickeb96/fish.vim", "tmhedberg/SimpylFold",
    -- "Konfekt/FastFold", "junegunn/vim-easy-align", "hkupty/iron.nvim",
    -- -- "codeape2/vim-multiple-monitors",
    "goerz/jupytext.vim", {"ggandor/leap.nvim", lazy = false},
    -- {"GCBallesteros/vim-textobj-hydrogen"}, {
    --     "iamcco/markdown-preview.nvim",
    --     run = "cd app && npm install",
    --     setup = function() vim.g.mkdp_filetypes = {"markdown"} end,
    --     ft = {"markdown"}
    -- }, {
    --     "folke/todo-comments.nvim",
    --     requires = "nvim-lua/plenary.nvim",
    --     config = function()
    --         require("todo-comments").setup {
    --             -- your configuration comes here
    --             -- or leave it empty to use the default settings
    --             -- refer to the configuration section below
    --         }
    --     end
    -- }, {
    --     "ThePrimeagen/refactoring.nvim",
    --     requires = {
    --         {"nvim-lua/plenary.nvim"}, {"nvim-treesitter/nvim-treesitter"}
    --     }
    -- },
    {'glacambre/firenvim', run = function() vim.fn['firenvim#install'](0) end}
    --   globalSettings = {alt = "all"},
    --   localSettings = {
    --   [".*"] = {
    --       cmdline = "neovim -c set lines=10",
    --       content = "text",
    --       priority = 0,
    --       selector = "textarea",
    --       takeover = "never"
    --   }
    -- },
    -- },

    -- You can also add new plugins here as well:
    -- Add plugins, the lazy syntax
    -- "andweeb/presence.nvim",
    -- {
    --   "ray-x/lsp_signature.nvim",
    --   event = "BufRead",
    --   config = function()
    --     require("lsp_signature").setup()
    --   end,
    -- },
}

return {
    -- the colorscheme should be available when starting Neovim

    "ziontee113/icon-picker.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    -- priority = 1000, -- make sure to load this before all the other start plugins
    -- config = function()
    --   -- load the colorscheme here
    --   vim.cmd([[colorscheme tokyonight]])
    -- end,
    config = function()
        require("icon-picker").setup({disable_legacy_commands = true})
    end
}

return {
  "dccsillag/magma-nvim",
  "nickeb96/fish.vim",
  "tmhedberg/SimpylFold",
  "Konfekt/FastFold",
  "junegunn/vim-easy-align",
  "hkupty/iron.nvim",
  "codeape2/vim-multiple-monitors", -- {"goerz/jupytext.vim", as = "jupytext"},
  { "dccsillag/magma-nvim", run = ":UpdateRemotePlugins", lazy = false },
  {
    "ggandor/leap.nvim",
    as = "leap",
    lazy = false,
    config = function() require("leap").add_default_mappings() end,
  },
  {
    "glacambre/firenvim",
    as = "firenvim",
    cond = not not vim.g.started_by_firenvim,
    build = function()
      require("lazy").load { plugins = "firenvim", wait = true }
      vim.fn["firenvim#install"](0)
    end,
    run = function() vim.fn["firenvim#install"](0) end,
    config = function()
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            cmdline = "neovim -c set lines=10",
            content = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never",
          },
        },
      }
    end,
  },
  { "GCBallesteros/vim-textobj-hydrogen" },
  {
    "iamcco/markdown-preview.nvim",
    run = "cd app && npm install",
    setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  },
  {
    "folke/todo-comments.nvim",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("todo-comments").setup {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      }
    end,
  },
  {
    "ThePrimeagen/refactoring.nvim",
    requires = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
  },
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

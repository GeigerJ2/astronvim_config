---@type LazySpec
return {
  "kevinhwang91/nvim-ufo",
  enabled = true, -- Explicitly enable nvim-ufo
  event = { "User AstroFile", "InsertEnter" },
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        -- Disable AstroNvim's built-in folding
        opts.features = opts.features or {}
        opts.features.foldtext = false -- Disable AstroNvim's foldtext

        local maps = opts.mappings
        maps.n["zR"] = { function() require("ufo").openAllFolds() end, desc = "Open all folds" }
        maps.n["zM"] = { function() require("ufo").closeAllFolds() end, desc = "Close all folds" }
        maps.n["zr"] = { function() require("ufo").openFoldsExceptKinds() end, desc = "Fold less" }
        maps.n["zm"] = { function() require("ufo").closeFoldsWith() end, desc = "Fold more" }
        maps.n["zp"] = { function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" }

        -- Add fold level mappings (1-5)
        maps.n["z1"] = { function() require("ufo").closeFoldsWith(1) end, desc = "Close folds to level 1" }
        maps.n["z2"] = { function() require("ufo").closeFoldsWith(2) end, desc = "Close folds to level 2" }
        maps.n["z3"] = { function() require("ufo").closeFoldsWith(3) end, desc = "Close folds to level 3" }
        maps.n["z4"] = { function() require("ufo").closeFoldsWith(4) end, desc = "Close folds to level 4" }
        maps.n["z5"] = { function() require("ufo").closeFoldsWith(5) end, desc = "Close folds to level 5" }

        local opt = opts.options.opt
        opt.foldcolumn = "1"
        opt.foldexpr = "0"
        opt.foldenable = true
        opt.foldlevel = 99
        opt.foldlevelstart = 99

        -- Remove AstroNvim's persistent foldexpr autocmd
        opts.autocmds.persistent_astroui_foldexpr = nil
      end,
    },
    {
      "AstroNvim/astrolsp",
      optional = true,
      opts = function(_, opts)
        local astrocore = require "astrocore"
        if astrocore.is_available "nvim-ufo" then
          opts.capabilities = astrocore.extend_tbl(opts.capabilities, {
            textDocument = { foldingRange = { dynamicRegistration = false, lineFoldingOnly = true } },
          })
        end
      end,
    },
    {
      "AstroNvim/astroui",
      opts = {
        -- Disable AstroNvim's built-in foldtext
        features = {
          foldtext = false,
        },
      },
    },
  },
  dependencies = { { "kevinhwang91/promise-async", lazy = true } },
  opts = {
    -- Prevent auto-folding on save/buffer display
    close_fold_kinds_for_ft = {
      default = {}, -- Don't auto-close any fold kinds
    },
    close_fold_current_line_for_ft = {
      default = false, -- Don't auto-close folds on current line
    },
    preview = {
      mappings = {
        scrollB = "<C-B>",
        scrollF = "<C-F>",
        scrollU = "<C-U>",
        scrollD = "<C-D>",
      },
    },
    provider_selector = function(_, filetype, buftype)
      local function handleFallbackException(bufnr, err, providerName)
        if type(err) == "string" and err:match "UfoFallbackException" then
          return require("ufo").getFolds(bufnr, providerName)
        else
          return require("promise").reject(err)
        end
      end

      return (filetype == "" or buftype == "nofile") and "indent" -- only use indent until a file is opened
        or function(bufnr)
          return require("ufo")
            .getFolds(bufnr, "lsp")
            :catch(function(err) return handleFallbackException(bufnr, err, "treesitter") end)
            :catch(function(err) return handleFallbackException(bufnr, err, "indent") end)
        end
    end,
  },
}

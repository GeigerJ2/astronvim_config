-- Auto-open the Aerial symbols outline when entering a normal file buffer, so the
-- structure of whatever you're reading is always visible (still toggleable with
-- <leader>lS). Skip diff panes (octo review, diffview) and octo:// buffers, where
-- an outline is meaningless and just eats an already-split view.
return {
  "stevearc/aerial.nvim",
  opts = function(_, opts)
    -- Skip the auto-open outline when viewing over SSH (typically the laptop into
    -- a workstation, where the screen is small and the sidebar just crowds it).
    -- SSH_CONNECTION is the signal; inside the persistent tmux server it only
    -- reaches nvim because tmux.conf lists it in `update-environment` (so nvim
    -- must be launched after attaching over SSH). Still toggle with <leader>lS.
    -- Always dock the outline on the right. Aerial's default "prefer_right" picks
    -- the side from the focused window's position (right only if it is the
    -- rightmost split, else left), so the outline jumps sides depending on where
    -- you open it. A fixed "right" keeps it put.
    opts.layout = opts.layout or {}
    opts.layout.default_direction = "right"

    local is_remote = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
    opts.open_automatic = function(bufnr)
      if is_remote then return false end
      -- Set by the <Leader>lS toggle: once you close the outline, keep it closed
      -- on buffer switches until you reopen it (which clears the flag).
      if vim.g.aerial_suppress_autoopen then return false end
      -- Octo review diff buffers (both octo:// virtual buffers and use-local real
      -- files) carry the octo_diff_props buffer var, set at buffer creation. Octo
      -- fires BufEnter -- which triggers aerial's auto-open -- BEFORE it runs
      -- diffthis and before it detects a filetype, so neither wo.diff nor an octo
      -- filetype is set yet at this point; the buffer var is the reliable signal.
      if vim.b[bufnr].octo_diff_props ~= nil then return false end
      -- Any other diff pane (diffview).
      if vim.wo.diff then return false end
      -- octo:// issue / PR / panel buffers (filetype "octo", "octo_panel").
      if vim.startswith(vim.bo[bufnr].filetype, "octo") then return false end
      -- Otherwise defer to aerial's buffer-ignore rules (special / unlisted
      -- buftypes, etc.). maybe_open_automatic also requires a symbol backend, so
      -- files without LSP/treesitter symbols won't pop the outline open.
      return not require("aerial.util").is_ignored_buf(bufnr)
    end
    return opts
  end,
  dependencies = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        -- Override AstroNvim's <Leader>lS (a plain aerial.toggle) so closing the
        -- outline also suppresses the auto-open, and reopening re-enables it.
        opts.mappings.n["<Leader>lS"] = {
          function()
            local aerial = require "aerial"
            if aerial.is_open() then
              vim.g.aerial_suppress_autoopen = true
              aerial.close()
            else
              vim.g.aerial_suppress_autoopen = false
              aerial.open()
            end
          end,
          desc = "Symbols outline (stays closed)",
        }
        -- Floating breadcrumb navigator: j/k between siblings (with live
        -- preview), h to the parent symbol, l into children, <CR> jumps. The
        -- keyboard equivalent of clicking the winbar breadcrumbs.
        opts.mappings.n["<Leader>ln"] = {
          function() require("aerial").nav_toggle() end,
          desc = "Navigate symbols (aerial)",
        }
      end,
    },
  },
}

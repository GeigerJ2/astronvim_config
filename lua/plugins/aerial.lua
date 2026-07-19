-- Auto-open the Aerial symbols outline when entering a normal file buffer, so the
-- structure of whatever you're reading is always visible (still toggleable with
-- <leader>lS). Skip diff panes (octo review, diffview) and octo:// buffers, where
-- an outline is meaningless and just eats an already-split view.
return {
  "stevearc/aerial.nvim",
  opts = function(_, opts)
    opts.open_automatic = function(bufnr)
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
}

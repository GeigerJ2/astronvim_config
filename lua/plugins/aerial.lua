-- Auto-open the Aerial symbols outline when entering a normal file buffer, so the
-- structure of whatever you're reading is always visible (still toggleable with
-- <leader>lS). Skip diff panes (octo review, diffview) and octo:// buffers, where
-- an outline is meaningless and just eats an already-split view.
return {
  "stevearc/aerial.nvim",
  opts = function(_, opts)
    opts.open_automatic = function(bufnr)
      -- Diff windows (octo review / diffview) get no outline. The auto-open path
      -- doesn't honor aerial's own diff_windows ignore, so check wo.diff here.
      if vim.wo.diff then return false end
      -- octo:// PR/issue buffers (filetype "octo").
      if vim.startswith(vim.bo[bufnr].filetype, "octo") then return false end
      -- Otherwise defer to aerial's buffer-ignore rules (special / unlisted
      -- buftypes, etc.). maybe_open_automatic also requires a symbol backend, so
      -- files without LSP/treesitter symbols won't pop the outline open.
      return not require("aerial.util").is_ignored_buf(bufnr)
    end
    return opts
  end,
}

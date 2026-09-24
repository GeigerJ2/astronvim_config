-- Show blink.cmp's scored completion menu for `:` commands, so frequently and
-- recently used commands (DiffviewRefresh, not the dozen other Diff* commands)
-- sort to the top via blink's frecency, instead of native wildmenu's alphabetical
-- Tab-cycling. AstroNvim disables the menu in cmdline mode
-- (auto_show = ctx.mode ~= "cmdline"); re-enable it, but only for command-line
-- (":"), leaving search (`/`, `?`) and `:%s/...` prompts alone.
---@type LazySpec
return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    opts.completion = opts.completion or {}
    opts.completion.menu = opts.completion.menu or {}
    opts.completion.menu.auto_show = function(ctx)
      if ctx.mode == "cmdline" then return vim.fn.getcmdtype() == ":" end
      return true -- keep AstroNvim's behaviour everywhere else (insert, term)
    end
    -- Frecency is blink's default (and needs the Rust matcher, which is built
    -- here); set it explicitly so this file documents the behaviour it relies on.
    -- Accepting a command from the menu boosts it, so the ranking learns your
    -- usage over the first few times. (use_frecency is the deprecated alias.)
    opts.fuzzy = opts.fuzzy or {}
    opts.fuzzy.frecency = vim.tbl_extend("force", opts.fuzzy.frecency or {}, { enabled = true })
    -- Force Rust (AstroNvim's "prefer_rust" would silently fall back to the Lua
    -- matcher, which ignores frecency). The binary is built here; if it ever goes
    -- missing this errors loudly instead of quietly dropping frecency.
    opts.fuzzy.implementation = "rust"
    return opts
  end,
}

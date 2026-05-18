-- Workaround for an upstream snacks.nvim bug.
--
-- `snacks/picker/select.lua` sizes the select list with:
--
--   box.height = math.max(math.min(#items, vim.o.lines * 0.8 - 10), 2)
--
-- `vim.o.lines * 0.8 - 10` is non-integral unless the terminal height is
-- a multiple of 5. When the item list is long (e.g. Mason's package
-- list), `math.min` picks that fractional value, and snacks' `win:dim()`
-- passes sizes >= 1 through verbatim (no flooring). The float then
-- reaches `nvim_win_set_config`, which rejects it:
--
--   E5108: Invalid 'height': Number is not integral
--
-- The buggy `layout.config` is set inline in select.lua and merged last
-- in `Snacks.picker.config.get`, so a plain `opts` override can't beat
-- it. The supported `opts.snacks` passthrough *is* merged over it
-- (`Snacks.config.merge`: last function wins), so we wrap the module's
-- `select` to inject a corrected, floored layout config and delegate.
--
-- This only reimplements the one-line height formula, not select's body,
-- so it should survive most upstream changes. Remove this file once
-- snacks.nvim floors the height upstream.

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local select = require("snacks.picker.select")
      if not select.__height_fix then
        select.__height_fix = true
        local orig = select.select
        select.select = function(items, sel_opts, on_choice)
          sel_opts = sel_opts or {}
          local snacks_opts = sel_opts.snacks or {}
          local layout = snacks_opts.layout or {}
          -- Respect a caller-provided layout config; only fill the gap.
          if layout.config == nil then
            layout.config = function(l)
              if type(l.layout) ~= "table" then return end
              for _, box in ipairs(l.layout) do
                if box.win == "list" and not box.height then
                  box.height = math.floor(math.max(math.min(#items, vim.o.lines * 0.8 - 10), 2))
                end
              end
            end
            snacks_opts.layout = layout
            sel_opts.snacks = snacks_opts
          end
          return orig(items, sel_opts, on_choice)
        end
      end
      return opts
    end,
  },
}

-- PR check status in a snacks picker, mirroring `gh pr checks`.
-- Enter opens the check's URL; no terminal round-trip.
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    opts.mappings.n["<Leader>C"] = {
      function()
        if vim.fn.executable "gh" == 0 then
          vim.notify("gh not found", vim.log.levels.WARN)
          return
        end
        local res = vim
          .system({ "gh", "pr", "checks", "--json", "name,state,link,description" }, { text = true })
          :wait()
        if res.code ~= 0 then
          vim.notify("gh pr checks failed (not a PR branch?)", vim.log.levels.WARN)
          return
        end
        local ok, checks = pcall(vim.json.decode, res.stdout)
        if not ok or #checks == 0 then
          vim.notify("no checks reported", vim.log.levels.INFO)
          return
        end
        local icons =
          { SUCCESS = "✓", FAILURE = "X", ERROR = "X", PENDING = "*", SKIPPED = "-", CANCELLED = "⊘", NEUTRAL = "=" }
        local items = {}
        for _, c in ipairs(checks) do
          items[#items + 1] = {
            text = string.format("%s %s  %s", icons[c.state] or "?", c.name or "?", c.description or ""),
            url = c.link,
          }
        end
        require("snacks").picker.pick({
          items = items,
          format = "text",
          confirm = function(picker, item)
            picker:close()
            if item and item.url and item.url ~= "" then vim.ui.open(item.url) end
          end,
        })
      end,
      desc = "PR checks (picker)",
    }
  end,
}

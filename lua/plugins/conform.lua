return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.gitcommit = { "git_commit_formatter" }

    opts.formatters = opts.formatters or {}
    opts.formatters.git_commit_formatter = {
      command = "lua",
      args = {
        "-e",
        [[
          local file = arg[1]
          local f = io.open(file, "r")
          local content = f:read("*all")
          f:close()
          
          local lines = {}
          for line in content:gmatch("[^\n]*") do
            table.insert(lines, line)
          end
          
          -- Format logic here
          local formatted = {}
          for i, line in ipairs(lines) do
            if i == 1 then
              line = line:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%.$", "")
              if #line > 50 then line = line:sub(1, 47) .. "..." end
            end
            table.insert(formatted, line)
          end
          
          local f = io.open(file, "w")
          f:write(table.concat(formatted, "\n"))
          f:close()
        ]],
      },
      stdin = false,
    }

    return opts
  end,
}

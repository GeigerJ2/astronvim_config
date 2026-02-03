-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"

    -- Helper function to detect Python path (uv, hatch, venv)
    local function get_python_path()
      local python_path = nil
      local venv = vim.env.VIRTUAL_ENV
      if venv then return venv .. "/bin/python" end

      local root = vim.fn.getcwd()
      local local_venv = root .. "/.venv/bin/python"
      if vim.fn.executable(local_venv) == 1 then return local_venv end

      local handle = io.popen("cd " .. root .. " && hatch env find 2>/dev/null")
      if handle then
        local hatch_path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
        handle:close()
        if hatch_path ~= "" then return hatch_path .. "/bin/python" end
      end

      handle = io.popen("cd " .. root .. " && uv run which python 2>/dev/null")
      if handle then
        local uv_path = handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
        handle:close()
        if uv_path ~= "" and vim.fn.executable(uv_path) == 1 then return uv_path end
      end

      return vim.fn.exepath "python3" or vim.fn.exepath "python"
    end

    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      -- Configure mypy with correct Python executable
      null_ls.builtins.diagnostics.mypy.with {
        extra_args = function()
          return { "--python-executable", get_python_path() }
        end,
      },
    })
  end,
}

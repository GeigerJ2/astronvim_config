-- Customize None-ls sources

-- Shared Python path detection (same as astrolsp.lua)
local function get_python_path()
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

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require "null-ls"
    null_ls.setup {
      sources = {
        null_ls.builtins.diagnostics.mypy.with {
          -- Run mypy from the project venv so plugins (pydantic.mypy, etc.) are available
          command = function()
            local python = get_python_path()
            local venv_mypy = python:gsub("/python$", "/mypy")
            if vim.fn.executable(venv_mypy) == 1 then return venv_mypy end
            return "mypy" -- fallback to Mason's mypy
          end,
          extra_args = function()
            return { "--python-executable", get_python_path() }
          end,
        },
      },
    }
  end,
}

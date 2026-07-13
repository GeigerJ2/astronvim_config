-- Neovim's built-in python ftplugin maps ]] / [[ to jump between class/def, but
-- anchors the pattern at column 0 (`^(class|def|async def)`), so they skip
-- indented defs (methods). Re-map them buffer-locally with `^\s*` so they land
-- on methods too — matching what the built-in ]m / [m already do, but on the
-- keys you use. The `desc` also replaces the raw <SNR>…Python_jump(...) label in
-- which-key with something readable.
--
-- Runs from after/ftplugin so it wins over the built-in ftplugin's mappings.

local pattern = [[\v^\s*(class|def|async def)>]]

-- `search()` in every mode moves the cursor: in normal mode it's a jump, in
-- operator-pending it defines the motion (d]] / y]]), in visual it extends the
-- selection. Push the jumplist only in normal mode (m' inside an operator- or
-- visual-mode mapping would break it), so <C-o> returns from a plain jump.
local function jump(flags)
  return function()
    if vim.fn.mode() == "n" then vim.cmd "normal! m'" end
    for _ = 1, vim.v.count1 do
      vim.fn.search(pattern, flags)
    end
  end
end

local modes = { "n", "x", "o" }
vim.keymap.set(modes, "]]", jump "W", { buffer = true, silent = true, desc = "Next class/def" })
vim.keymap.set(modes, "[[", jump "Wb", { buffer = true, silent = true, desc = "Prev class/def" })

-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
--
-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Diff / Diffview / Folded highlight overrides now live in ONE place:
-- lua/plugins/astroui.lua (highlights.init). There the DiffAdd/DiffChange/
-- DiffText/DiffDelete backgrounds are cleared (bg=NONE) so :Octo review shows
-- syntax highlighting instead of astrodark's green/red line backgrounds.

-- NOTE: gitcommit buffer setup (50/72 colorcolumn, line-aware textwidth,
-- <leader>lf formatter) lives in lua/plugins/committia.lua.

-- Persist closed-fold state across sessions.
--
-- Strategy: snapshot every closed fold as `{start_line, end_line, text}`
-- into a JSON sidecar in stdpath('state')/fold-state/.  On load, switch
-- the buffer to foldmethod=manual and recreate the folds from the saved
-- ranges, because :foldclose / zc on a nested-fold line always targets
-- the OUTERMOST containing fold (under expr-method), not the inner
-- section the user actually closed.

local fold_state_dir = vim.fn.stdpath("state") .. "/fold-state"
vim.fn.mkdir(fold_state_dir, "p")

local fold_persistence = vim.api.nvim_create_augroup("persistent_folds", { clear = true })

local function should_persist(bufnr)
  if bufnr == nil or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return vim.bo[bufnr].buftype == ""
    and vim.bo[bufnr].modifiable
    and name ~= ""
    and vim.fn.filereadable(name) == 1
end

local function fold_state_path(bufnr)
  if bufnr == nil or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then return nil end
  local hash = vim.fn.sha256(file):sub(1, 16)
  local basename = vim.fn.fnamemodify(file, ":t")
  return string.format("%s/%s_%s.json", fold_state_dir, basename, hash)
end

-- Walk the buffer and record every closed fold's range and headline.
local function collect_closed_folds(bufnr)
  local closed = {}
  local last = vim.api.nvim_buf_line_count(bufnr)
  local lnum = 1
  while lnum <= last do
    local fold_start = vim.fn.foldclosed(lnum)
    if fold_start == lnum then
      local fold_end = vim.fn.foldclosedend(lnum)
      local text = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
      table.insert(closed, { start_line = lnum, end_line = fold_end, text = text })
      lnum = (fold_end > 0 and fold_end or lnum) + 1
    else
      lnum = lnum + 1
    end
  end
  return closed
end

local function locate_fold_start(bufnr, entry)
  local total = vim.api.nvim_buf_line_count(bufnr)
  local at = function(lnum)
    if lnum < 1 or lnum > total then return nil end
    return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
  end
  local saved_line = entry.start_line or entry.line
  if at(saved_line) == entry.text then return saved_line end
  for offset = 1, 50 do
    if at(saved_line - offset) == entry.text then return saved_line - offset end
    if at(saved_line + offset) == entry.text then return saved_line + offset end
  end
  return nil
end

local function save_fold_state(bufnr)
  if bufnr == nil or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  if not should_persist(bufnr) then return end
  local path = fold_state_path(bufnr)
  if path == nil then return end
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then return end

  local closed = vim.api.nvim_win_call(winid, function() return collect_closed_folds(bufnr) end)
  local fh = io.open(path, "w")
  if fh == nil then return end
  fh:write(vim.json.encode { closed = closed })
  fh:close()
end

local function apply_fold_state(target_buf, state)
  if not vim.api.nvim_buf_is_valid(target_buf) then return end
  local winid = vim.fn.bufwinid(target_buf)
  if winid == -1 then return end

  -- Switch foldmethod=manual and lower foldlevel for the window.
  -- AstroNvim sets foldlevel=99 globally, which auto-opens any fold at
  -- level <= 99 — including the manual level-1 folds we're about to
  -- create.  Drop it to 0 so the closed state set by :N,Mfoldclose
  -- isn't overridden on the next redraw.  vim.wo inside nvim_win_call
  -- can be unreliable across versions, so use the explicit API.
  vim.api.nvim_set_option_value("foldmethod", "manual", { win = winid })
  vim.api.nvim_set_option_value("foldlevel", 0, { win = winid })

  vim.api.nvim_win_call(winid, function()
    pcall(vim.cmd, "silent! normal! zE")
    for _, entry in ipairs(state.closed) do
      local start_line = locate_fold_start(target_buf, entry)
      if start_line ~= nil then
        local saved_start = entry.start_line or entry.line
        local saved_end = entry.end_line or saved_start
        local end_line = saved_end + (start_line - saved_start)
        local last = vim.api.nvim_buf_line_count(target_buf)
        if end_line > last then end_line = last end
        if end_line >= start_line then
          -- `:N,Mfold` creates a manual fold (initially closed), but
          -- AstroNvim's global `foldlevel=99` auto-opens any fold at
          -- level <= 99 immediately after creation.  Re-close it with
          -- `:N,Mfoldclose` — under foldmethod=manual there's no
          -- nested ambiguity, so this targets exactly our fold.
          if pcall(vim.cmd, string.format("%d,%dfold", start_line, end_line)) then
            pcall(vim.cmd, string.format("%d,%dfoldclose", start_line, end_line))
          end
        end
      end
    end
  end)
end

local function load_fold_state(bufnr)
  if bufnr == nil or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  if not should_persist(bufnr) then return end
  local path = fold_state_path(bufnr)
  if path == nil or vim.fn.filereadable(path) == 0 then return end

  local fh = io.open(path, "r")
  if fh == nil then return end
  local content = fh:read("*a")
  fh:close()

  local ok, state = pcall(vim.json.decode, content)
  if not ok or type(state) ~= "table" or type(state.closed) ~= "table" then return end
  if #state.closed == 0 then return end

  local target_buf = bufnr
  vim.schedule(function() apply_fold_state(target_buf, state) end)
end

vim.api.nvim_create_autocmd({ "BufWritePost", "BufLeave", "BufWinLeave", "BufHidden" }, {
  group = fold_persistence,
  callback = function(args) save_fold_state(args.buf) end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = fold_persistence,
  callback = function()
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      local bufnr = vim.api.nvim_win_get_buf(winid)
      vim.api.nvim_win_call(winid, function() save_fold_state(bufnr) end)
    end
  end,
})

-- Auto-apply saved fold state on file open.  load_fold_state itself
-- skips early when no JSON exists or its `closed` list is empty, so
-- files without persisted folds keep their default (treesitter) folding.
-- Note: applying *does* switch the buffer to foldmethod=manual + foldlevel=0
-- (that's how the closed state is made to stick); to get treesitter folds
-- back run `:setlocal foldmethod=expr | setlocal foldlevel=99`.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = fold_persistence,
  callback = function(args) load_fold_state(args.buf) end,
})

vim.api.nvim_create_user_command("SaveFolds", function() save_fold_state(0) end, {})
vim.api.nvim_create_user_command("LoadFolds", function() load_fold_state(0) end, {})
vim.api.nvim_create_user_command("ShowFoldState", function()
  local path = fold_state_path(0)
  if path == nil then
    vim.notify("No file path for current buffer", vim.log.levels.WARN)
    return
  end
  if vim.fn.filereadable(path) == 0 then
    vim.notify("No saved fold state at " .. path, vim.log.levels.INFO)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end, { desc = "Open the JSON sidecar with this buffer's saved closed folds" })

-- Walk up the treesitter tree from cursor to find the smallest node
-- spanning at least two lines.  For markdown that's a `section`; for
-- code it's typically a function / class / block.  Returns 1-indexed
-- (start_line, end_line) or nil.
local function ts_section_at_cursor()
  local cursor_row = vim.fn.line "." - 1
  local cursor_col = math.max(0, vim.fn.col "." - 1)
  local ok, node = pcall(vim.treesitter.get_node, { pos = { cursor_row, cursor_col } })
  if not ok or node == nil then return nil end
  while node ~= nil do
    local sr, _, er, _ = node:range()
    if er > sr + 1 then return sr + 1, er end
    node = node:parent()
  end
  return nil
end

-- `zc` fallback: when the normal-mode `zc` finds no fold at the cursor
-- (the typical case in a buffer where fold persistence has switched
-- foldmethod to manual and only the saved ranges have folds), use
-- treesitter to discover the smallest enclosing section/definition
-- and turn it into a closed manual fold.  Auto-save will pick it up
-- on the next BufLeave / BufWritePost.
vim.keymap.set("n", "zc", function()
  local cursor = vim.fn.line "."
  if pcall(vim.cmd, "silent! normal! zc") and vim.fn.foldclosed(cursor) ~= -1 then
    return
  end
  local start_line, end_line = ts_section_at_cursor()
  if start_line == nil then
    vim.notify("zc: no fold or treesitter section at cursor", vim.log.levels.WARN)
    return
  end
  pcall(vim.cmd, string.format("%d,%dfold", start_line, end_line))
  pcall(vim.cmd, string.format("%d,%dfoldclose", start_line, end_line))
end, { desc = "Close fold (fallback: treesitter section)" })

-- Fold all sections that do NOT contain the cursor, in a given line range.
-- Walks each line, attempts `zc` (close innermost fold at line). If the closed
-- fold turns out to span the cursor, undoes with `zo` and moves on.
-- Skips past already-closed folds for efficiency. Works with any foldmethod
-- (manual / marker / expr / treesitter) since it only operates on existing
-- folds, never creates them.
local function fold_range_excluding_cursor(start_line, end_line)
  if start_line > end_line then return end
  local cursor = vim.fn.line "."
  local saved_view = vim.fn.winsaveview()
  local saved_lz = vim.opt.lazyredraw:get()
  vim.opt.lazyredraw = true

  local line = start_line
  while line <= end_line do
    local fold_end = vim.fn.foldclosedend(line)
    if fold_end ~= -1 then
      line = fold_end + 1
    elseif vim.fn.foldlevel(line) == 0 then
      line = line + 1
    else
      vim.fn.cursor(line, 1)
      vim.cmd "silent! normal! zc"
      local cs = vim.fn.foldclosed(line)
      local ce = vim.fn.foldclosedend(line)

      if cs == -1 then
        line = line + 1
      elseif cs <= cursor and cursor <= ce then
        -- The just-closed fold spans the cursor; reopen and skip this line.
        vim.cmd "silent! normal! zo"
        line = line + 1
      else
        line = ce + 1
      end
    end
  end

  vim.opt.lazyredraw = saved_lz
  vim.fn.winrestview(saved_view)
end

local function fold_above_cursor()
  local cursor = vim.fn.line "."
  if cursor <= 1 then return end
  fold_range_excluding_cursor(1, cursor - 1)
end

local function fold_below_cursor()
  local cursor = vim.fn.line "."
  fold_range_excluding_cursor(cursor + 1, vim.fn.line "$")
end

-- Recursively open every fold in the line range. Uses Ex `foldopen!`
-- (range form), which is more efficient than walking with `zo` and works
-- with any foldmethod since it only opens existing folds.
local function unfold_range(start_line, end_line)
  if start_line > end_line then return end
  local saved_view = vim.fn.winsaveview()
  pcall(vim.cmd, string.format("silent! %d,%dfoldopen!", start_line, end_line))
  vim.fn.winrestview(saved_view)
end

local function unfold_above_cursor()
  local cursor = vim.fn.line "."
  if cursor <= 1 then return end
  unfold_range(1, cursor - 1)
end

local function unfold_below_cursor()
  unfold_range(vim.fn.line "." + 1, vim.fn.line "$")
end

vim.keymap.set("n", "<leader>zk", fold_above_cursor, { desc = "Fold all above cursor (level-aware)" })
vim.keymap.set("n", "<leader>zj", fold_below_cursor, { desc = "Fold all below cursor (level-aware)" })
vim.keymap.set("n", "<leader>zz", "zMzv", { desc = "Fold all but cursor's path (zMzv)" })
vim.keymap.set("n", "<leader>zK", unfold_above_cursor, { desc = "Unfold all above cursor" })
vim.keymap.set("n", "<leader>zJ", unfold_below_cursor, { desc = "Unfold all below cursor" })
vim.keymap.set("n", "<leader>zZ", "zR", { desc = "Unfold everything (zR)" })

-- :DiffOrig -- side-by-side diff of the current buffer against the version
-- saved on disk, i.e. exactly your *unsaved* changes (unlike gitsigns, which
-- diffs against git). Opens the on-disk content in a scratch vertical split.
-- Close that split (`:q`) to end; or run :DiffOff to clear the diff state.
vim.api.nvim_create_user_command("DiffOrig", function()
  local original = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(original) == "" then
    vim.notify("DiffOrig: buffer is not backed by a file", vim.log.levels.WARN)
    return
  end
  local ft = vim.bo[original].filetype
  vim.cmd "vertical new"
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  -- `#` is the alternate buffer (the original file) in this fresh window;
  -- `++edit` applies the file's own options while reading it from disk.
  vim.cmd "read ++edit #"
  vim.cmd "0d_" -- drop the empty first line `:read` leaves behind
  vim.bo.filetype = ft
  vim.cmd "diffthis"
  vim.cmd "wincmd p"
  vim.cmd "diffthis"
end, { desc = "Diff buffer against the saved file on disk (unsaved changes)" })

vim.api.nvim_create_user_command(
  "DiffOff",
  function() vim.cmd "diffoff!" end,
  { desc = "Turn off diff mode in all windows of the current tab" }
)

-- markdown-preview.nvim browser opener.
--
-- mkdp's bundled opener.js detects WSL and shells out to `cmd.exe /c start`;
-- with Windows interop disabled in this WSL that fails with
-- "Can not open browser by using cmd.exe command". mkdp's server.js calls
-- `g:mkdp_browserfunc` (if set) *instead of* opener.js, so we route the
-- preview URL through the existing `~/.local/bin/browser-detached`, which
-- already launches the Windows qutebrowser correctly. `detach` so the
-- browser outlives nvim. Defined as a Vim function because mkdp invokes it
-- by name over RPC (nvim_call_function).
vim.cmd [[
  function! MkdpBrowserOpen(url) abort
    call jobstart([expand('~/.local/bin/browser-detached'), a:url], {'detach': v:true})
  endfunction
]]
vim.g.mkdp_browserfunc = "MkdpBrowserOpen"

-- Search selected text (or the word under the cursor) on the web.
--
-- Reuses the same `~/.local/bin/browser-detached` launcher as the markdown
-- preview above, so it opens the Windows qutebrowser under WSL (and a native
-- qutebrowser elsewhere) without relying on cmd.exe interop. `detach` so the
-- browser outlives nvim.
local browser_detached = vim.fn.expand "~/.local/bin/browser-detached"
-- `%s` is replaced with the percent-encoded query. Kagi by default (no
-- captcha walls, and we're authenticated there in qutebrowser). Swap for e.g.
-- "https://duckduckgo.com/?q=%s" or "https://www.google.com/search?q=%s".
local search_url = "https://kagi.com/search?q=%s"

local function open_url(url) vim.fn.jobstart({ browser_detached, url }, { detach = true }) end

-- Percent-encode everything outside the RFC 3986 unreserved set.
local function urlencode(str)
  return (str:gsub("[^%w%-_%.~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end

-- If the text already looks like a URL, open it directly; otherwise search.
local function open_or_search(text)
  text = vim.trim((text or ""):gsub("%s+", " "))
  if text == "" then
    vim.notify("Nothing to search", vim.log.levels.WARN)
    return
  end
  if text:match "^%a[%w+.-]*://" then
    open_url(text)
  elseif text:match "^www%." then
    open_url("https://" .. text)
  else
    open_url(search_url:format(urlencode(text)))
  end
end

-- Grab the current visual selection without clobbering the unnamed register.
local function visual_selection()
  local saved = vim.fn.getreg '"'
  vim.cmd 'noau normal! "vy'
  local selected = vim.fn.getreg "v"
  vim.fn.setreg('"', saved)
  return selected
end

vim.keymap.set(
  "n",
  "<Leader>fb",
  function() open_or_search(vim.fn.expand "<cword>") end,
  { desc = "Search word under cursor in browser" }
)
vim.keymap.set(
  { "v", "x" },
  "<Leader>fb",
  function() open_or_search(visual_selection()) end,
  { desc = "Search selection in browser" }
)

vim.api.nvim_create_user_command(
  "SearchWeb",
  function(opts) open_or_search(opts.args ~= "" and opts.args or vim.fn.expand "<cword>") end,
  { nargs = "*", desc = "Search the web (args, or word under cursor) in the browser" }
)

-- Open an additional directory as a new tab rooted there: the tab gets its own
-- cwd (via :tcd), so its file tree, Telescope, and live-grep all scope to that
-- directory. resession saves each tab's cwd, so a saved session can span
-- multiple project roots. Add dirs, then <Leader>Ss to save / <Leader>Sf to
-- restore. Mapped to <Leader>Sa (prompts for the path) in astrocore.lua.
local function session_add_dir(dir)
  local path = vim.fn.fnamemodify(vim.fn.expand(dir), ":p")
  if vim.fn.isdirectory(path) == 0 then
    vim.notify("SessionAddDir: not a directory: " .. path, vim.log.levels.ERROR)
    return
  end
  vim.cmd.tabnew()
  vim.cmd.tcd(path)
  vim.cmd.Neotree "show" -- file tree rooted at the new tab's cwd
end

vim.api.nvim_create_user_command(
  "SessionAddDir",
  function(opts) session_add_dir(opts.args) end,
  { nargs = 1, complete = "dir", desc = "Open a directory as a new tab (adds a root to the session)" }
)

-- ]] / [[ / ][ / [] jump to the next/prev FUNCTION or CLASS, treesitter-based so
-- they work at any indentation (methods!) and in every language with a parser --
-- unlike Vim's built-in per-filetype motions (python's match only column 0).
-- Set buffer-local on FileType, `vim.schedule`d so they land AFTER any ftplugin's
-- own ]] mapping and thus win (same reason AstroNvim's ]f/]k win). Skips buffers
-- with no treesitter parser so ]] keeps its default there. The list query means
-- "next function OR class", whichever comes first.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ts_section_motions", { clear = true }),
  callback = function(ev)
    if not pcall(vim.treesitter.get_parser, ev.buf) then return end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then return end
      local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
      if not ok then return end
      local q = { "@function.outer", "@class.outer" }
      local function map(lhs, fn, desc)
        vim.keymap.set({ "n", "x", "o" }, lhs, fn, { buffer = ev.buf, silent = true, desc = desc })
      end
      map("]]", function() move.goto_next_start(q, "textobjects") end, "Next function/class")
      map("[[", function() move.goto_previous_start(q, "textobjects") end, "Prev function/class")
      map("][", function() move.goto_next_end(q, "textobjects") end, "Next function/class end")
      map("[]", function() move.goto_previous_end(q, "textobjects") end, "Prev function/class end")
    end)
  end,
})

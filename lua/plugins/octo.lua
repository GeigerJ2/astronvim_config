-- Jump to the next/prev review thread across ALL files in the active review.
-- octo's built-in ]t/[t (next_thread) only walk threads within the current
-- file's diff, so they no-op on a file that has none. dir = 1 forward, -1 back;
-- wraps around. Lands the cursor on the thread's line in the right (local-file)
-- diff window, switching files first when the next thread is in another file.
local function octo_goto_thread(dir)
  local ok, reviews = pcall(require, "octo.reviews")
  if not ok then return end
  local review = reviews.get_current_review()
  if review == nil or review.layout == nil then
    vim.notify("octo: no active review", vim.log.levels.WARN)
    return
  end
  local fp = require "octo.reviews.file-panel"
  local utils = require "octo.utils"
  local layout = review.layout
  local files = layout.files or {}

  -- Ordered (file-index, line) stops for every thread that still has comments.
  local stops = {}
  for fi, f in ipairs(files) do
    local lines = {}
    for _, t in ipairs(fp.threads_for_path(f.path)) do
      if t.comments ~= nil and #t.comments.nodes > 0 then table.insert(lines, t.startLine) end
    end
    table.sort(lines)
    for _, l in ipairs(lines) do
      table.insert(stops, { fi = fi, line = l, file = f })
    end
  end
  if #stops == 0 then
    vim.notify("octo: no review threads in this PR", vim.log.levels.INFO)
    return
  end

  -- Current position (file index + line); defaults put us before the first stop.
  local _, cur_path = utils.get_split_and_path(vim.api.nvim_get_current_buf())
  local cur_fi, cur_line = 0, 0
  if cur_path ~= nil then
    for fi, f in ipairs(files) do
      if f.path == cur_path then
        cur_fi = fi
        break
      end
    end
    cur_line = vim.fn.line "."
  end

  local target
  if dir >= 0 then
    for _, s in ipairs(stops) do
      if s.fi > cur_fi or (s.fi == cur_fi and s.line > cur_line) then
        target = s
        break
      end
    end
    target = target or stops[1] -- wrap to first
  else
    for i = #stops, 1, -1 do
      local s = stops[i]
      if s.fi < cur_fi or (s.fi == cur_fi and s.line < cur_line) then
        target = s
        break
      end
    end
    target = target or stops[#stops] -- wrap to last
  end

  local function place()
    local win = layout.right_winid
    if win ~= nil and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      pcall(vim.api.nvim_win_set_cursor, win, { target.line, 0 })
      vim.cmd "normal! zz"
    end
  end
  if target.fi ~= cur_fi then
    layout:set_current_file(target.file)
    vim.schedule(place) -- let the file switch settle before moving the cursor
  else
    place()
  end
end

---@type LazySpec
return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  opts = {
    use_local_fs = true, -- Use local files on right side of reviews
    enable_builtin = true,
    picker = "telescope",
    -- Explicit mappings to ensure they work
    mappings = {
      pull_request = {
        next_comment = { lhs = "]c", desc = "go to next comment" },
        prev_comment = { lhs = "[c", desc = "go to previous comment" },
      },
      review_thread = {
        next_comment = { lhs = "]c", desc = "go to next comment" },
        prev_comment = { lhs = "[c", desc = "go to previous comment" },
      },
      review_diff = {
        next_thread = { lhs = "]t", desc = "move to next thread" },
        prev_thread = { lhs = "[t", desc = "move to previous thread" },
        select_next_entry = { lhs = "]q", desc = "move to next file" },
        select_prev_entry = { lhs = "[q", desc = "move to previous file" },
      },
      submit_win = {
        approve_review = { lhs = "<A-a>", desc = "approve review" },
        comment_review = { lhs = "<A-m>", desc = "comment review" },
        request_changes = { lhs = "<A-r>", desc = "request changes review" },
      },
      file_panel = {
        next_entry = { lhs = "j", desc = "next file" },
        prev_entry = { lhs = "k", desc = "prev file" },
        select_entry = { lhs = "<cr>", desc = "select file" },
      },
    },
  },
  config = function(_, opts)
    require("octo").setup(opts)

    -- Keep :Octo review readable. octo mirrors GitHub with green/red diff
    -- backgrounds of its own: changed *text* via OctoReviewDiffAdd/DeleteText
    -- (white on dark green/red), and changed *lines* link DiffChange ->
    -- DiffAdd/DiffDelete per review window. That wash hides syntax highlighting,
    -- so blank the backgrounds (mark changed text with an underline instead).
    -- octo re-applies its colors on every colorscheme, so this autocmd is
    -- registered AFTER octo's own setup and thus runs last / wins.
    local octo_const = require "octo.constants"
    local function octo_plain_diff()
      vim.api.nvim_set_hl(0, "OctoReviewDiffAddText", { underline = true })
      vim.api.nvim_set_hl(0, "OctoReviewDiffDeleteText", { underline = true })
      for _, ns in ipairs { 0, octo_const.OCTO_REVIEW_LEFT_HIGHLIGHT_NS, octo_const.OCTO_REVIEW_RIGHT_HIGHLIGHT_NS } do
        for _, g in ipairs { "DiffAdd", "DiffDelete", "DiffChange" } do
          vim.api.nvim_set_hl(ns, g, { bg = "NONE" })
        end
      end
    end
    octo_plain_diff()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = octo_plain_diff })

    -- :OctoPrEditCurrent — edit the PR for the current branch (no number needed)
    vim.api.nvim_create_user_command('OctoPrEditCurrent', function()
      local result = vim.fn.system('gh pr view --json number -q .number')
      local pr_number = vim.trim(result)
      if pr_number ~= '' and tonumber(pr_number) then
        vim.cmd('Octo pr edit ' .. pr_number)
      else
        vim.notify('No PR found for current branch', vim.log.levels.WARN)
      end
    end, {})

    -- :OctoPrChecksCurrent — show PR checks for the current branch without
    -- first opening the PR buffer. Calls octo's M.pr_checks directly with a
    -- minimal buffer-shaped table { number, repo }.
    vim.api.nvim_create_user_command('OctoPrChecksCurrent', function()
      local pr_number = vim.trim(vim.fn.system('gh pr view --json number -q .number'))
      if pr_number == '' or not tonumber(pr_number) then
        vim.notify('No PR found for current branch', vim.log.levels.WARN)
        return
      end
      local repo = vim.trim(vim.fn.system('gh repo view --json nameWithOwner -q .nameWithOwner'))
      if repo == '' then
        vim.notify('Cannot determine repo', vim.log.levels.WARN)
        return
      end
      require('octo.commands').pr_checks { number = tonumber(pr_number), repo = repo }
    end, {})

    -- Show filename in winbar on octo:// buffers so they align vertically
    -- with the right-side local file that has barbecue's winbar.
    -- barbecue.lua skips octo:// buffers, so this winbar won't be overwritten.
    vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
      callback = function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if not bufname:match "^octo://" then return end
        local filename = bufname:match "([^/]+)$" or bufname
        vim.wo[0].winbar = " 󰈔 " .. filename
      end,
    })

    -- Patch FileEntry.show_diff to use nvim_win_call instead of nvim_buf_call.
    -- The original calls :diffthis via nvim_buf_call which doesn't properly
    -- switch window context, so diff mode may not activate on both windows.
    local FileEntry = require("octo.reviews.file-entry").FileEntry
    FileEntry.show_diff = function(self)
      for _, bufid in ipairs { self.left_bufid, self.right_bufid } do
        if not bufid or not vim.api.nvim_buf_is_valid(bufid) then goto continue end
        -- Find the window showing this buffer (only in current tab)
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufid then
            vim.api.nvim_win_call(winid, function()
              if vim.fn.bufname(bufid):match "octo://" then
                -- `silent!`: filetype detect runs `doautocmd filetypedetect BufRead`,
                -- which matches nothing on octo's synthetic buffers and otherwise
                -- prints "No matching autocommands" (a message pcall can't swallow),
                -- forcing a hit-enter prompt per file.
                pcall(vim.cmd, "silent! filetype detect")
              end
              pcall(vim.cmd, "silent! doautocmd BufEnter")
              pcall(vim.cmd.diffthis)
              pcall(vim.cmd.exec, [["normal! \<c-y>"]])
              -- Wrap long lines with smooth scrolling so both diff
              -- windows stay visually aligned (like GitHub's web UI)
              vim.wo[winid].wrap = true
              vim.wo[winid].linebreak = true
              vim.wo[winid].smoothscroll = true
              vim.wo[winid].breakindent = true
              -- Diff mode folds unchanged regions by default; show the whole
              -- file unfolded during review (every line visible).
              vim.wo[winid].foldenable = false
            end)
            break
          end
        end
        ::continue::
      end
      -- Make right-side (local file) buffer modifiable so edits can be made
      -- during review. Octo sets modifiable=false on all review buffers.
      if self.right_bufid and vim.api.nvim_buf_is_valid(self.right_bufid) then
        vim.bo[self.right_bufid].modifiable = true
      end
    end
  end,
  keys = {
    -- gX: open the PR/issue under the cursor in octo, inside nvim (mirrors the
    -- built-in gx → open-in-browser). Handles a full GitHub URL (any repo),
    -- owner/repo#N, #N, or a bare number (current repo); octo's :Octo parses
    -- each form. Lazy-loads octo on first press.
    {
      "gX",
      function()
        local word = vim.fn.expand "<cWORD>"
        local url = word:match "%((https?://[^)%s]+)" or word:match "(https?://[^%s)]+)"
        if url then
          vim.cmd { cmd = "Octo", args = { (url:gsub("[%.,;:%)]+$", "")) } }
          return
        end
        local owner_repo, num = word:match "([%w%._%-]+/[%w%._%-]+)#(%d+)"
        if owner_repo then
          vim.cmd { cmd = "Octo", args = { num, owner_repo } }
          return
        end
        num = word:match "#(%d+)" or word:match "^(%d+)$"
        if num then
          vim.cmd { cmd = "Octo", args = { num } }
          return
        end
        vim.notify("gX: no PR/issue URL or #ref under the cursor", vim.log.levels.WARN)
      end,
      desc = "Octo: open PR/issue under cursor",
    },
    {
      "<localleader>oi",
      "<CMD>Octo issue list<CR>",
      desc = "List GitHub Issues",
    },
    {
      "<localleader>op",
      "<CMD>Octo pr list<CR>",
      desc = "List GitHub PullRequests",
    },
    {
      "<localleader>od",
      "<CMD>Octo discussion list<CR>",
      desc = "List GitHub Discussions",
    },
    {
      "<localleader>on",
      "<CMD>Octo notification list<CR>",
      desc = "List GitHub Notifications",
    },
    {
      "<localleader>oe",
      "<CMD>OctoPrEditCurrent<CR>",
      desc = "Octo: Edit current branch PR",
    },
    {
      "<localleader>oc",
      "<CMD>OctoPrChecksCurrent<CR>",
      desc = "Octo: PR checks for current branch",
    },
    {
      "<localleader>os",
      function() require("octo.utils").create_base_search_command { include_current_repo = true } end,
      desc = "Search GitHub",
    },
    -- Cross-file thread navigation (octo's ]t/[t only move within one file).
    {
      "<localleader>ot",
      function() octo_goto_thread(1) end,
      desc = "Octo: next review thread (any file)",
    },
    {
      "<localleader>oT",
      function() octo_goto_thread(-1) end,
      desc = "Octo: prev review thread (any file)",
    },
    -- Jump to local file at current line in a new tab
    {
      "<localleader>of",
      function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local line = vim.api.nvim_win_get_cursor(0)[1]
        local filepath = nil

        if bufname:match "^/" or bufname:match "^%a:" then
          filepath = bufname
        else
          local cwd = vim.fn.getcwd()
          filepath = bufname:match "octo://[^/]+/[^/]+/pull/%d+/(.+)$"
            or bufname:match "octo://.*review_diff.*//([^%?]+)"
            or bufname:match "octo://.*//(.+)$"
            or bufname:match "//([^/]+%.%w+)$"
            or bufname:match "/pull/%d+/(.+)$"

          if filepath then
            filepath = filepath:gsub("%?.*$", "")
            if not filepath:match "^/" then filepath = cwd .. "/" .. filepath end
          end
        end

        if filepath and vim.fn.filereadable(filepath) == 1 then
          vim.cmd "tabnew"
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          vim.api.nvim_win_set_cursor(0, { line, 0 })
          vim.cmd "normal! zz"
        else
          vim.notify("Could not open file: " .. (filepath or bufname), vim.log.levels.WARN)
        end
      end,
      desc = "Octo: Jump to file in new tab",
    },
    -- Alternative: open in split
    {
      "<localleader>oF",
      function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local line = vim.api.nvim_win_get_cursor(0)[1]

        local filepath = nil

        if bufname:match "^/" or bufname:match "^%a:" then
          filepath = bufname
        else
          local cwd = vim.fn.getcwd()
          filepath = bufname:match "octo://[^/]+/[^/]+/pull/%d+/(.+)$"
            or bufname:match "octo://.*review_diff.*//([^%?]+)"
            or bufname:match "octo://.*//(.+)$"
            or bufname:match "//([^/]+%.%w+)$"
            or bufname:match "/pull/%d+/(.+)$"

          if filepath then
            filepath = filepath:gsub("%?.*$", "")
            if not filepath:match "^/" then filepath = cwd .. "/" .. filepath end
          end
        end

        if filepath and vim.fn.filereadable(filepath) == 1 then
          vim.cmd("vsplit " .. vim.fn.fnameescape(filepath))
          vim.api.nvim_win_set_cursor(0, { line, 0 })
          vim.cmd "normal! zz"
        else
          vim.notify("Could not open file in split", vim.log.levels.WARN)
        end
      end,
      desc = "Octo: Open file in split",
    },
    -- Maximize the right (local file) pane, turning off diff mode.
    -- Octo's ensure_layout will restore the two-pane diff on file switch.
    {
      "<localleader>om",
      function()
        local reviews = require "octo.reviews"
        local current_review = reviews.get_current_review()
        if not current_review or not current_review.layout then
          vim.notify("No active review", vim.log.levels.WARN)
          return
        end
        local layout = current_review.layout
        local right_win = layout.right_winid
        local left_win = layout.left_winid

        if not vim.api.nvim_win_is_valid(right_win) then return end

        -- If left window exists, close it + file panel and diffoff
        if vim.api.nvim_win_is_valid(left_win) then
          vim.api.nvim_set_current_win(right_win)
          vim.cmd "diffoff"
          -- Close file panel first (so it doesn't interfere)
          if layout.file_panel and layout.file_panel:is_open() then
            layout.file_panel:close()
          end
          vim.api.nvim_win_close(left_win, true)
        else
          -- Restore: ensure_layout recreates missing windows and re-diffs
          layout:ensure_layout()
          local file = layout:get_current_file()
          if file then layout:set_current_file(file) end
        end
      end,
      desc = "Octo: Toggle full-screen file view",
    },
    -- Toggle line wrap on all diff windows in current tab
    {
      "<localleader>ow",
      function()
        local new_wrap = not vim.wo.wrap
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_is_valid(winid) and vim.wo[winid].diff then
            vim.wo[winid].wrap = new_wrap
            vim.wo[winid].linebreak = new_wrap
            vim.wo[winid].smoothscroll = new_wrap
            vim.wo[winid].breakindent = new_wrap
          end
        end
        vim.notify("Line wrap " .. (new_wrap and "enabled" or "disabled"), vim.log.levels.INFO)
      end,
      desc = "Octo: Toggle line wrap (both windows)",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
  },
}

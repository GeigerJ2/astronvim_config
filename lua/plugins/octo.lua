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
      file_panel = {
        next_entry = { lhs = "j", desc = "next file" },
        prev_entry = { lhs = "k", desc = "prev file" },
        select_entry = { lhs = "<cr>", desc = "select file" },
      },
    },
  },
  config = function(_, opts)
    require("octo").setup(opts)

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
                pcall(vim.cmd.filetype, [[detect]])
              end
              pcall(vim.cmd.doau, [[BufEnter]])
              pcall(vim.cmd.diffthis)
              pcall(vim.cmd.exec, [["normal! \<c-y>"]])
              -- Wrap long lines with smooth scrolling so both diff
              -- windows stay visually aligned (like GitHub's web UI)
              vim.wo[winid].wrap = true
              vim.wo[winid].linebreak = true
              vim.wo[winid].smoothscroll = true
              vim.wo[winid].breakindent = true
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
      "<localleader>os",
      function() require("octo.utils").create_base_search_command { include_current_repo = true } end,
      desc = "Search GitHub",
    },
    -- Jump to local file at current line in next tab
    {
      "<localleader>of",
      function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local line = vim.api.nvim_win_get_cursor(0)[1]

        print("DEBUG - Full buffer name: " .. bufname)

        local filepath = nil

        -- Check if it's already a local file path (use_local_fs = true)
        if bufname:match "^/" or bufname:match "^%a:" then
          -- It's already a local file path
          filepath = bufname
          print "DEBUG - Already a local file"
        else
          -- It's an octo:// buffer, extract the path
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

        if filepath then
          print("DEBUG - Filepath: " .. filepath)

          -- Check if file exists and is readable
          if vim.fn.filereadable(filepath) == 1 then
            print "DEBUG - File is readable"

            -- Check if buffer is modifiable
            local is_modifiable = vim.bo[0].modifiable
            print("DEBUG - Current buffer modifiable: " .. tostring(is_modifiable))

            -- If we're already in the local file and it's not modifiable, make it so
            if bufname == filepath and not is_modifiable then
              vim.bo[0].modifiable = true
              vim.notify("Made buffer modifiable", vim.log.levels.INFO)
            else
              -- Open in next tab
              local current_tab = vim.api.nvim_get_current_tabpage()
              vim.cmd "tabnext"

              if vim.api.nvim_get_current_tabpage() == current_tab then vim.cmd "tabnew" end

              vim.cmd("edit " .. vim.fn.fnameescape(filepath))
              vim.api.nvim_win_set_cursor(0, { line, 0 })
              vim.cmd "normal! zz"
            end
          else
            vim.notify("File not readable: " .. filepath, vim.log.levels.ERROR)
          end
        else
          vim.notify("Could not determine file path. Buffer: " .. bufname, vim.log.levels.WARN)
        end
      end,
      desc = "Octo: Jump to file in next tab (or make modifiable)",
    },
    -- Make current buffer modifiable
    {
      "<localleader>om",
      function()
        local is_modifiable = vim.bo[0].modifiable
        if not is_modifiable then
          vim.bo[0].modifiable = true
          vim.notify("Buffer is now modifiable", vim.log.levels.INFO)
        else
          vim.notify("Buffer is already modifiable", vim.log.levels.INFO)
        end
      end,
      desc = "Octo: Make buffer modifiable",
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

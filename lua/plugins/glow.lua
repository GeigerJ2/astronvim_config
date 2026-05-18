-- glow.nvim only renders into a `relative = "editor"` floating window, so
-- `:Glow` itself cannot be a split. `:GlowSplit` (below) reuses glow.nvim's
-- proven approach -- feed `glow`'s ANSI output into a terminal channel so
-- colours render -- but targets a real vertical split. It renders from the
-- buffer's *contents* (unsaved edits included), refreshes on save, and leaves
-- the cursor in the source window so you can edit and preview side by side.

---@type integer? terminal channel of the live preview, if any
local function glow_split()
  local src_buf = vim.api.nvim_get_current_buf()
  local src_win = vim.api.nvim_get_current_win()

  if vim.bo[src_buf].filetype == "glowpreview" then
    return -- invoked from inside the preview itself
  end

  -- Toggle: a second invocation from the source closes the open preview.
  local open_win = vim.b[src_buf].glow_split_win
  if open_win and vim.api.nvim_win_is_valid(open_win) then
    vim.api.nvim_win_close(open_win, true)
    return
  end

  if vim.bo[src_buf].filetype ~= "markdown" then
    vim.notify("GlowSplit: not a markdown buffer", vim.log.levels.WARN)
    return
  end

  local cfg = require("glow").config
  local glow_path = (cfg and cfg.glow_path ~= "" and cfg.glow_path) or vim.fn.exepath "glow"
  if glow_path == "" then
    vim.notify("GlowSplit: glow binary not found -- run :Glow once to install it", vim.log.levels.ERROR)
    return
  end
  local style = tostring((cfg and cfg.style) or vim.o.background)

  -- Vertical split on the far right holding a scratch terminal buffer.
  local preview_buf = vim.api.nvim_create_buf(false, true)
  vim.cmd "botright vsplit"
  local preview_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].filetype = "glowpreview"
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].signcolumn = "no"
  vim.wo[preview_win].spell = false
  vim.wo[preview_win].cursorline = false

  local chan = vim.api.nvim_open_term(preview_buf, {})
  vim.b[src_buf].glow_split_win = preview_win

  local function render()
    if not vim.api.nvim_buf_is_valid(preview_buf) or not vim.api.nvim_buf_is_valid(src_buf) then return end
    -- Render to the split's *current* width so glow fills it. glamour insets
    -- ~2 cols within `-w`, so passing the full width leaves a clean gutter
    -- without horizontal scroll. Min 20 only to keep glow well-behaved.
    local width = vim.api.nvim_win_is_valid(preview_win) and vim.api.nvim_win_get_width(preview_win) or 80
    local content = table.concat(vim.api.nvim_buf_get_lines(src_buf, 0, -1, false), "\n")
    vim.system(
      { glow_path, "-s", style, "-w", tostring(math.max(width, 20)), "-" },
      { stdin = content, text = true },
      vim.schedule_wrap(function(res)
        if not vim.api.nvim_buf_is_valid(preview_buf) then return end
        if res.code ~= 0 then
          vim.notify("GlowSplit: glow failed\n" .. (res.stderr or ""), vim.log.levels.ERROR)
          return
        end
        -- Clear screen + scrollback, home cursor, then write fresh output.
        local out = (res.stdout or ""):gsub("\n", "\r\n")
        vim.api.nvim_chan_send(chan, "\27[2J\27[3J\27[H" .. out)
      end)
    )
  end

  -- Defer the first render: `botright vsplit` hasn't been laid out yet, so
  -- measuring width synchronously here returns a stale/small value.
  vim.schedule(render)

  local group = vim.api.nvim_create_augroup("GlowSplit_" .. src_buf, { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", { group = group, buffer = src_buf, callback = render })
  -- Re-wrap to the new width whenever the split (or the UI) is resized.
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function()
      if vim.api.nvim_win_is_valid(preview_win) then render() end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = src_buf,
    callback = function()
      if vim.api.nvim_win_is_valid(preview_win) then vim.api.nvim_win_close(preview_win, true) end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = preview_buf,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
      if vim.api.nvim_buf_is_valid(src_buf) then vim.b[src_buf].glow_split_win = nil end
    end,
  })

  local close = function()
    if vim.api.nvim_win_is_valid(preview_win) then vim.api.nvim_win_close(preview_win, true) end
  end
  vim.keymap.set("n", "q", close, { buffer = preview_buf, silent = true, desc = "Close Glow preview" })
  vim.keymap.set("n", "<Esc>", close, { buffer = preview_buf, silent = true, desc = "Close Glow preview" })

  -- Keep editing where you were.
  if vim.api.nvim_win_is_valid(src_win) then vim.api.nvim_set_current_win(src_win) end
end

return {
  "ellisonleao/glow.nvim",
  cmd = { "Glow", "GlowSplit" },
  opts = {
    border = "none",
    width = 999,
    height = 999,
    width_ratio = 1.0,
    height_ratio = 1.0,
  },
  keys = {
    {
      "<leader>mg",
      function()
        vim.cmd "tabnew %"
        vim.cmd "Glow"
      end,
      desc = "Glow fullscreen (new tab)",
    },
    {
      "<leader>mv",
      "<cmd>GlowSplit<cr>",
      ft = "markdown",
      desc = "Glow preview (vertical split, live)",
    },
  },
  config = function(_, opts)
    require("glow").setup(opts)
    vim.api.nvim_create_user_command(
      "GlowSplit",
      glow_split,
      { desc = "Toggle a live glow markdown preview in a vertical split" }
    )
  end,
}

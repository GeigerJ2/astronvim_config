-- resession extension: persist neo-tree panels across sessions.
--
-- resession drops neo-tree buffers from the saved window layout (they are not
-- "restorable" per astrocore's buf_filter), so the file tree disappears when a
-- session is loaded. This extension records the neo-tree panels open in each
-- tab (source, position, size) and reopens them after the session is restored,
-- rooted at each tab's restored working directory.
--
-- Registered via lua/plugins/resession.lua (`extensions = { neotree = {} }`).

local M = {}

-- neo-tree tags its buffers with these buffer-local variables (set in
-- neo-tree/ui/renderer.lua). Returns nil for non-neo-tree windows.
local function neotree_panel(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local ok, source = pcall(vim.api.nvim_buf_get_var, bufnr, "neo_tree_source")
  if not ok then return nil end
  local _, position = pcall(vim.api.nvim_buf_get_var, bufnr, "neo_tree_position")
  return {
    source = source,
    position = position or "left",
    width = vim.api.nvim_win_get_width(winid),
    height = vim.api.nvim_win_get_height(winid),
  }
end

-- Stored as a list (not a sparse map) so tab indices survive resession's JSON
-- round-trip, which would otherwise coerce integer keys to strings.
M.on_save = function()
  local tabs = {}
  for index, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local panels = {}
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      local panel = neotree_panel(winid)
      if panel ~= nil then table.insert(panels, panel) end
    end
    if next(panels) ~= nil then table.insert(tabs, { index = index, panels = panels }) end
  end
  return { tabs = tabs }
end

M.on_post_load = function(data)
  if data == nil or data.tabs == nil then return end
  local tabpages = vim.api.nvim_list_tabpages()
  local restore_to = vim.api.nvim_get_current_tabpage()
  for _, entry in ipairs(data.tabs) do
    local tabpage = tabpages[entry.index]
    if tabpage ~= nil and vim.api.nvim_tabpage_is_valid(tabpage) then
      vim.api.nvim_set_current_tabpage(tabpage)
      for _, panel in ipairs(entry.panels) do
        pcall(function()
          -- `action=show` reveals the panel without stealing focus.
          vim.cmd(("Neotree action=show source=%s position=%s"):format(panel.source, panel.position))
          for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
            if neotree_panel(winid) ~= nil then
              if panel.position == "left" or panel.position == "right" then
                vim.api.nvim_win_set_width(winid, panel.width)
              else
                vim.api.nvim_win_set_height(winid, panel.height)
              end
            end
          end
        end)
      end
    end
  end
  if vim.api.nvim_tabpage_is_valid(restore_to) then vim.api.nvim_set_current_tabpage(restore_to) end
end

return M

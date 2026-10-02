-- LSP in diffview's file panes (K, gd, ...).
--
-- Diffview shows files as nowrite `diffview://...` buffers, to which no language
-- server attaches by itself, so K (hover: signature, docstring) does nothing in
-- :ReviewCommits (<Leader>gc). This attaches the language servers already running
-- for the repo to those buffers (the server then analyses them as in-memory
-- documents, resolving imports against the checked-out files). When no server for
-- the file type runs yet, the checked-out copy of the file is loaded once (hidden)
-- so the normal LSP startup runs, and the server attaches as soon as it is up.
-- Diagnostics stay off in these buffers: they are historical blobs.
local M = {}

local kickstarted = {} -- "<toplevel>\0<filetype>" -> true

local function current_view()
  local ok, lib = pcall(require, "diffview.lib")
  return ok and lib.get_current_view() or nil
end

local function serves(client, toplevel, filetype)
  local filetypes = client.config.filetypes
  local right_type = filetypes == nil or vim.tbl_contains(filetypes, filetype)
  local root = client.config.root_dir
  return right_type and type(root) == "string" and (root == toplevel or vim.startswith(toplevel, root .. "/"))
end

local function kickstart(toplevel, filetype, relpath)
  local key = toplevel .. "\0" .. filetype
  if kickstarted[key] then return end
  local real = toplevel .. "/" .. relpath
  if vim.fn.filereadable(real) == 0 then return end
  kickstarted[key] = true
  local buf = vim.fn.bufadd(real)
  vim.fn.bufload(buf)
  vim.api.nvim_buf_call(buf, function() vim.cmd "silent! filetype detect" end)
end

function M.attach()
  local view = current_view()
  if view == nil then return end
  local toplevel = view.adapter.ctx.toplevel
  local file = view:infer_cur_file()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local filetype = vim.bo[buf].filetype
    if vim.startswith(vim.api.nvim_buf_get_name(buf), "diffview://") and vim.bo[buf].buftype == "nowrite" and filetype ~= "" then
      local found = false
      for _, client in ipairs(vim.lsp.get_clients()) do
        if serves(client, toplevel, filetype) then
          found = true
          if not vim.lsp.buf_is_attached(buf, client.id) then
            vim.lsp.buf_attach_client(buf, client.id)
            vim.diagnostic.enable(false, { bufnr = buf })
          end
        end
      end
      if not found and file ~= nil then kickstart(toplevel, filetype, file.path) end
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("diffview_lsp", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "DiffviewDiffBufWinEnter",
    callback = function() vim.schedule(M.attach) end,
  })
  -- A server that finishes starting (including the kickstarted one) attaches to
  -- the panes already on screen.
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function() vim.schedule(M.attach) end,
  })
end

return M

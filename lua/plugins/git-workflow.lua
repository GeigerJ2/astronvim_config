-- Two git-workflow keybinds:
--   <Leader>gM  Commit the prewritten repo-root COMMIT_EDITMSG (the file Claude
--               writes) from inside nvim, reviewing it in a gitcommit buffer
--               first -- the nvim equivalent of `git commit -eF COMMIT_EDITMSG`.
--   <Leader>gh  Toggle a floating `gh dash` (GitHub PR/issue dashboard), with its
--               clipboard routed through nvim so `y`/`Y` work even over SSH.

-- gh-dash copies via atotto/clipboard, which shells out to xsel/xclip/wl-copy.
-- Those write to the LOCAL X server, which is invisible when nvim runs over SSH
-- (the copy lands on the remote box's clipboard, not the client's). Shim those
-- tools -- first on the gh-dash terminal's PATH -- to instead forward the text
-- to THIS nvim's + register via its RPC socket ($NVIM); nvim's clipboard
-- provider then delivers it (OSC52 over the SSH pty) to the client terminal.
-- Works locally too: setreg('+') just uses the local clipboard path.
local function ensure_clip_shims()
  local dir = vim.fn.stdpath "cache" .. "/gh-dash-clip"
  vim.fn.mkdir(dir, "p")
  local shim = [[#!/bin/sh
# Managed by nvim (plugins/git-workflow.lua): route gh-dash copies through the
# parent nvim's + register so they work over SSH. Read requests are a no-op.
case "$0" in *wl-paste) exit 0 ;; esac
case "$*" in *-o*) exit 0 ;; esac
tmp=$(mktemp) || exit 0
cat > "$tmp"
if [ -n "${NVIM:-}" ] && command -v nvim >/dev/null 2>&1; then
  nvim --server "$NVIM" --remote-expr "setreg('+', join(readfile('$tmp'), \"\n\"))" >/dev/null 2>&1
else
  printf '\033]52;c;%s\007' "$(base64 -w0 < "$tmp" 2>/dev/null)" > /dev/tty 2>/dev/null
fi
rm -f "$tmp"
exit 0
]]
  for _, name in ipairs { "xsel", "xclip", "wl-copy", "wl-paste" } do
    local f = io.open(dir .. "/" .. name, "w")
    if f ~= nil then
      f:write(shim)
      f:close()
      vim.fn.setfperm(dir .. "/" .. name, "rwxr-xr-x")
    end
  end
  return dir
end

return {
  "AstroNvim/astrocore",
  opts = {
    mappings = {
      n = {
        ["<Leader>gM"] = {
          function()
            local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
            if vim.v.shell_error ~= 0 or root == nil or root == "" then
              vim.notify("Not in a git repository", vim.log.levels.WARN)
              return
            end
            local msg = root .. "/COMMIT_EDITMSG"
            if vim.fn.filereadable(msg) == 0 then
              vim.notify("No COMMIT_EDITMSG at " .. root, vim.log.levels.WARN)
              return
            end
            -- Open the prewritten message in a gitcommit buffer; committia.lua's
            -- FileType autocmd adds the 50/72 guides and <leader>lf formatter.
            vim.cmd("botright split " .. vim.fn.fnameescape(msg))
            vim.bo.filetype = "gitcommit"
            local buf = vim.api.nvim_get_current_buf()
            local function finish(do_commit)
              if do_commit then
                vim.cmd "silent write"
                -- --cleanup=strip matches the `-e` path (drops #-comment lines);
                -- -F takes the buffer verbatim. Commits the staged changes.
                local out = vim.fn.systemlist { "git", "-C", root, "commit", "--cleanup=strip", "-F", msg }
                local ok = vim.v.shell_error == 0
                vim.notify(table.concat(out, "\n"), ok and vim.log.levels.INFO or vim.log.levels.ERROR)
                if not ok then return end -- keep the buffer so you can fix and retry
              end
              if vim.api.nvim_buf_is_valid(buf) then vim.cmd("bwipeout! " .. buf) end
            end
            vim.keymap.set("n", "<C-c><C-c>", function() finish(true) end, { buffer = buf, desc = "Commit" })
            vim.keymap.set("n", "<C-c><C-k>", function() finish(false) end, { buffer = buf, desc = "Abort commit" })
            vim.notify "Review, then <C-c><C-c> to commit  ·  <C-c><C-k> to abort"
          end,
          desc = "Commit COMMIT_EDITMSG",
        },
        ["<Leader>gh"] = {
          function()
            local shimdir = ensure_clip_shims()
            require("astrocore").toggle_term_cmd {
              cmd = "gh dash",
              direction = "float",
              -- gh dash is a full-screen TUI; a near-full float gives it room.
              float_opts = {
                width = function() return math.floor(vim.o.columns * 0.9) end,
                height = function() return math.floor(vim.o.lines * 0.9) end,
              },
              -- Clipboard shims first on PATH so `y`/`Y` route through nvim.
              env = { PATH = shimdir .. ":" .. vim.env.PATH, NVIM = vim.v.servername },
            }
          end,
          desc = "gh dash (GitHub dashboard)",
        },
      },
    },
  },
}

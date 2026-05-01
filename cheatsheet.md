# Neovim Cheatsheet

Exhaustive reference: built-in power moves + bindings, commands, and behaviors
from this config (AstroNvim base + custom plugins).

`<Leader>` is `<Space>`. `<LocalLeader>` is `,` (AstroNvim default).
Open from inside nvim: `:e ~/.config/nvim/cheatsheet.md`.

---

## 0. Known overrides / conflicts vs AstroNvim defaults

Where this config deviates from AstroNvim defaults, in case you ever wonder
"why isn't `<X>` doing what the docs say?":

| Key | AstroNvim default | This config |
|-----|------------------|-------------|
| `<Leader>fp` | snacks "find projects" | `:CopyRelativeFilePath` (custom plugin) |
| `<Leader>fj` | — | telescope projects (replacement for above) |
| `<Leader>fo` | snacks "find old/recent" | telescope-frecency (cwd) |
| `<Leader>fO` | snacks "find old (root)" | telescope-frecency (all) |
| `<Leader>fu` | snacks undo | telescope-undo |
| `<Leader>fh` | snacks help | `:CopyRelativeFilePathFromHome` |
| `<Leader>fn` | snacks notifications | `:CopyFileName` |
| `]b` `[b` | next/prev buffer | next/prev buffer (count-aware re-impl) |
| `<Leader>lf` | format buffer | format buffer *(restored)* |

All previously-conflicting overrides have been moved to non-colliding keys:
`<Leader>tT` (coverage toggle), `<Leader>tL` (load coverage file),
`<Leader>uX` (baleia ANSI), `<Leader>Z` (maximize).
AstroNvim's `<Leader>tt` (ToggleTerm), `<Leader>tl` (lazygit),
`<Leader>uA` (autochdir), and `<Leader>z` (no longer hijacked) are intact.

---

## 1. Built-in Vim/Neovim

### 1.1 Motion / jumps
- `h j k l` / `w b e ge` / `W B E gE` — char / WORD vs word boundaries
- `0` / `^` / `$` / `g_` — line start / first non-blank / end / last non-blank
- `f{c}` / `F{c}` / `t{c}` / `T{c}` — find char (forward / back; `t` stops before)
- `;` / `,` — repeat last `f/F/t/T` forward / back
- `gg` / `G` / `{n}G` / `:{n}` — top / bottom / line n
- `H` / `M` / `L` — top / middle / bottom of screen
- `zz` / `zt` / `zb` — center / top / bottom current line on screen
- `<C-d>` / `<C-u>` / `<C-f>` / `<C-b>` — half / full page down / up
- `%` — match bracket / `#if/#else/#endif` / start/end of comment block
- `*` / `#` — search word forward / back; `g*` `g#` substring
- `n` / `N` — next / prev search match
- `''` / `` `` `` — last cursor pos in file (line / exact)
- `'.` / `` `. `` — last change position
- `'^` / `` `^ `` — last insert position
- `<C-o>` / `<C-i>` — jumplist back / forward (across files)
- `g;` / `g,` — changelist back / forward
- `gd` / `gD` — local / file-wide definition
- `gf` — go to file under cursor; `<C-w>f` open in split, `<C-w>gf` in tab
- `gx` — open URL/file via system handler
- `<C-^>` / `<C-6>` — alternate file (last buffer)
- `g<C-g>` — word/char count; `<C-g>` — file info

### 1.2 Text objects (`{op}{a|i}{obj}`)
- `iw` `aw` — word; `iW` `aW` — WORD
- `is` `as` — sentence; `ip` `ap` — paragraph
- `i"` `a"` `i'` `a'` `` i` `` `` a` `` — quoted strings
- `i(` `a(` `i[` `a[` `i{` `a{` `i<` `a<` — bracketed
- `it` `at` — XML/HTML tag
- *Treesitter (via AstroNvim defaults):* `if`/`af` function, `ic`/`ac` class,
  `ia`/`aa` parameter, `ii`/`ai` indent (vindent — see §6)

### 1.3 Editing
- `d` `c` `y` — delete / change / yank with motion or text object
- `dd` `cc` `yy` — line-wise; `D` `C` `Y` — to end of line
- `x` `X` — delete char forward / back
- `r{c}` `R` — replace single char / replace mode
- `s` `S` — substitute char / line (delete + insert)
- `~` — toggle case; `g~{motion}` `gu{motion}` `gU{motion}` — toggle / lower / upper
- `J` / `gJ` — join lines (with / without space)
- `>>` `<<` — indent / dedent line; `>{motion}` / `>i{` etc.
- `==` — auto-indent line; `={motion}` for range; `gg=G` whole file
- `gq{motion}` — format via `formatprg` (or LSP if `formatexpr` set)
- `<C-a>` / `<C-x>` — increment / decrement number
- `g<C-a>` (visual) — turn 1 into a sequence (1, 2, 3, …)
- `.` — repeat last change. Combine with `n` for "search-fix-each".
- `ZZ` / `ZQ` — save+quit / quit no save

### 1.4 Insert mode tricks
- `<C-r>{reg}` — paste register without leaving insert
- `<C-r>=` — eval expression and insert result
- `<C-r>+` / `<C-r>*` — paste system clipboard
- `<C-w>` — delete previous word; `<C-u>` — delete to start of line
- `<C-t>` / `<C-d>` — indent / dedent in insert
- `<C-o>{cmd}` — run one normal-mode command, then back to insert
- `<C-x><C-o>` — omni-completion (LSP); `<C-x><C-f>` — file path; `<C-x><C-l>` line
- `<C-n>` / `<C-p>` — next / prev completion (also keyword)

### 1.5 Visual mode
- `v` / `V` / `<C-v>` — char / line / block visual; `<Leader>vb` also block
- `gv` — re-select last visual selection
- `o` — toggle anchor end of selection
- In `<C-v>` block: `I{txt}<Esc>` — insert at start of every selected line;
  `A{txt}<Esc>` — append at end; `r{c}` — replace block; `c` — change block

### 1.6 Registers
- `"` — unnamed (last yank/delete)
- `0` — last yank only
- `1`–`9` — delete history (rotates)
- `+` / `*` — system clipboard (PRIMARY / CLIPBOARD)
- `/` — last search pattern
- `:` — last command-line
- `.` — last inserted text
- `%` — current filename; `#` — alternate filename
- `=` — expression register (insert via `<C-r>=`)
- `_` — black hole (use to delete without overwriting `"`): `"_dd`
- `:reg` — show all; `:reg "0+/*` — show specific

### 1.7 Marks
- `m{a-z}` — set local mark; `'{a-z}` jump line, `` `{a-z} `` jump exact
- `m{A-Z}` — global mark (across files)
- `:marks` — list
- `[m` / `]m` — start of next/prev method (when supported by 'define')

### 1.8 Macros
- `q{reg}` — start recording into register
- `q` — stop recording
- `@{reg}` — play back; `@@` — repeat last; `{n}@{reg}` — play n times
- `:'<,'>normal @q` — run macro on each visual line
- `q:` / `q/` / `q?` — open editable command / search / reverse-search history

### 1.9 Search & replace
- `/{pat}` `?{pat}` `n` `N` — forward / back / next / prev
- `:%s/old/new/g` — global; `:%s/old/new/gc` — confirm each
- `&` — repeat last `:s` on current line
- `:&&` — repeat last `:s` with same flags
- `g&` — repeat last `:s` on whole file
- `:s/old/new/g` (visual) operates on selection
- `\v` — very magic; `\<word\>` — whole word; `\c` / `\C` — case insens / sens
- `:%s//new/g` — empty pattern = reuse last search
- `:noh` — clear highlight; or set up an autocmd

### 1.10 Ex / shell
- `:!cmd` — run shell; `:r !cmd` — read output into buffer
- `:%!cmd` — pipe whole buffer through cmd (`:%!jq .`, `:%!sort -u`)
- `:.!cmd` — pipe current line; `:N,M!cmd` — pipe range
- `:e!` — reload from disk (drop changes)
- `:earlier 10m` / `:later 5m` — time-travel undo
- `:undolist` — undo branches; `:undo {n}`
- `:lua print(...)` / `:=expr` — evaluate Lua / vim expression
- `:checkhealth` — diagnose plugins/providers
- `:Inspect` — semantic / treesitter / extmark info under cursor
- `:InspectTree` — open treesitter tree view

### 1.11 Folds
- `zM` / `zR` — close all / open all
- `za` / `zA` — toggle current / recursively
- `zo` / `zO` `zc` / `zC` — open / close (recursively)
- `zm` / `zr` — fold more / less (one level)
- `zv` — open just enough to view cursor
- `zj` / `zk` (built-in) — next / prev fold start/end
- `zf{motion}` — manually create a fold (when `foldmethod=manual`)
- *Custom:*
  - `zp` — peek closed fold contents in floating window (q/Esc/zp dismiss)
  - `<Leader>zk` / `<Leader>zj` — fold all above / below cursor (level-aware)
  - `<Leader>zK` / `<Leader>zJ` — **un**fold all above / below cursor
  - `<Leader>zz` — `zMzv`: collapse all but the path to cursor
  - `<Leader>zZ` — `zR`: unfold everything (mirror of `<Leader>zz`)

> Note: maximize (see §10) lives on `<Leader>Z` (capital) so `<Leader>z`
> can be a clean prefix for the fold mappings above without `timeoutlen` delay.
- *Custom (persistence):* closed-fold start lines are snapshotted to a
  JSON sidecar in `~/.local/state/nvim/fold-state/` on
  `BufWritePost`/`BufLeave`/`BufWinLeave`/`BufHidden`/`VimLeavePre` and
  replayed on `BufWinEnter`/`BufReadPost` (with a 100 ms defer so
  LSP/treesitter foldexpr has computed the structure). Replaces the old
  `:mkview`/`:loadview` setup, which silently dropped `zc` deltas under
  AstroNvim's `foldmethod=expr` + `foldlevel=99`. Manually:
  `:SaveFolds`, `:LoadFolds`, `:ShowFoldState` (open the sidecar JSON).

### 1.12 Windows & tabs
- `<C-w>s` / `<C-w>v` — horizontal / vertical split
- `<C-w>q` / `<C-w>c` / `<C-w>o` — close / close (force kill) / only this window
- `<C-w>h/j/k/l` — move focus
- `<C-w>H/J/K/L` — move window to far left / bottom / top / right
- `<C-w>x` — swap with next window
- `<C-w>r` / `<C-w>R` — rotate down/right / up/left
- `<C-w>=` — equalize sizes
- `<C-w>_` / `<C-w>|` — max height / max width
- `<C-w>{n}+` / `<C-w>{n}-` — resize height; `<C-w>{n}>` / `<` width
- `<C-w>T` — move current window to a new tab
- `<C-w>p` — previous window
- `gt` / `gT` / `{n}gt` — next / prev / nth tab
- `:tabnew` `:tabclose` `:tabonly` `:tabmove {n}`
- *Custom:* `:TabDir <path>` — open dir in new tab with its own `tcd`
- *Custom:* `<Leader>|` — vsplit with previous buffer
- *Custom:* `<Leader>vb` — visual block (for layouts that eat `<C-v>`)

### 1.13 Buffers
- `:b {name|n}` `:bn` `:bp` `:bd` `:bw` — switch / next / prev / delete / wipe
- `:ls` / `:buffers` — list
- `<C-^>` — alternate buffer
- *Custom:* `]b` / `[b` — next / previous buffer (count-aware)
- *Custom:* `<Leader>bd` — close buffer via tabline picker

### 1.14 Quickfix / loclist
- `:cn` / `:cp` / `:cnf` / `:cpf` — next/prev (file)
- `:copen` / `:cclose` / `:cwindow` — open / close / open if non-empty
- `:cdo {cmd}` — run cmd on every quickfix entry
- `:cfdo {cmd}` — run cmd on every quickfix file
- `:lopen` / `:lne` etc. — same for loclist (window-local)
- From Telescope: `<C-q>` send all → quickfix; `<M-q>` send selected

### 1.15 Diff mode
- `]c` / `[c` — next / prev hunk
- `do` (`:diffget`) — pull change FROM other window
- `dp` (`:diffput`) — push change TO other window
- `:diffupdate` — refresh; `:diffoff` — turn off
- `:DiffviewOpen [rev..rev]` — diffview UI (community plugin)
- `:DiffviewFileHistory %` — file history
- *Custom:* `:DiffViewPR` — diff against detected PR base (gh → upstream/origin)

---

## 2. Telescope (search / navigate)

### 2.1 Custom pickers (this config)
- `<Leader>fv` *(visual)* — grep selected text
- `<Leader>fG` — live grep with rg args (regex/globs/--)
- `<Leader>fo` / `<Leader>fO` — frecent files (cwd / global) *(overrides snacks recent)*
- `<Leader>fu` — undo history picker (telescope-undo) *(overrides snacks undo)*
- `<Leader>fe` — file browser (current file's dir, recursive)
- `<Leader>fE` — file browser (cwd)
- `<Leader>f<CR>` — resume last Telescope search
- `<Leader>fj` — find projects (telescope) *(`<Leader>fp` was reused for
  copy-relative-path; AstroNvim's snacks "find projects" effectively lives at `<Leader>fj`)*
- `<Leader>lF` — LSP doc symbols, functions/methods only
- `<Leader>lC` — LSP doc symbols, classes/structs only
- `<Leader>lb` — buffer diagnostics
- *Search history is persistent (sqlite via telescope-smart-history)*

### 2.2 AstroNvim defaults you almost certainly have
- `<Leader>ff` — find files
- `<Leader>fF` — find files (all, no gitignore)
- `<Leader>fw` — live grep
- `<Leader>fW` — live grep (all)
- `<Leader>fb` — buffers
- `<Leader>fc` — word under cursor (grep)
- `<Leader>fr` — registers
- `<Leader>fk` — keymaps
- `<Leader>fh` — *overridden:* `:CopyRelativeFilePathFromHome` (was: snacks help)
- `<Leader>fm` — man pages
- `<Leader>fT` — find TODOs (todo-comments)
- `<Leader>fa` — autocmds; `<Leader>fC` — commands; `<Leader>fl` — loclist
- `<Leader>fs` — smart picker (buffers/recent/files)
- `<Leader>fg` — git files; `<Leader>ft` — colorschemes

### 2.3 Inside any Telescope picker
- `<C-n>` / `<C-p>` — next / prev result
- `<CR>` — open
- `<C-x>` / `<C-v>` / `<C-t>` — open in hsplit / vsplit / tab
- `<C-\>` — *custom:* vsplit (snacks picker mapping)
- `<M-v>` — *custom:* vsplit
- `<C-q>` — send all to quickfix; `<M-q>` selected to quickfix
- `<C-/>` — show keymap inside picker (insert) / `?` (normal)
- `<C-u>` / `<C-d>` — preview scroll up / down
- `<Tab>` / `<S-Tab>` — multi-select toggle

### 2.4 Emoji / file path
- `:Telescope emoji` — emoji picker
- `<Leader>fp` — copy relative file path
- `<Leader>fP` — copy absolute file path
- `<Leader>fn` — copy file name
- `<Leader>fh` — copy path relative to home

---

## 3. LSP / diagnostics / formatting

### 3.1 Buffer-local LSP (AstroNvim defaults)
- `K` — hover doc; `gd` — definition; `gD` — declaration
- `gr` — references; `gI` — implementation; `gy` — type definition
- `<Leader>la` — code action; `<Leader>lr` — rename
- `<Leader>lh` — toggle inlay hints
- `<Leader>lf` — format buffer (LSP); visual selection in visual mode
- `<Leader>lG` — toggle format on save (per-buffer / global)
- `<Leader>ls` — document symbols (snacks); `<Leader>lS` — symbols outline (aerial)
- `<Leader>lF` *(custom)* — search functions/methods (filtered telescope picker)
- `<Leader>lC` *(custom)* — search classes/structs (filtered telescope picker)
- `<Leader>ld` — line diagnostics; `[d` / `]d` — prev / next
- `<Leader>lD` — workspace diagnostics (snacks picker)
- `<Leader>li` — `:checkhealth vim.lsp`; `<Leader>lI` — `:NullLsInfo`

### 3.2 Custom LSP toggles (Python)
- `<Leader>lps` — strict mode (basedpyright)
- `<Leader>lpl` — lenient mode (pyright)
- `<Leader>lpr` — toggle pylsp (rope refactoring)
- `<Leader>lb` — buffer-only diagnostics picker
- `<Leader>lq` — buffer diagnostics → loclist
- `<Leader>uY` — toggle LSP semantic highlighting (buffer)

### 3.3 Inlay hint materialization (AbysmalBiscuit/insert-inlay-hints)
- `<Leader>ic` — insert closest inlay hint
- `<Leader>il` — insert all inlay hints on current line
- `<Leader>iv` *(visual)* — insert all inlay hints in selection
- `<Leader>ia` — insert all inlay hints in buffer
- Commands: `:InsertHints closest|line|visual|all`

### 3.4 Refactoring (ThePrimeagen/refactoring.nvim)
- `<Leader>re` *(v)* — Extract Function
- `<Leader>rE` *(v)* — Extract Function To File
- `<Leader>rv` *(v)* — Extract Variable
- `<Leader>ri` *(n/v)* — Inline Variable
- `<Leader>rI` — Inline Function
- `<Leader>rb` — Extract Block
- `<Leader>rB` — Extract Block To File
- `<Leader>rp` — Debug print (printf)
- `<Leader>rdv` *(n/v)* — Debug print variable
- `<Leader>rdc` — Debug print cleanup (remove all)
- `<Leader>rm` *(n/v)* — Telescope refactor menu *(moved from `rr` to avoid
  iron.nvim collision; iron uses `<Leader>rr` for REPL restart)*

### 3.5 Spectre (project-wide find/replace)
- `<Leader>H` — toggle Spectre UI
- `<Leader>Hw` — Spectre on word/selection under cursor
- Inside Spectre: `<CR>` open match; `dd` toggle replace; `<Leader>R` replace all;
  `<Leader>rc` replace current; `<Leader>q` send to quickfix

### 3.6 Conform / formatting
- Python: ruff_format on `<Leader>lF` (or format-on-save if enabled)
- `:ConformInfo` — show available formatters

---

## 4. Git

### 4.1 Gitsigns (in source buffers)
- `]c` / `[c` — next / prev hunk
- `<Leader>gh` (group): `s` stage hunk, `r` reset hunk, `S` stage buffer,
  `u` undo stage, `R` reset buffer, `p` preview hunk, `b` blame line,
  `d` diff, `D` diff against `~`
- *This config:* `Gitsigns change_base` is auto-applied to the
  merge-base with main/master, so hunks reflect the PR's diff (not the index)

### 4.2 Diffview
- `:DiffviewOpen [rev..rev]` — open diff
- `:DiffviewClose` `:DiffviewToggleFiles` `:DiffviewFocusFiles`
- `:DiffviewFileHistory %` — history of current file
- `:DiffviewFileHistory` — history of cwd
- *Custom:* `:DiffViewPR` — auto-detect PR base
- Inside: `<Tab>`/`<S-Tab>` next/prev file, `gf` open in tab, `<Leader>e`
  toggle file panel, `g<C-x>` cycle layout, `[x`/`]x` next/prev conflict

### 4.3 Neogit
- `:Neogit` — main UI; `:Neogit cwd=...` `:Neogit kind=split` etc.
- Inside: `s`/`u` stage/unstage, `c` commit menu, `P` push, `F` pull,
  `b` branch menu, `l` log, `Z` stash, `?` help

### 4.4 Git worktrees (ThePrimeagen/git-worktree)
- `<Leader>gw` — list worktrees
- `<Leader>gW` — create worktree
- Inside picker: `<CR>` switch, `<C-d>` delete, `<C-f>` toggle force

### 4.5 git-conflict.nvim
- `<Leader>gx` — list conflicts in quickfix
- Buffer (when in conflict): `co` ours, `ct` theirs, `cb` both, `c0` none,
  `]x` / `[x` next / prev conflict

### 4.6 gitlinker — copy permalinks
- `<Leader>gy` (n/v) — copy git permalink (uses `upstream` if set, else `origin`)
- `:GitLink` — same; `:GitLink!` — open in browser

### 4.7 gist-nvim
- `:Gist` etc. — see `:h gist-nvim`

### 4.8 Custom commit-message helpers
- `<Leader>gm` — scratch commit-message buffer (filetype gitcommit)
- `:CommitMsg` — same as above
- `:CommitMsg <PR#>` — seeded with PR title (via `gh pr view`)
- *committia.nvim:* nicer 3-pane commit editor with:
    - `<Leader>lf` (in gitcommit) — auto-format buffer to 50/72 rule
- Visual guides in gitcommit: colorcolumn at 50,72; textwidth toggles
  to 50 on line 1, 72 elsewhere

---

## 5. GitHub via Octo (LocalLeader = `,`)

### 5.1 Top-level pickers
- `<LocalLeader>oi` — list issues
- `<LocalLeader>op` — list PRs
- `<LocalLeader>od` — list discussions
- `<LocalLeader>on` — list notifications
- `<LocalLeader>os` — search GitHub (current repo scope)

### 5.2 Current-branch shortcuts (custom commands)
- `<LocalLeader>oe` — `:OctoPrEditCurrent` — edit PR for current branch
- `<LocalLeader>oc` — `:OctoPrChecksCurrent` — show PR checks for current branch
- `<LocalLeader>of` — jump from octo:// buffer to local file in **new tab**
- `<LocalLeader>oF` — same but **vsplit**
- `<LocalLeader>om` — toggle full-screen file view in PR review
- `<LocalLeader>ow` — toggle line wrap in both diff windows

### 5.3 Inside review / PR buffer
- `]c` / `[c` — next / prev review comment
- `]t` / `[t` — next / prev review thread
- `]q` / `[q` — next / prev file in review
- File panel: `j`/`k` navigate, `<CR>` select
- *This config patches `FileEntry.show_diff`* so diff mode reliably engages
  on both panes; right pane is also writable during review.

### 5.4 Octo CLI subcommands (`:Octo …`)
- `:Octo issue list|create|edit|close|reopen|browser`
- `:Octo pr list|create|checkout|edit|close|merge|ready|reload|browser|reviews|checks`
- `:Octo review start|submit|resume|comments`
- `:Octo comment add|edit|delete`
- `:Octo reaction +1|-1|eyes|heart|laugh|...`
- `:Octo label add|delete`, `:Octo assignee add|delete`
- `:Octo card move`, `:Octo gist list`, `:Octo search`

---

## 6. Motion / structure plugins

### 6.1 flash.nvim (community pack)
- `s{c1}{c2}` — jump to any 2-char location on screen
- `S` — same but treesitter-aware (jump to nodes)
- `r` *(operator-pending)* — remote operations (e.g. `yr` then jump+yank)
- `R` *(visual)* — extend visual treesitter selection
- `<C-s>` (in cmdline) — flash through search

### 6.2 vindent (indent motions / objects)
- `[-` / `]-` — prev / next line at same indentation
- `[=` / `]=` — prev / next line at less indentation
- `[p` / `]p` — start / end of current indent block
- `ii` / `ai` — text object: inner / around indent block

---

## 7. Tests / coverage / CI

### 7.1 Coverage (nvim-coverage)
- `<Leader>tc` — load coverage gutter
- `<Leader>tC` — hide coverage
- `<Leader>tT` — toggle coverage *(capital T to leave `<Leader>tt` for ToggleTerm)*
- `<Leader>ts` — coverage summary popup
- `<Leader>tL` — load coverage file *(capital L to leave `<Leader>tl` for lazygit)*

### 7.2 Neotest (community pack — `<Leader>T` capital, *not* `<Leader>t`)
- `<Leader>Tt` — run nearest test
- `<Leader>Tf` — run file tests
- `<Leader>Td` — debug nearest test
- `<Leader>Tp` — stop nearest test
- `<Leader>T<CR>` — show test output
- `<Leader>To` — open output panel; `<Leader>TO` — close output
- `<Leader>Tw` (watch group): `Twt` watch test, `Twf` watch file,
  `Twp` stop watching, `TwS` stop all watches
- `]T` / `[T` — next / prev failed test

### 7.3 Pipeline (CI status)
- `<Leader>a` — open pipeline.nvim (GitHub Actions / GitLab CI)

---

## 8. REPL (Iron.nvim, mostly Python/IPython)

- `<Leader>rs` — start (or toggle) REPL
- `<Leader>rr` — restart REPL
- `<Leader>rf` — send entire file
- `<Leader>rl` *(n)* — send current line
- `<Leader>rl` *(v)* — send selection
- `<Leader>rc{motion}` — send motion (e.g. `<Leader>rcip` send paragraph)
- `<Leader>rq` — close REPL
- REPL opens in vertical split (40% on right)

---

## 9. Markdown / writing

- `<Leader>mg` — Glow fullscreen preview in new tab
- `<Leader>uX` — colorize ANSI escape codes in current buffer (for log files)
- Commands: `:BaleiaColorize`, `:BaleiaLogs` (show baleia's own logger)

---

## 10. Window helpers

- `<Leader>Z` — toggle maximize current window (maximize.nvim)
- `<Leader>|` — vsplit with previous buffer

---

## 11. Custom user commands (this config)

- `:TabDir <path>` — open directory in new tab with its own `tcd`
- `:CommitMsg [PR#]` — scratch commit-message buffer (optionally seeded with PR title)
- `:DiffViewPR` — diffview against detected PR merge-base
- `:SaveFolds` / `:LoadFolds` — manual fold persistence (auto-runs already)
- `:OctoPrEditCurrent` — edit PR for current git branch
- `:OctoPrChecksCurrent` — show PR checks for current git branch
- `:BaleiaColorize` / `:BaleiaLogs`

---

## 12. Custom autocmd behaviors (silent, but worth knowing)

- **gitcommit buffers:** colorcolumn at 50,72; textwidth = 50 on subject line,
  72 in body; `<Leader>lf` formats whole buffer to 50/72.
- **Fold persistence:** mkview/loadview on every BufLeave/BufWinEnter etc.
  `viewoptions` excludes `curdir`, so views work across worktrees.
- **GitHub-style diff colors:** custom DiffAdd/Delete/Change/Text +
  Diffview equivalents are applied on every ColorScheme.
- **Octo winbar:** octo:// buffers get a filename winbar so they line up
  vertically with barbecue's right-side winbar.
- **Octo review patch:** `FileEntry.show_diff` rewritten to use
  `nvim_win_call` so diff mode engages reliably on both panes; right pane
  is made modifiable during review; long lines wrap with `smoothscroll`.
- **gitsigns base:** auto-set to `merge-base(main|master, HEAD)`, so hunks
  show the PR's diff against its base, not the working index.

---

## 13. Misc one-liners worth knowing

- `:!gh pr view --web` — open current PR in browser
- `:%y+` — yank entire buffer to system clipboard
- `:put =strftime('%Y-%m-%d')` — insert today's date
- `:g/pat/d` — delete every line matching pattern
- `:g!/pat/d` — delete every line NOT matching
- `:v/pat/d` — same as `:g!`
- `:sort` `:sort u` — sort range; `u` removes dups
- `:%retab` — convert tabs <-> spaces per `expandtab`
- `:set list!` — toggle whitespace markers
- `:windo {cmd}` / `:tabdo {cmd}` / `:bufdo {cmd}` — run on each
- `:argadd **/*.py | argdo %s/foo/bar/ge | update` — multi-file edit

-- In AstroNvim config
return {
  "jessekelighine/vindent.vim",
  lazy = false,
  init = function()
    -- Jump to next/prev line with same indentation
    vim.g.vindent_motion_OO_prev = "[-"
    vim.g.vindent_motion_OO_next = "]-"

    -- Jump to next/prev line with less indentation
    vim.g.vindent_motion_less_prev = "[="
    vim.g.vindent_motion_less_next = "]="

    -- Jump to start/end of current block scope
    vim.g.vindent_motion_XX_ss = "[p"
    vim.g.vindent_motion_XX_se = "]p"

    -- Text objects for selecting indent blocks
    vim.g.vindent_object_XX_ii = "ii"
    vim.g.vindent_object_XX_ai = "ai"
  end,
  config = function()
    -- Nice which-key labels: the keys above otherwise show as their raw <Plug>
    -- names (e.g. "VindentBlockMotion_XX_se"). Re-map to the same targets with a
    -- desc; remap=true so the <Plug> expands. These are the "select to where the
    -- indent ends" tools: ]p / [p jump (use with v or an operator, e.g. v]p or
    -- d]p), while ai / ii are the one-shot text objects (vai / vii).
    local function set(lhs, plug, desc, modes)
      vim.keymap.set(modes or { "n", "x", "o" }, lhs, plug, { remap = true, silent = true, desc = desc })
    end
    set("]p", "<Plug>(VindentBlockMotion_XX_se)", "Indent block: to end")
    set("[p", "<Plug>(VindentBlockMotion_XX_ss)", "Indent block: to start")
    set("ai", "<Plug>(VindentObject_XX_ai)", "Indent block (with boundary)", { "x", "o" })
    set("ii", "<Plug>(VindentObject_XX_ii)", "Indent block (inner)", { "x", "o" })
  end,
}

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
}

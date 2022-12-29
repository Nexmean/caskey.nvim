local internal = require("caskey.internal")
local utils = require("caskey.utils")

local M = vim.tbl_extend("error", utils,  {})

function M.setup(config)
  local global_conf = internal.empty_global_conf()
  internal.fill {
    wk = false,
    global_conf = global_conf,
    config = config,
  }
  for mode, acts in pairs(global_conf) do
    for lhs, act in pairs(acts) do
      internal.set_keymap(mode, lhs, act)
    end
  end
end

return M

local internal = require("caskey.internal")
local utils = require("caskey.utils")

local M = vim.tbl_extend("error", utils,  {})

function M.setup(config)
  local global_config = internal.empty_global_config()
  internal.fill {
    wk = false,
    global_config = global_config,
    config = config,
  }
  for mode, acts in pairs(global_config) do
    for lhs, act in pairs(acts) do
      internal.set_keymap(mode, lhs, act)
    end
  end
end

return M

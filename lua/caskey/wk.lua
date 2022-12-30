-- which-key integration
local internal = require("caskey.internal")
local utils = require("caskey.utils")

local M = vim.tbl_extend("force", utils, {})

function M.setup(config)
  local wk = require("which-key")
  local global_config = internal.empty_global_config()
  internal.fill {
    wk = true,
    global_config = global_config,
    config = config,
  }
  for mode, acts in pairs(global_config) do
    wk.register(acts, {mode = mode})
  end
end

return M

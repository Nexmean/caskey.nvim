-- which-key integration
local internal = require("caskey.internal")
local utils = require("caskey.utils")
local wk = require("which-key")

local M = vim.tbl_extend("force", utils, {})

function M.setup(config)
  local global_conf = internal.empty_global_conf()
  internal.fill {
    wk = true,
    global_conf = global_conf,
    config = config,
  }
  for mode, acts in pairs(global_conf) do
    wk.register(acts, {mode = mode})
  end
end

return M

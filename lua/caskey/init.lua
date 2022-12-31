local internal = require "caskey.internal"
local utils = require "caskey.utils"

local M = vim.tbl_extend("error", utils, {})

local function setup_config(config, add_opts)
  for mode, mappings in pairs(config.mappings) do
    for lhs, mapping in pairs(mappings) do
      vim.keymap.set(mode, lhs, mapping.rhs, vim.tbl_extend("error", mapping.opts, add_opts or {}))
    end
  end
end

function M.setup(root)
  local config = internal.mk_config(root)
  setup_config(config)
  internal.setup_autocommands(config.autocommands, setup_config)
end

return M

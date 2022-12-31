local lib = require "caskey.lib"
local internal = require "caskey.internal"
local utils = require "caskey.utils"

local M = vim.tbl_extend("keep", utils, {})

local function mk_wk_configs(config)
  local wk_configs = {}
  local all_modes =
    lib.nub(lib.concat { vim.tbl_keys(config.groups), vim.tbl_keys(config.mappings) })
  for _, mode in ipairs(all_modes) do
    local mode_config = { {}, { mode = mode } }
    for lhs, name in pairs(config.groups[mode] or {}) do
      mode_config[1][lhs] = { name = name }
    end

    for lhs, mapping in pairs(config.mappings[mode] or {}) do
      mode_config[1][lhs] = lib.coalesce { mode_config[1][lhs], {} }
      mode_config[1][lhs][1] = mapping.rhs
      mode_config[1][lhs][2] = mapping.opts.desc
      mode_config[1][lhs] = vim.tbl_extend("error", mode_config[1][lhs], mapping.opts)
    end

    table.insert(wk_configs, mode_config)
  end

  return wk_configs
end

local function patch_autocommands(config)
  for _, au in pairs(config.autocommands) do
    au.wk = mk_wk_configs(au)
  end
end

local function setup_config(config, add_opts)
  local wk = require "which-key"
  for _, wk_config in ipairs(config.wk) do
    wk.register(wk_config[1], vim.tbl_extend("error", wk_config[2], add_opts))
  end
end

function M.setup(root)
  local wk = require "which-key"
  local config = internal.mk_config(root)
  local wk_configs = mk_wk_configs(config)
  for _, wk_config in ipairs(wk_configs) do
    wk.register(wk_config[1], wk_config[2])
  end
  patch_autocommands(config)
  internal.setup_autocommands(config.autocommands, setup_config)
end

return M

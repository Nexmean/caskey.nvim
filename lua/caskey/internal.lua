local lib = require "caskey.lib"

local M = {}

---@class Node : Opts, { [integer]: Node }, { [string]: Node }, function(): Node
---@field act? Rhs
---@field name? string
---@field mode? Mode | Modes
---@field buf_local? When[]

---@class GlobalConfig : Config
---@field autocommands {AuKey: AuConfig}

---@class Config
---@field groups {Mode: {Lhs: string}}
---@field mappings {Mode: {Lhs: Mapping}}

---@class AuConfig : Config
---@field when When

---@class Mapping
---@field rhs string | function
---@field opts Opts

---@alias Modes string[]

---@class Opts
---@field desc? string
---@field expr? boolean
---@field noremap? boolean
---@field nowait? boolean
---@field silent? boolean
---@field unique? boolean
---@field buffer? integer

---@class When
---@field event string | string[]
---@field pattern? string | string[]
---@field group? string
---@field condition? function(event: any): boolean

---@alias NodesList Node[]
---@alias NodesMap {Lhs: Node}
---@alias AuKey string | When
---@alias Mode string
---@alias Lhs string
---@alias Rhs string | function | {string: function}

local function mk_empty_config()
  return {
    groups = {},
    mappings = {},
  }
end

local opt_keys = {
  "act",
  "buffer",
  "buf_local",
  "buf_local_extend",
  "desc",
  "expr",
  "mode",
  "mode_extend",
  "name",
  "noremap",
  "nowait",
  "silent",
  "unique",
}

---@param node any
---@param parent_modes? Modes
---@return Modes
local function mk_modes(node, parent_modes)
  return vim.tbl_flatten {
    lib.coalesce { node.mode, parent_modes, {} },
    lib.coalesce { node.mode_extend, {} },
  }
end

---@param node any
---@param parent_opts? Opts
---@return Opts
local function mk_opts(node, parent_opts)
  parent_opts = lib.coalesce { parent_opts, {} }
  return {
    desc = lib.coalesce { node.desc },
    expr = lib.coalesce { node.expr, parent_opts.expr, false },
    noremap = lib.coalesce { node.noremap, parent_opts.noremap, true },
    nowait = lib.coalesce { node.nowait, parent_opts.nowait, false },
    silent = lib.coalesce { node.silent, parent_opts.silent, true },
    unique = lib.coalesce { node.unique, parent_opts.unique },
    buffer = lib.coalesce { node.buffer, parent_opts.buffer },
  }
end

---@param node Node
---@param parent_buf_local? When[]
---@return When[]
local function mk_when(node, parent_buf_local)
  if node.buf_local == nil and node.buf_local_extend == nil then
    return parent_buf_local or {}
  end

  return lib.concat {
    lib.coalesce { node.buf_local, parent_buf_local, {} },
    lib.coalesce { node.buf_local_extend, {} },
  }
end

---@param trace Trace
---@param au When
---@return AuKey
local function mk_autocmd_key(trace, au)
  if au.condition ~= nil then
    return au
  end

  local key = ""
  if type(au.event) == "string" then
    key = au.event .. ";"
  elseif type(au.event) == "table" then
    table.sort(au.event)
    key = lib.intercalate(au.event, ",") .. ";"
  else
    lib.throw_error(
      lib.concat { trace, "buf_local", "event" },
      { "string", "table" },
      "value",
      au.event
    )
  end

  if type(au.pattern) == "string" then
    key = key .. au.pattern .. ";"
  elseif type(au.pattern) == "table" then
    table.sort(au.pattern)
    key = key .. lib.intercalate(au.pattern, ",") .. ";"
  elseif au.pattern == nil then
    key = key .. ";"
  else
    lib.throw_error(
      lib.concat { trace, "buf_local", "pattern" },
      { "string", "table", "nil" },
      "value",
      au.pattern
    )
  end

  if type(au.group) == "string" then
    key = key .. au.group
  elseif au.group == nil then
  else
    lib.throw_error(
      lib.concat { trace, "buf_local", "group" },
      { "string", "nil" },
      "value",
      au.event
    )
  end

  return key
end

---@param trace Trace
---@param config any
---@param lhs string
---@param modes Modes
---@param name? string
local function fill_groups(trace, config, lhs, modes, name)
  if name == nil then
    return
  end

  if type(name) == "string" then
    for _, mode in ipairs(modes) do
      config.groups[mode] = lib.coalesce { config.groups[mode], {} }
      config.groups[mode][lhs] = name
    end
  else
    lib.throw_error(lib.concat { trace, "name" }, { "string", "nil" }, "value", name)
  end
end

---@param trace Trace
---@param config Config
---@param lhs string
---@param rhs? Rhs
---@param modes Modes
---@param opts Opts
local function fill_mappings(trace, config, lhs, rhs, modes, opts)
  if rhs == nil then
    return
  end

  if lib.type_in(rhs, { "string", "function" }) then
    for _, mode in ipairs(modes) do
      config.mappings[mode] = lib.coalesce { config.mappings[mode], {} }
      config.mappings[mode][lhs] = {
        rhs = rhs,
        opts = opts,
      }
    end
  elseif type(rhs) == "table" then
    for mode, rhs_ in pairs(rhs) do
      if lib.type_in(rhs_, { "string", "function" }) then
        config.mappings[mode] = lib.coalesce { config.mappings[mode], {} }
        config.mappings[mode][lhs] = {
          rhs = rhs_,
          opts = opts,
        }
      else
        lib.throw_error(lib.concat { trace, "act", mode }, { "string", "function" }, "value", rhs)
      end
    end
  else
    lib.throw_error(lib.concat { trace, "act" }, { "string", "function", "table" }, "value", rhs)
  end
end

---@param trace Trace
---@param config GlobalConfig
---@param lhs string
---@param rhs Rhs
---@param modes Modes
---@param opts Opts
---@param when When[]
---@param name? string
local function fill_autocommands(trace, config, lhs, rhs, modes, opts, when, name)
  if when == nil or #when == 0 then
    return
  end

  for _, au in ipairs(when) do
    local key = mk_autocmd_key(trace, au)
    local au_config = config.autocommands[key] or mk_empty_config()
    config.autocommands[key] = au_config

    au_config.when = au
    fill_groups(trace, au_config, lhs, modes, name)
    fill_mappings(trace, au_config, lhs, rhs, modes, opts)
  end
end

---@param trace Trace
---@param config GlobalConfig
---@param node Node
---@param lhs? string
---@param parent_modes? Modes
---@param parent_opts? Opts
---@param parent_when? When[]
local function fill_config(trace, config, node, lhs, parent_modes, parent_opts, parent_when)
  local modes = mk_modes(node, parent_modes)
  local opts = mk_opts(node, parent_opts)
  local when = mk_when(node, parent_when)
  lhs = lhs or ""

  if #when == 0 then
    fill_groups(trace, config, lhs, modes, node.name)
    fill_mappings(trace, config, lhs, node.act, modes, opts)
  else
    fill_autocommands(trace, config, lhs, node.act, modes, opts, when, node.name)
  end

  for k, child in pairs(node) do
    if not vim.tbl_contains(opt_keys, k) then
      local new_lhs
      if type(k) == "string" then
        new_lhs = lhs .. k
      elseif type(k) == "number" then
        new_lhs = lhs
      else
        lib.throw_error(trace, { "number", "string" }, "config key", k)
      end

      if type(child) == "function" then
        child = child()
      elseif type(child) ~= "table" then
        lib.throw_error(lib.concat { trace, k }, { "table", "function" }, "config body", child)
      end

      fill_config(lib.concat { trace, k }, config, child, new_lhs, modes, opts, when)
    end
  end
end

---@param root Node
function M.mk_config(root)
  local config = mk_empty_config()
  config.autocommands = {}
  fill_config({ "root" }, config, root)
  return config
end

---@param autocommands {AuKey: AuConfig}
---@param setup_config function(au: AuConfig, opts: Opts)
function M.setup_autocommands(autocommands, setup_config)
  for _, au in pairs(autocommands) do
    local callback
    if au.when.condition == nil then
      callback = function(e)
        setup_config(au, { buffer = e.buf })
      end
    else
      callback = function(e)
        if au.when.condition(e) then
          setup_config(au, { buffer = e.buf })
        end
      end
    end

    vim.api.nvim_create_autocmd(au.when.event, {
      pattern = au.when.pattern,
      group = au.when.group,
      callback = callback,
    })
  end
end

return M

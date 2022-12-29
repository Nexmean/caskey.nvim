local M = {}

function M.set_keymap(mode, lhs, act, buf)
  vim.keymap.set(mode, lhs, act[1], vim.tbl_extend(
    "error",
    act.opts,
    {desc = act.desc, buffer = buf}
  ))
end

local opt_keys = {
  "act",
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

local function tbl_concat(t)
  local res = {}
  for _, tt in ipairs(t) do
    for _, v in ipairs(tt) do
      res[#res+1] = v
    end
  end

  return res
end

local function mk_modes(config, parent_modes)
  return vim.tbl_flatten {
    config.mode or parent_modes or {},
    config.mode_extend or {},
  }
end

local function mk_opts(config, parent_opts)
  return {
    expr = vim.F.if_nil(config.expr, parent_opts.expr),
    noremap = vim.F.if_nil(config.noremap, parent_opts.noremap),
    nowait = vim.F.if_nil(config.nowait, parent_opts.nowait),
    silent = vim.F.if_nil(config.silent, parent_opts.silent),
    unique = vim.F.if_nil(config.unique, parent_opts.unique)
  }
end

local function mk_buf_local(config, parent_buf_local)
  return tbl_concat {
    vim.F.if_nil(vim.F.if_nil(config.buf_local, parent_buf_local), {}),
    vim.F.if_nil(config.buf_local_extend, {}),
  }
end

local function mk_act(act, name, desc, opts, wk)
  if wk == true then
    return vim.tbl_extend("error", {act, desc, name = name}, opts)
  else
    return {act, desc = desc, name = name, opts = opts}
  end
end

local function mk_acts(act, name, desc, modes, opts, wk)
  if act == nil and (name == nil or not wk) then
    return {}
  end

  local acts = {}

  if type(act) == "table" then
    for mode, mode_act in pairs(act) do
      acts[mode] = mk_act(mode_act, name, desc, opts, wk)
    end
  else
    for _, mode in ipairs(modes) do
      acts[mode] = mk_act(act, name, desc, opts, wk)
    end
  end

  return acts
end

local function register_buf_locals(conf, acts, lhs)
  for _, buf_local in ipairs(conf) do
    vim.api.nvim_create_autocmd(buf_local.event, {
      pattern = buf_local.pattern,
      callback = function (e)
        local reqister_bindings = function ()
          for mode, act in pairs(acts) do
            M.set_keymap(mode, lhs, act, e.buf)
          end
        end
        if buf_local.condition ~= nil then
          if buf_local.condition(e) then
            reqister_bindings()
          end
        else
          reqister_bindings()
        end
      end
    })
  end
end

local function register_buf_locals_wk(conf, acts, lhs)
  local wk = require("which-key")
  for _, buf_local in ipairs(conf) do
    vim.api.nvim_create_autocmd(buf_local.event, {
      pattern = buf_local.pattern,
      callback = function (e)
        local reqister_bindings = function ()
          for mode, act in pairs(acts) do
            wk.register(
              { [lhs] = vim.tbl_extend("error", {buffer = e.buf}, act) },
              { mode = mode }
            )
          end
        end
        if buf_local.condition ~= nil then
          if buf_local.condition(e) then
            reqister_bindings()
          end
        else
          reqister_bindings()
        end
      end
    })
  end
end

-- fills normalized global keymaps config and sets autocommands for buf local keymaps
function M.fill(args)
  local wk = args.wk
  local global_conf = args.global_conf
  local config = args.config
  local parent_modes = args.parent_modes or {}
  local parent_opts = args.parent_opts or {}
  local parent_buf_local = args.parent_buf_local or {}
  local lhs = args.lhs or ""

  local modes = mk_modes(config, parent_modes)
  local opts = mk_opts(config, parent_opts)
  local buf_local = mk_buf_local(config, parent_buf_local)
  local acts = mk_acts(config.act, config.name, config.desc, modes, opts, wk)

  if #buf_local > 0 then
    if wk then
      register_buf_locals_wk(buf_local, acts, lhs)
    else
      register_buf_locals(buf_local, acts, lhs)
    end
  else
    for mode, act in pairs(acts) do
      global_conf[mode][lhs] = act
    end
  end

  for k, c in pairs(config) do
    if not vim.tbl_contains(opt_keys, k) then
      local new_lhs
      if type(k) == "string" then
        new_lhs = lhs .. k
      else
        new_lhs = lhs
      end
      M.fill {
        wk = wk,
        global_conf = global_conf,
        config = c,
        lhs = new_lhs,
        parent_modes = modes,
        parent_opts = opts,
        parent_buf_local = buf_local,
      }
    end
  end

  return global_conf
end

function M.empty_global_conf()
  return {
    n = {},
    v = {},
    s = {},
    x = {},
    o = {},
    i = {},
    l = {},
    c = {},
    t = {},
    ["!"] = {},
  }
end

return M

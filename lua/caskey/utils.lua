local M = {}

---wrap string in `<cmd>%s<CR>`
function M.cmd(command)
  return string.format("<cmd>%s<CR>", command)
end

---wrap string in function that call vim.cmd
function M.cmdfn(command)
  return function ()
    vim.cmd(command)
  end
end

--- setup mappings on FileType event
function M.filetype(filetypes)
  return { event = "FileType", pattern = filetypes }
end

--- setup mappings on FileType event
M.ft = M.filetype

--- setup mappings on BufWinEnter event and check buftype
function M.buftype(buftypes)
  local check_buftype
  if type(buftypes) == "string" then
    check_buftype = function()
      return vim.o.buftype == buftypes
    end
  else
    check_buftype = function()
      return vim.tbl_contains(buftypes, vim.o.buftype)
    end
  end

  return {
    event = "BufWinEnter",
    condition = check_buftype,
  }
end

--- setup mappings on BufWinEnter event and check buftype
M.bt = M.buftype

---useful for plugins that have on_attach function, but doesn't have event, for example gitsigns
---@param group string | integer - group name or id
---@param bufnr? integer - buffer number, if nil or 0 then current
function M.emit(group, bufnr)
  if bufnr == 0 or bufnr == nil then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if type(group) == "string" then
    vim.api.nvim_create_augroup(group, {clear = false})
  end
  vim.api.nvim_exec_autocmds("User", {
    pattern = "caskey.nvim",
    group = group,
    data = {
      buf = bufnr
    }
  })
end

---setup mappings on `ck.utils.emit` call
---@param group string | integer - group name or id
function M.emitted(group)
  if type(group) == "string" then
    vim.api.nvim_create_augroup(group, {clear = false})
  end
  return {
    event = "User",
    pattern = "caskey.nvim",
    group = group
  }
end

return M

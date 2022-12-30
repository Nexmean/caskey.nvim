local M = {}

function M.cmd(command)
  return string.format("<cmd>%s<CR>", command)
end

function M.filetype(filetypes)
  return {event = "FileType", pattern = filetypes}
end

M.ft = M.filetype

function M.buftype(buftypes)
  local check_buftype
  if type(buftypes) == "string" then
    check_buftype = function ()
      return vim.o.buftype == buftypes
    end
  else
    check_buftype = function ()
      return vim.tbl_contains(buftypes, vim.o.buftype)
    end
  end

  return {
    event = "BufWinEnter",
    condition = check_buftype
  }
end

M.bt = M.buftype

return M

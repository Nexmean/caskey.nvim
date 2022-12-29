local M = {}

function M.dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
       if type(k) ~= 'number' then k = '"'..k..'"' end
       s = s .. '['..k..'] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

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

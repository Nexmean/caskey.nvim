local M = {}

--- intercalate strings by separator
-- @param ss list of strings
-- @param sep separator
function M.intercalate(ss, sep)
  if #ss < 1 then
    return ""
  end

  local res = ss[1]

  local i = 2
  while i <= #ss do
    res = res .. sep .. ss[i]
    i = i + 1
  end

  return res
end

-- @param trace Path in config, list of strings and numbers
function M.format_trace(trace)
  return M.intercalate(
    vim.tbl_map(function(trace_chunk)
      if type(trace_chunk) == "string" then
        return string.format('[["%s"]]', trace_chunk)
      else
        return string.format("[[%s]]", tostring(trace_chunk))
      end
    end, trace),
    ""
  )
end

-- @param trace Path in config
-- @param[opt] trace_tail Formatted path for known properties
-- @param expected List of expected types
-- @param key_value Where got unexpected value, in table key or value
-- @param got Actual value
function M.throw_error(trace, expected, label, got)
  local got_string
  if type(got) == "string" then
    got_string = string.format('"%s"', got)
  elseif M.type_in(got, { "nil", "boolean", "number" }) then
    got_string = tostring(got)
  else
    got_string = type(got)
  end

  error(
    string.format(
      "Expected (%s) as %s %s, but got %s",
      M.intercalate(expected, "|"),
      M.format_trace(trace),
      label,
      got_string
    )
  )
end

--- like vim.tbl_flatten, but only for 1 nestings level
function M.concat(t)
  local res = {}
  for _, tt in ipairs(t) do
    if type(tt) == "table" then
      for _, v in ipairs(tt) do
        table.insert(res, v)
      end
    else
      table.insert(res, tt)
    end
  end

  return res
end

function M.type_in(v, types)
  return vim.tbl_contains(types, type(v))
end

--- returns copy of input table without duplicate
function M.nub(t)
  table.sort(t)
  local res = {}

  res[1] = t[1]
  local i = 2
  while i <= #t do
    if t[i] ~= res[#res] then
      table.insert(res, t[i])
    end
    i = i + 1
  end

  return res
end

--- returns first non nil value in a table
function M.coalesce(args)
  local i = 1
  while i <= #args do
    if args[i] ~= nil then
      return args[i]
    end
    i = i + 1
  end
end

return M


local xinerama = {}

function xinerama.info()
  local info = { heads = {}, head_count = 0 }
  local pats = {
    ['^%s+head #(%d+): (%d+)x(%d+) @ (%d+),(%d+)$'] = function(matches)
      info.heads[matches[1]] = { 
        resolution = { tonumber(matches[2]), tonumber(matches[3]) },
        offset = { tonumber(matches[4]), tonumber(matches[5]) }
      }
      info.head_count = info.head_count + 1
    end
  }
  local fp = io.popen('xdpyinfo -ext XINERAMA')
  for line in fp:lines() do
    for pat, func in pairs(pats) do
      local res 
      res = {line:find(pat)}
      if #res > 0 then
        table.remove(res, 1)
        table.remove(res, 1)
        func(res)
        break
      end
    end
  end
  return info
end

return xinerama

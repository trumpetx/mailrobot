function shuffle(list)
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

function keys(tb)
  local ks = {}
  for k in pairs(tb) do table.insert(ks, k) end
  return ks
end

function sortedKeys(tb, sortFunction)
  local sorted = keys(tb)
  table.sort(sorted, sortFunction)
  return sorted
end

function getKeysSortedByValue(tbl, sortFunction)
  local keys = keys(tbl)
  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)
  return keys
end

do
  local strformat = string.format
  function string.format(format, ...)
    local args = {...}
    local match_no = 1
    for pos, type in string.gmatch(format, "()%%.-(%a)") do
      if type == 't' then
        args[match_no] = tostring(args[match_no])
      end
      match_no = match_no + 1
    end
    return strformat(string.gsub(format, '%%t', '%%s'),
      unpack(args,1,select('#',...)))
  end
end

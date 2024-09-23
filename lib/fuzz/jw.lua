-- https://en.wikipedia.org/wiki/Jaro-Winkler_distance

local function jaro_distance(s1, s2)
    local len_s1 = #s1
    local len_s2 = #s2

    if len_s1 == 0 and len_s2 == 0 then
        return 1
    end

    local match_distance = math.floor(math.max(len_s1, len_s2) / 2) - 1
    local s1_matches = {}
    local s2_matches = {}
    
    -- Find matches
    local matches = 0
    for i = 1, len_s1 do
        local start = math.max(1, i - match_distance)
        local stop = math.min(i + match_distance, len_s2)

        for j = start, stop do
            if not s2_matches[j] and s1:sub(i, i) == s2:sub(j, j) then
                s1_matches[i] = true
                s2_matches[j] = true
                matches = matches + 1
                break
            end
        end
    end

    if matches == 0 then
        return 0
    end

    -- Find transpositions
    local t = 0
    local point = 1
    for i = 1, len_s1 do
        if s1_matches[i] then
            while not s2_matches[point] do
                point = point + 1
            end
            if s1:sub(i, i) ~= s2:sub(point, point) then
                t = t + 1
            end
            point = point + 1
        end
    end

    t = t / 2

    -- Jaro distance formula
    return (matches / len_s1 + matches / len_s2 + (matches - t) / matches) / 3
end

-- Jaro-Winkler Distance calculation
local function jaro_winkler_distance(s1, s2, p)
    p = p or 0.1 -- Default scaling factor for the prefix is 0.1
    local jaro_dist = jaro_distance(s1, s2)

    -- Find the length of common prefix
    local prefix_length = 0
    local max_prefix = 4  -- Standard maximum prefix length considered in Jaro-Winkler
    for i = 1, math.min(max_prefix, #s1, #s2) do
        if s1:sub(i, i) == s2:sub(i, i) then
            prefix_length = prefix_length + 1
        else
            break
        end
    end

    -- Jaro-Winkler distance formula
    return jaro_dist + (prefix_length * p * (1 - jaro_dist))
end

return function(query, items)
    local filtered = {}
    for _, item in pairs(items) do
      local dist = jaro_winkler_distance(query, item)
      print("Jaro-Winkler", query, "/", item, dist)
      if dist < 0.5 then table.insert(filtered, item) end
    end

    table.sort(filtered, function(a, b)
      local dista = jaro_winkler_distance(query, a)
      local distb = jaro_winkler_distance(query, b)
      return dista > distb
    end)

    return filtered
end
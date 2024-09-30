local fzy = require("lib/fuzz/fzy").filter
local jw = require("lib/fuzz/jw").filter

ItemUI = {Enabled = true}
ImGui = ImGui or {}

local count = 1
local filter = ""
local algorithm = 0
local hasMatches = true
local filteredItems = {}
local filteredTypes = {}
local filteredIkeys = {}
local filteredTkeys = {}
local filterQuality = 0

local algorithms = {"string.find", "fzy"}

local Colors = {["Random"] = {127, 132, 156}, ["Uncommon"] = {166, 227, 161}, ["Rare"] = {137, 180, 250}, ["Epic"] = {203, 166, 247}, ["Legendary"] = {250, 179, 135}}
local qualities = {"All", "Random", "Common", "Common+", "Uncommon", "Uncommon+", "Rare", "Rare+", "Epic", "Epic+", "Legendary", "Legendary+", "Legendary++"}

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

local function RGBtoPackedABGR(color)
  local a = color[4] or 255
  local b = color[3]
  local g = color[2]
  local r = color[1]
  return bit32.bor(bit32.lshift(a, 24), bit32.lshift(b, 16), bit32.lshift(g, 8), r)
end

local function getHoverColor(color)
  local newColor = copy(color)
  newColor[4] = 192
  return newColor
end

local function getActiveColor(color)
  local newColor = copy(color)
  newColor[4] = 128
  return newColor
end

local function indexof(array, value)
  for i, v in ipairs(array) do if v == value then return i end end
  return nil
end

function ItemUI:Filter()
  local filtered = {}
  hasMatches = false
  for cat, items in pairs(SimpleUtils.Dumper.Items) do
    local currentItems = {}
    for name, item in pairs(items) do if filterQuality == 0 or name:match("^.*##" .. qualities[filterQuality + 1]:gsub("+", "Plus") .. "$") then currentItems[name] = item end end

    local keys = {}
    for k, _ in pairs(currentItems) do table.insert(keys, k) end

    local types = {}
    local tkeys = {}
    local ikeys = {}
    local function postprocess(name, id)
      local record = SimpleUtils.Dumper.Records[id]
      local type = ""
      if record:ItemType() then type = Game.GetLocalizedTextByKey(record:ItemType():LocalizedType()) end

      if type == "" then type = cat end
      if filter ~= "" then type = "Search Results" end
      types[type] = types[type] or {}
      types[type][name] = id
    end

    if algorithm ~= 0 then
      local fuzzed = (algorithm == 1 and fzy or jw)(filter, keys)

      for _, name in ipairs(fuzzed) do
        hasMatches = true
        filtered[cat] = filtered[cat] or {}
        if algorithm == 1 then name = keys[name[1]] end
        filtered[cat][name] = currentItems[name]

        postprocess(name, currentItems[name])
      end
    else
      for _, name in pairs(keys) do
        if string.find(name:lower(), filter:lower(), 0, true) then
          hasMatches = true
          filtered[cat] = filtered[cat] or {}
          filtered[cat][name] = currentItems[name]

          postprocess(name, currentItems[name])
        end
      end
    end

    for k in pairs(types) do table.insert(tkeys, k) end

    table.sort(tkeys)

    for _, type in ipairs(tkeys) do
      local itms = types[type]
      ikeys[type] = ikeys[type] or {}
      for k in pairs(itms) do table.insert(ikeys[type], k) end
      table.sort(ikeys[type], function(a, b)
        local q = {}
        for k, v in pairs(qualities) do q[v] = k end
        local an = a:gsub("(.*)##.*", "%1")
        local bn = b:gsub("(.*)##.*", "%1")

        local aq = a:gsub(".*##(.*)", "%1"):gsub("Plus", "+")
        local bq = b:gsub(".*##(.*)", "%1"):gsub("Plus", "+")

        if an:lower() ~= bn:lower() then return an:lower() < bn:lower() end

        local qa, qb = q[aq], q[bq]
        if qa and qb then
          return qa < qb
        else
          return an:lower() < bn:lower() -- fallback to standard string comparison
        end
      end)
    end

    filteredTypes[cat] = types
    filteredTkeys[cat] = tkeys
    filteredIkeys[cat] = ikeys
  end

  filteredItems = filtered
end

function ItemUI:DrawGUI()
  if not ItemUI.Enabled then return end

  ImGui.SetWindowSize(720, 480)

  ImGui.Text("Count")
  ImGui.SameLine()
  ImGui.SetNextItemWidth(127)
  count = ImGui.InputInt("##Count", count, 1, 10)
  count = math.max(count, 1)

  ImGui.SameLine(ImGui.GetWindowWidth() - 315)

  ImGui.Text("Filter")
  ImGui.SameLine(ImGui.GetWindowWidth() - (255 + 5 + 20))
  ImGui.SetNextItemWidth(128)
  local newFilter = ImGui.InputText("##Filter", filter, 128)
  if newFilter ~= filter then
    filter = newFilter

    self:Filter()
  end

  ImGui.SameLine(ImGui.GetWindowWidth() - (128 + 20))
  ImGui.SetNextItemWidth(128)
  local newQuality = ImGui.Combo("##Quality", filterQuality, qualities, #qualities)
  if newQuality ~= filterQuality then
    filterQuality = newQuality

    self:Filter()
  end

  ImGui.Text("Note: Some items cannot easily be removed once added.")
  ImGui.SameLine(ImGui.GetWindowWidth() - 315)
  ImGui.Text("Algorithm")
  ImGui.SameLine(ImGui.GetWindowWidth() - 148)
  ImGui.SetNextItemWidth(128)
  local newAlgorithm = ImGui.Combo("##Algorithm", algorithm, algorithms, #algorithms)
  if newAlgorithm ~= algorithm then
    algorithm = newAlgorithm

    self:Filter()
  end

  ImGui.Spacing()
  ImGui.Separator()
  ImGui.Spacing()

  if not hasMatches then
    ImGui.Text("No matches found for \"" .. filter .. "\"\nPlease try another query.")
  else
    if ImGui.BeginTabBar('Tabs') then
      for cat, _ in pairs(filteredItems) do
        local types = filteredTypes[cat]
        local tkeys = filteredTkeys[cat]
        local ikeys = filteredIkeys[cat]

        if ImGui.BeginTabItem(cat) then
          for _, type in ipairs(tkeys) do
            if ImGui.CollapsingHeader(type) then
              for _, name in ipairs(ikeys[type]) do
                local id = types[type][name]

                local quality = name:gsub(".*##(.*)", "%1"):gsub("Plus", "")
                local color = Colors[quality]
                if color == nil then color = Colors.Random end
                local hoverColor = getHoverColor(color)
                local activeColor = getActiveColor(color)

                ImGui.PushStyleColor(ImGuiCol.Button, RGBtoPackedABGR(color))
                ImGui.PushStyleColor(ImGuiCol.ButtonHovered, RGBtoPackedABGR(hoverColor))
                ImGui.PushStyleColor(ImGuiCol.ButtonActive, RGBtoPackedABGR(activeColor))
                ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({17, 17, 27}))

                if ImGui.Button(name) then
                  Game.AddToInventory(id, count)
                  SimpleUtils.Logger:Log("ItemUI", "Added " .. count .. " of " .. id)
                end

                ImGui.PopStyleColor(4)

                if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
                  local record = SimpleUtils.Dumper.Records[id]

                  ImGui.PushStyleColor(ImGuiCol.Border, RGBtoPackedABGR(color))
                  ImGui.BeginTooltip()

                  ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({52, 152, 219}))
                  ImGui.Text(name:gsub("%s+(.*)%s+##.*", "%1"))
                  ImGui.PopStyleColor()

                  ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({231, 76, 60}))
                  ImGui.Text(type)
                  ImGui.PopStyleColor()

                  local locDesc = Game.GetLocalizedTextByKey(record:LocalizedDescription())
                  if locDesc ~= nil and locDesc ~= "" then
                    ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({255, 255, 255}))

                    ImGui.PushTextWrapPos(500)
                    ImGui.Text(locDesc)
                    ImGui.PopTextWrapPos()

                    ImGui.PopStyleColor()
                  end

                  ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR(color))
                  ImGui.Text(name:gsub(".*##(.*)", "%1"):gsub("Plus", "+"))
                  ImGui.PopStyleColor()

                  ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({255, 255, 255, 64}))
                  ImGui.Text(id)
                  ImGui.PopStyleColor()

                  ImGui.PopStyleColor()
                  ImGui.EndTooltip()
                end
              end
            end
          end
          ImGui.EndTabItem()
        end
      end

      ImGui.EndTabBar()
    end
  end
end

return ItemUI

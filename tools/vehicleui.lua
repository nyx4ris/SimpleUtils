local fzy = require("lib/fuzz/fzy").has_match
local jw = require("lib/fuzz/jw").match

VehicleUI = {Enabled = true}
ImGui = ImGui or {}

local filter = ""
local algorithm = 0
local hasMatches = true
local filteredvehicles = {}

local hideQuest = true
local hideUntranslated = true

local algorithms = {"string.find", "fzy"}

local function RGBtoPackedABGR(color)
  local a = color[4] or 255
  local b = color[3]
  local g = color[2]
  local r = color[1]
  return bit32.bor(bit32.lshift(a, 24), bit32.lshift(b, 16), bit32.lshift(g, 8), r)
end

local enabled = {}
local models = {}
function VehicleUI:Filter()
  local vs = Game.GetVehicleSystem()

  local filtered = {}
  hasMatches = false

  for k, v in pairs(vs:GetPlayerVehicles()) do
    local name = SimpleUtils.Dumper.Vehicles[v.recordID.value] or v.recordID.value
    local displayName = name:gsub("Vehicle.", "Untranslated: ")

    models[name] = v.name.value
    if displayName ~= name and hideUntranslated then goto continue end
    if v.recordID.value:match("Vehicle.q.*") and hideQuest then goto continue end

    if algorithm ~= 0 then
      if (algorithm == 1 and fzy or jw)(filter, displayName) then
        hasMatches = true
        filtered[name] = v.recordID.value
      end
    else
      if string.find(displayName:lower(), filter:lower(), 0, true) then
        hasMatches = true
        filtered[name] = v.recordID.value
      end
    end

    enabled[v.recordID.value] = v.isUnlocked
    ::continue::
  end

  filteredvehicles = filtered
end

function VehicleUI:DrawGUI()
  if not VehicleUI.Enabled then return end

  local vs = Game.GetVehicleSystem()

  ImGui.SetNextItemWidth(ImGui.GetWindowWidth() - (128 + 48))
  local newFilter = ImGui.InputText("##Filter", filter, 128)
  if newFilter ~= filter then
    filter = newFilter
    self:Filter()
  end
  if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
    ImGui.SetTooltip("Filter")
  end

  ImGui.SameLine(ImGui.GetWindowWidth() - (128 + 32))
  ImGui.SetNextItemWidth(128)
  local newAlgorithm = ImGui.Combo("##Algorithm", algorithm, algorithms, #algorithms)
  if newAlgorithm ~= algorithm then
    algorithm = newAlgorithm
    self:Filter()
  end
  if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
    ImGui.SetTooltip("Filter Algorithm")
  end

  local pressed = false
  hideUntranslated, pressed = ImGui.Checkbox("Hide untranslated", hideUntranslated)
  if pressed then
    self:Filter()
  end
  if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
    ImGui.SetTooltip("Untranslated vehicles are usually not meant to be driven.")
  end

  ImGui.SameLine()
  pressed = false
  hideQuest, pressed = ImGui.Checkbox("Hide quest vehicles", hideQuest)
  if pressed then
    self:Filter()
  end

  ImGui.Spacing()
  ImGui.Separator()
  ImGui.Spacing()

  if not hasMatches then
    ImGui.Text("No matches found for \"" .. filter .. "\"\nPlease try another query.")
  else
    for vehicle, id in pairs(filteredvehicles) do
      local name = SimpleUtils.Dumper.Vehicles[id] or id
      local displayName = name:gsub("Vehicle.", "Untranslated: ")
      local record = SimpleUtils.Dumper.Records[id]

      local newState, pressed = ImGui.Checkbox(displayName, enabled[id] or false)
      if pressed then
        vs:EnablePlayerVehicle(id, newState, false)
        SimpleUtils.Logger:Log("VehicleUI", (newState and "En" or "Dis") .. "abled " .. id)
        enabled[id] = newState
      end

      if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
        local type = "Unknown"
        local manufacturer = record:Manufacturer()
        if manufacturer ~= nil then type = manufacturer:EnumName() end

        ImGui.BeginTooltip()

        ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({52, 152, 219}))
        ImGui.Text(displayName)
        ImGui.PopStyleColor()

        ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({231, 76, 60}))
        ImGui.Text(type .. " " .. models[name])
        ImGui.PopStyleColor()

        ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({255, 255, 255, 64}))
        ImGui.Text(id)
        ImGui.PopStyleColor()

        ImGui.EndTooltip()
      end
      ::continue::
    end
  end
end

function VehicleUI:OnInit()
end

return VehicleUI

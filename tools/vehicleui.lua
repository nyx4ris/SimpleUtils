local fzy = require("lib/fuzz/fzy").has_match
local jw = require("lib/fuzz/jw").match

VehicleUI = {Enabled = true}
ImGui = ImGui or {}

local filter = ""
local algorithm = 0
local hasMatches = true
local filteredvehicles = {}

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
  hasMatches = true

  for k, v in pairs(vs:GetPlayerVehicles()) do
    local name = SimpleUtils.Dumper.Vehicles[v.recordID.value]
    models[name] = v.name.value
    if algorithm ~= 0 then
      if (algorithm == 1 and fzy or jw)(filter, name) then
        hasMatches = true
        filtered[name] = v.recordID.value
      end
    else
      if string.find(name:lower(), filter:lower(), 0, true) then
        hasMatches = true
        filtered[name] = v.recordID.value
      end
    end

    enabled[v.recordID.value] = v.isUnlocked
  end

  filteredvehicles = filtered
end

function VehicleUI:DrawGUI()
  if not VehicleUI.Enabled then return end

  local vs = Game.GetVehicleSystem()

  ImGui.SetWindowSize(720, 480)

  ImGui.Text("Filter")
  ImGui.SameLine()
  ImGui.SetNextItemWidth(128 + 256)
  local newFilter = ImGui.InputText("##Filter", filter, 128)
  if newFilter ~= filter then
    filter = newFilter

    self:Filter()
  end

  ImGui.SameLine(ImGui.GetWindowWidth() - 215)
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
    for vehicle, id in pairs(filteredvehicles) do
      -- if not id:match(".*_player") then goto continue end

      local name = SimpleUtils.Dumper.Vehicles[id]
      local record = SimpleUtils.Dumper.Records[id]

      local newState, pressed = ImGui.Checkbox(name, enabled[id] or false)
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
        ImGui.Text(name)
        ImGui.PopStyleColor()

        ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({231, 76, 60}))
        ImGui.Text(type .. " " .. models[name])
        ImGui.PopStyleColor()

        ImGui.PushStyleColor(ImGuiCol.Text, RGBtoPackedABGR({255, 255, 255, 64}))
        ImGui.Text(id)
        ImGui.PopStyleColor()

        ImGui.EndTooltip()
      end
      -- ::continue::
    end
  end
end

return VehicleUI

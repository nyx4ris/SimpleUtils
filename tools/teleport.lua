local fzy = require("lib/fuzz/fzy").filter
local dl = require("lib/fuzz/dl")
local jw = require("lib/fuzz/jw")
local json = require("lib/json")

Teleporter = {Enabled = true, Waypoints = {}}
ImGui = ImGui or {}

local name = ""

function Teleporter:AddWaypoint(title, coords, angle)
  table.insert(Teleporter.Waypoints, {
    ["name"] = title,
    ["coords"] = { coords.x, coords.y, coords.z },
    ["angle"] = { angle.roll, angle.pitch, angle.yaw }
  })
end

function Teleporter:DrawGUI()
  if not Teleporter.Enabled then return end

  ImGui.SetWindowSize(330, 480)

  ImGui.SetNextItemWidth(213)
  name = ImGui.InputText("##Name", name, 128)
  ImGui.SameLine()
  if ImGui.Button("Add Waypoint") then
    local plyObj = Game.GetPlayerObject()
    Teleporter:AddWaypoint(name, plyObj:GetWorldPosition(), plyObj:GetWorldOrientation():ToEulerAngles())
    name = ""
  end

  ImGui.Spacing()
  ImGui.Separator()
  ImGui.Spacing()

  for k, v in pairs(Teleporter.Waypoints) do
    if ImGui.Button(v.name .. "##" .. k) then
      local x, y, z = unpack(v.coords)
      local roll, pitch, yaw = unpack(v.angle)
      Game.GetTeleportationFacility():Teleport(GetPlayer(), ToVector4 {x = x, y = y, z = z, w = 0}, ToEulerAngles {roll = roll, pitch = pitch, yaw = yaw})
    end
  end
end

return Teleporter
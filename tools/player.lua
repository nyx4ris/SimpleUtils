local fzy = require("lib/fuzz/fzy").filter
local dl = require("lib/fuzz/dl")
local jw = require("lib/fuzz/jw")
local json = require("lib/json")

Player = {Enabled = true}
ImGui = ImGui or {}

local recoverySpeed = 1
local quickhackCost = 1
local quickhackSpeed = 1

function Player:DrawGUI()
  if not Player.Enabled then return end

  ImGui.SetWindowSize(330, 480)

  if ImGui.BeginTabBar("Tabs") then
    ImGui.Text("NONE OF THESE DO ANYTHING YET")
    if ImGui.BeginTabItem(IconGlyphs.IntegratedCircuitChip .. " Quick hacks") then
      ImGui.Spacing()
      local used = false
      recoverySpeed, used = ImGui.SliderFloat("Recovery rate", recoverySpeed, 1, 10, "%.1fx", ImGuiSliderFlags.Logarithmic)
      quickhackCost, used = ImGui.SliderFloat("Cost Multiplier", quickhackCost, 0.001, 1, "%.3fx", ImGuiSliderFlags.Logarithmic)
      quickhackSpeed, used = ImGui.SliderFloat("Upload Speed", quickhackSpeed, 0.001, 1, "%.3fx", ImGuiSliderFlags.Logarithmic)

      ImGui.EndTabItem()
    end

    ImGui.EndTabBar()
  end
end

return Player

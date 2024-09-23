local inspect = require("lib/inspect")
SimpleUtils = {}

SimpleUtils.ItemUI = require("tools/itemui")
SimpleUtils.Dumper = require("tools/dumper")
SimpleUtils.Cheats = require("tools/cheats")
SimpleUtils.Teleporter = require("tools/teleport")

local isOverlayVisible = false

SimpleUtils.Logger = {}

function SimpleUtils.Logger:Log(module, ...) print("[SimpleUtils::" .. module .. "] " .. tostring(...)) end

local flags = ImGuiWindowFlags.AlwaysAutoResize

SimpleUtils.FPS = 0

function SimpleUtils:UpdateFPS(delta)
  SimpleUtils.FPS = 1/delta
end

function SimpleUtils:Render()
  local infoFlags = ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoMove
  if not isOverlayVisible then infoFlags = infoFlags + ImGuiWindowFlags.NoBackground end

  ImGui.SetNextWindowPos(0, 0)
  if ImGui.Begin('Player Info', infoFlags) then
    ImGui.Text("FPS: " .. tostring(math.floor(SimpleUtils.FPS)))
    ImGui.Text("Position: " .. Game.GetPlayerObject():GetWorldPosition():ToString())

    ImGui.End()
  end

  if isOverlayVisible and ImGui.Begin(IconGlyphs.Cog .. ' Simple Utils', flags) then
    if Game.GetPlayer() == nil then
      ImGui.Text("Player is not initialized yet.\nPlease wait...")

      ImGui.End()
      return
    end
    if ImGui.BeginTabBar("Tabs") then
      if ImGui.BeginTabItem(IconGlyphs.Console .. " Cheats") then
        flags = ImGuiWindowFlags.AlwaysAutoResize

        if ImGui.BeginTabBar("Cheat Tabs") then
          if ImGui.BeginTabItem("Impulse") then
            for k, v in pairs(SimpleUtils.Cheats.Buttons) do if ImGui.Button(v.name) then v.callback() end end

            ImGui.EndTabItem()
          end

          if ImGui.BeginTabItem("Toggles") then
            for k, v in pairs(SimpleUtils.Cheats.Checkboxes) do
              local enabled = SimpleUtils.Cheats.Checkboxes[k].enabled
              enabled = ImGui.Checkbox(v.name, enabled)
              SimpleUtils.Cheats.Checkboxes[k].enabled = enabled
            end

            ImGui.EndTabItem()
          end

          ImGui.EndTabBar()
        end

        ImGui.EndTabItem()
      else
        flags = ImGuiWindowFlags.NoResize
      end

      if ImGui.BeginTabItem(IconGlyphs.StorageTank .. " Items") then
        SimpleUtils.ItemUI:DrawGUI()

        ImGui.EndTabItem()
      end

      if ImGui.BeginTabItem(IconGlyphs.PlaneTrain .. " Teleporter") then
        SimpleUtils.Teleporter:DrawGUI()

        ImGui.EndTabItem()
      end

      ImGui.EndTabBar()
    end

    ImGui.End()
  end
end

registerForEvent('onDraw', function() SimpleUtils:Render() end)
registerForEvent('onOverlayOpen', function() isOverlayVisible = true end)
registerForEvent('onOverlayClose', function() isOverlayVisible = false end)
registerForEvent('onUpdate', function(delta) SimpleUtils:UpdateFPS(delta) end)

SimpleUtils.Logger:Log("Core", "Loaded!")

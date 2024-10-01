local inspect = require("lib/inspect")

SimpleUtils = SimpleUtils or {}

require("info")

SimpleUtils.ItemUI = require("tools/itemui")
SimpleUtils.VehicleUI = require("tools/vehicleui")
SimpleUtils.Dumper = require("tools/dumper")
SimpleUtils.Teleporter = require("tools/teleport")
SimpleUtils.Player = require("tools/player")
SimpleUtils.Debug = (build == "{commit}")

local isOverlayVisible = false

SimpleUtils.Logger = {}

function SimpleUtils.Logger:Log(module, ...) print("[SimpleUtils::" .. module .. "] " .. tostring(...)) end

-- local flags = ImGuiWindowFlags.AlwaysAutoResize

SimpleUtils.FPS = 0

function SimpleUtils:UpdateFPS(delta) SimpleUtils.FPS = 1 / delta end

function SimpleUtils:Tab(icon, name, callback)
  if ImGui.BeginTabItem(icon) then
    ImGui.Spacing()
    callback()

    ImGui.EndTabItem()
  end
end

function SimpleUtils:Render()
  local infoFlags = ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoMove
  if not isOverlayVisible then infoFlags = infoFlags + ImGuiWindowFlags.NoBackground end

  if (SimpleUtils.Debug or isOverlayVisible) and ImGui.Begin('Debug Info', infoFlags) then
    ImGui.SetWindowPos(0, 0)

    if SimpleUtils.Debug then
      local ply = Game.GetPlayerObject()

      if not isOverlayVisible then
        ImGui.Text("FPS: " .. tostring(math.floor(SimpleUtils.FPS)))
        if ply then ImGui.Text("Position: " .. ply:GetWorldPosition():ToString()) end
      elseif ImGui.BeginTabBar("Tabs") then
        if ImGui.BeginTabItem("Game") then
          ImGui.Text("FPS: " .. tostring(math.floor(SimpleUtils.FPS)))
          if ply then ImGui.Text("Position: " .. ply:GetWorldPosition():ToString()) end

          ImGui.EndTabItem()
        end

        if ImGui.BeginTabItem("SimpleUI") then
          ImGui.Text(inspect(SimpleUtils))

          ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
      end
    end

    if isOverlayVisible then SimpleUtils.Debug = ImGui.Checkbox("Show debug info", SimpleUtils.Debug) end

    ImGui.End()
  end

  if isOverlayVisible and ImGui.Begin(IconGlyphs.Cog .. ' Simple Utils', ImGuiWindowFlags.NoResize) then
    if ImGui.IsWindowCollapsed() then
      ImGui.End()
      return
    end
    if Game.GetPlayer() == nil then
      ImGui.SetWindowSize(175, 77)
      ImGui.Text("Player is not initialized yet.\nPlease wait...")

      ImGui.End()
      return
    end

    if ImGui.BeginTabBar("Tabs") then
      self:Tab(IconGlyphs.Account, " Player", function() SimpleUtils.Player:DrawGUI() end)
      self:Tab(IconGlyphs.StorageTank, " Items", function() SimpleUtils.ItemUI:DrawGUI() end)
      self:Tab(IconGlyphs.Car, " Vehicles", function() SimpleUtils.VehicleUI:DrawGUI() end)
      self:Tab(IconGlyphs.MapMarker, " Teleporter", function() SimpleUtils.Teleporter:DrawGUI() end)
      self:Tab(IconGlyphs.Information, " About", function()
        ImGui.SetWindowSize(175, 112)

        ImGui.Text("SimpleUtils by Nyx")
        ImGui.Text("Build: " .. (build == "{commit}" and "dev" or build))
      end)

      ImGui.EndTabBar()
    end

    ImGui.End()
  end
end

registerForEvent('onDraw', function() SimpleUtils:Render() end)
registerForEvent('onOverlayOpen', function() isOverlayVisible = true end)
registerForEvent('onOverlayClose', function() isOverlayVisible = false end)
registerForEvent('onUpdate', function(delta)
  SimpleUtils:UpdateFPS(delta)
  SimpleUtils.Dumper:OnUpdate()
  SimpleUtils.Player:Process()
end)
registerForEvent('onInit', function()
  SimpleUtils.Dumper:OnInit()
  SimpleUtils.Player:OnInit()
  SimpleUtils.VehicleUI:OnInit()
end)

SimpleUtils.Logger:Log("Core", "Loaded!")

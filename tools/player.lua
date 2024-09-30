require("lib/vehicle")

Player = {Enabled = true}
ImGui = ImGui or {}

local infiniteAmmo = false
local noReload = false

local vehicleGodMode = false
local infiniteVehicleAmmo = false

local clearTraffic = true
local useKinematic = true
local minDist = 0
local minSpeed = 15
local maxSpeed = 30

local recoverySpeed = 1
local quickhackCost = 1
local quickhackSpeed = 1
local customMappin

local godMode = false

local function getWeaponAndAmmo()
  local player = Game.GetPlayer()
  local transactionSystem = Game.GetTransactionSystem()
  local weapon = transactionSystem:GetItemInSlot(player, TweakDBID.new('AttachmentSlots.WeaponRight'))
  if weapon == nil then return nil end
  local gotAmmoType, ammoType = pcall(function() return WeaponObject.GetAmmoType(weapon:GetItemID()) end)

  local equipmentSystem = Game.GetScriptableSystemsContainer():Get('EquipmentSystem')
  local equipmentSystemPlayerData = equipmentSystem:GetPlayerData(player)
  local inventoryDataManager = equipmentSystemPlayerData:GetInventoryManager()

  local data = inventoryDataManager:GetItemDataFromIDInLoadout(weapon:GetItemID())

  return gotAmmoType, ammoType.id.value, data.Ammo
end

function Player:Process()
  local weapon = Game.GetPlayer():GetWeaponRight()
  local gotAmmoType, ammoType, currentAmmo = getWeaponAndAmmo()

  if infiniteAmmo and gotAmmoType and currentAmmo < 200 then Game.AddToInventory(ammoType, 1000) end
  if noReload and weapon and weapon:GetMagazineAmmoCount() <= 0 then
    weapon:StartReload(-1)
    weapon:StopReload(gameweaponReloadStatus.Standard)
  end
end

function Player:DrawGUI()
  if not Player.Enabled then return end

  ImGui.SetWindowSize(360, 480)

  if ImGui.BeginTabBar("Tabs") then
    local prevSys = GameInstance.GetScriptableSystemsContainer():Get("PreventionSystem")
    if ImGui.BeginTabItem(IconGlyphs.Cog .. " General") then
      ImGui.Spacing()
      infiniteAmmo = ImGui.Checkbox(IconGlyphs.Ammunition .. " Infinite Ammo", infiniteAmmo)
      noReload = ImGui.Checkbox(IconGlyphs.MagazineRifle .. " No Reload", noReload)

      local toggle
      godMode, toggle = ImGui.Checkbox(IconGlyphs.Skull .. " Godmode", godMode)
      if toggle then
        if godMode then
          Game.GetGodModeSystem():AddGodMode(GetPlayer():GetEntityID(), gameGodModeType.Immortal, 'Default')
        else
          Game.GetGodModeSystem():RemoveGodMode(GetPlayer():GetEntityID(), gameGodModeType.Immortal, 'Default')
        end
      end

      local newPrevSysState, pressed = ImGui.Checkbox(IconGlyphs.PoliceBadge .. " Crime Prevention", prevSys.systemEnabled)
      if pressed then
        prevSys:TogglePreventionSystem(newPrevSysState)
        prevSys:ChangeHeatStage(0, "No")
      end

      if prevSys.systemEnabled then
        if ImGui.Button(IconGlyphs.PoliceBadge .. " Clear heat") then prevSys:ChangeHeatStage(0, "No") end
        if ImGui.Button(IconGlyphs.PoliceBadge .. " Most wanted") then prevSys:ChangeHeatStage(5, "No") end
      end

      ImGui.EndTabItem()
    end

    local veh = GetPlayer():GetMountedVehicle()
    if ImGui.BeginTabItem(IconGlyphs.Car .. " Autopilot") then
      ImGui.Spacing()

      clearTraffic = ImGui.Checkbox("Clear traffic", clearTraffic)
      useKinematic = ImGui.Checkbox("Use kinematic", useKinematic)
      minDist = ImGui.SliderInt("Min. Distance", minDist, 0, 100)
      minSpeed = ImGui.SliderInt("Min. Speed", minSpeed, 20, 200)
      maxSpeed = ImGui.SliderInt("Max. Speed", maxSpeed, 20, 200)
      if not customMappin or not veh then ImGui.BeginDisabled() end

      if ImGui.Button(" Activate ") then
        local pin = customMappin:GetWorldPosition():Vector4To3()
        Autopilot(veh, pin, minSpeed / 2, maxSpeed / 2, clearTraffic, useKinematic, minDist)
      end
      local hovered = ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled)

      ImGui.SameLine()
      if ImGui.Button(" Cancel ") then VehicleCancelLastCommand(veh) end
      hovered = hovered or ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled)

      if not customMappin or not veh then
        ImGui.EndDisabled()

        if hovered then
          if not veh then
            ImGui.SetTooltip("You are not in a vehicle.")
          else
            ImGui.SetTooltip("Custom map pin not found.\nIf you have one, try removing and re-adding it.")
          end
        end
      end

      ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(IconGlyphs.Car .. " Vehicle") then
      ImGui.Spacing()

      ImGui.Text("Nothing here is implemented yet, sadly.")
      vehicleGodMode = ImGui.Checkbox(IconGlyphs.Bomb .. " Indestructible", vehicleGodMode)
      infiniteVehicleAmmo = ImGui.Checkbox(IconGlyphs.Ammunition .. " Infinite vehicle ammo", infiniteVehicleAmmo)

      ImGui.EndTabItem()
    end

    if ImGui.BeginTabItem(IconGlyphs.IntegratedCircuitChip .. " Hacking") then
      ImGui.Spacing()
      ImGui.Text("Not implemented yet, unfortunately.")
      local used = false
      recoverySpeed, used = ImGui.SliderFloat("Recovery rate", recoverySpeed, 1, 10, "%.1fx", ImGuiSliderFlags.Logarithmic)
      quickhackCost, used = ImGui.SliderFloat("Cost Multiplier", quickhackCost, 0.001, 1, "%.3fx", ImGuiSliderFlags.Logarithmic)
      quickhackSpeed, used = ImGui.SliderFloat("Upload Speed", quickhackSpeed, 0.001, 1, "%.3fx", ImGuiSliderFlags.Logarithmic)

      ImGui.EndTabItem()
    end

    ImGui.EndTabBar()
  end
end

function Player:OnInit()
  Observe('BaseWorldMapMappinController', 'OnUpdate', function(self) if self:GetMappinVariant() == gamedataMappinVariant.CustomPositionVariant then customMappin = self:GetMappin() end end)
  Observe('WorldMapMenuGameController', 'UntrackCustomPositionMappin', function(self) customMappin = nil end)
end

return Player

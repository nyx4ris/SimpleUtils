Cheats = {Buttons = {}, Checkboxes = {}}

local State = {Disabled = 0, JustDisabled = 1, Enabled = 2, JustEnabled = 3}

local function updateState(v)
  if v.enabled then
    if v.state == State.Disabled then
      v.state = State.JustEnabled
    else
      v.state = State.Enabled
    end
  else
    if v.state == State.Enabled then
      v.state = State.JustDisabled
    else
      v.state = State.Disabled
    end
  end
end

local function getWeaponAndAmmo()
  local player = Game.GetPlayer()
  local transactionSystem = Game.GetTransactionSystem()
  local weapon = transactionSystem:GetItemInSlot(player, TweakDBID.new('AttachmentSlots.WeaponRight'))
  local gotAmmoType, ammoType = pcall(function() return WeaponObject.GetAmmoType(weapon:GetItemID()) end)

  local equipmentSystem = Game.GetScriptableSystemsContainer():Get('EquipmentSystem')
  local equipmentSystemPlayerData = equipmentSystem:GetPlayerData(player)
  local inventoryDataManager = equipmentSystemPlayerData:GetInventoryManager()

  local data = inventoryDataManager:GetItemDataFromIDInLoadout(weapon:GetItemID())

  return gotAmmoType, ammoType.id.value, data.Ammo
end

function Cheats:AddButton(name, callback) table.insert(Cheats.Buttons, {["name"] = name, ["callback"] = callback}) end
function Cheats:AddCheckbox(name, callback) table.insert(Cheats.Checkboxes, {["name"] = name, ["callback"] = callback, ["enabled"] = false, ["state"] = State.Disabled}) end

function Cheats:Init()
  Cheats:AddButton(IconGlyphs.Skull .. " Kill player", function() Game.GetPlayer():Kill(Game.GetPlayer(), true, true) end)

  Cheats:AddButton(IconGlyphs.Ammunition .. " 1k ammo for current weapon", function()
    local gotAmmoType, ammoType, currentAmmo = getWeaponAndAmmo()

    if gotAmmoType then
      Game.AddToInventory(ammoType, 1000)
    end
  end)

  Cheats:AddButton(IconGlyphs.Alert .. " Mark current quest finished (!)", function()
    local journalManager = Game.GetJournalManager()
    local trackedEntry = journalManager:GetTrackedEntry()
    local questEntry = journalManager:GetParentEntry(journalManager:GetParentEntry(trackedEntry))
    local questEntryHash = journalManager:GetEntryHash(questEntry)
    journalManager:ChangeEntryStateByHash(questEntryHash, gameJournalEntryState.Succeeded, gameJournalNotifyOption.Notify)
  end)

  Cheats:AddCheckbox(IconGlyphs.Ammunition .. " Infinite Ammo", function(enabled)
    if not enabled then return end

    local gotAmmoType, ammoType, currentAmmo = getWeaponAndAmmo()

    if gotAmmoType and currentAmmo < 200 then
      Game.AddToInventory(ammoType, tostring(1000 - currentAmmo))
    end
  end)

  registerForEvent('onUpdate', function()
    for k, v in pairs(Cheats.Checkboxes) do
      updateState(v)
      v.callback(v.enabled, v.state)
    end
  end)

  return Cheats
end

return Cheats:Init()

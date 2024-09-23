Dumper = {Colors = {}}
ImGui = ImGui or {}

local isInitialized = false

function Dumper:Dump()
  local classNames = {"gamedataClothing_Record", "gamedataWeaponItem_Record", "gamedataRecipeItem_Record", "gamedataConsumableItem_Record", "gamedataItem_Record", "gamedataGrenade_Record"}

  local items = {}
  local recordNames = {}
  for _, className in pairs(classNames) do
    local records = TweakDB:GetRecords(className) or {}
    for _, record in ipairs(records) do
      local recordId = record:GetID()
      recordNames[tostring(recordId.value)] = record
    end
  end

  for recordName, record in pairs(recordNames) do
    local locName = TDB.GetLocKey(recordName .. '.displayName')
    local quality = "Unknown"
    if record:Quality() then quality = record:Quality():Name() end
    local name = " " .. Game.GetLocalizedTextByKey(locName) .. " ##" .. quality

    local class = "Uncategorized"
    local locClass = record:ItemCategory()
    if locClass ~= nil then class = locClass:Name().value elseif recordName:find("Items.w_") then class = "Attachments" end
    if recordName:find("Ammo.") then class = "Ammo" end
    if class == "WeaponMod" then class = "Mod" end

    if name:gsub("%s*(.*)%s*##.*", "%1") ~= "" and not recordName:lower():find("shard", 1, true) then
      items[class] = items[class] or {}
      items[class][name] = recordName
    end
  end

  SimpleUtils.Dumper.Items = items
  SimpleUtils.Dumper.Records = recordNames
  SimpleUtils.Dumper.Dumped = true
  SimpleUtils.ItemUI:Filter()
end

function Dumper:new()
  registerForEvent('onInit', function()
    ObserveAfter('EquipmentSystem', 'OnPlayerAttach', function()
      Dumper:Dump()
      isInitialized = true
      SimpleUtils.Logger:Log("Dumper", "Successfully dumped item table!")
    end)

    if Game.GetPlayer() ~= nil then
      if not isInitialized then
        Dumper:Dump()
        SimpleUtils.Logger:Log("Dumper", "Successfully dumped item table!")
      end

      isInitialized = true
    else
      isInitialized = false
    end
  end)

  return Dumper
end

return Dumper:new()

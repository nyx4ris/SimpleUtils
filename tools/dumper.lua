Dumper = {Colors = {}}
ImGui = ImGui or {}

local isInitialized = false

function Dumper:Dump()
  SimpleUtils.Logger:Log("Dumper", "Dumping, please wait...")
  local itemClasses = {"gamedataClothing_Record", "gamedataWeaponItem_Record", "gamedataRecipeItem_Record", "gamedataConsumableItem_Record", "gamedataItem_Record", "gamedataGrenade_Record"}
  local vehicleClasses = {"gamedataVehicle_Record"}
  local allRecords = {}

  local items = {}
  local itemRecords = {}
  for _, itemClass in pairs(itemClasses) do
    local records = TweakDB:GetRecords(itemClass) or {}
    for _, record in ipairs(records) do
      local recordId = record:GetID()
      itemRecords[tostring(recordId.value)] = record
      allRecords[tostring(recordId.value)] = record
    end
  end

  for itemRecord, record in pairs(itemRecords) do
    local locName = TDB.GetLocKey(itemRecord .. '.displayName')
    local quality = "Unknown"
    if record:Quality() then quality = record:Quality():Name() end
    local name = " " .. Game.GetLocalizedTextByKey(locName) .. " ##" .. quality

    local class = "Uncategorized"
    local locClass = record:ItemCategory()
    if locClass ~= nil then
      class = locClass:Name().value
    elseif itemRecord:find("Items.w_") then
      class = "Attachments"
    end
    if itemRecord:find("Ammo.") then class = "Ammo" end
    if class == "WeaponMod" then class = "Mod" end

    if name:gsub("%s*(.*)%s*##.*", "%1") ~= "" and not itemRecord:lower():find("shard", 1, true) then
      items[class] = items[class] or {}
      items[class][name] = itemRecord
    end
  end

  local vehicles = {}
  local vehicleRecords = {}
  for _, vehicleClass in pairs(vehicleClasses) do
    local records = TweakDB:GetRecords(vehicleClass) or {}
    for _, record in ipairs(records) do
      local recordId = record:GetID()
      vehicleRecords[tostring(recordId.value)] = record
      allRecords[tostring(recordId.value)] = record
    end
  end

  for vehicleRecord, _ in pairs(vehicleRecords) do
    local locName = TDB.GetLocKey(vehicleRecord .. '.displayName')
    local name = Game.GetLocalizedTextByKey(locName)

    if name ~= "" then vehicles[vehicleRecord] = name end
  end

  SimpleUtils.Logger:Log("Dumper", "Successfully dumped item table!")

  SimpleUtils.Dumper.Dumped = true
  SimpleUtils.Dumper.Items = items
  SimpleUtils.Dumper.Records = allRecords
  SimpleUtils.Dumper.Vehicles = vehicles
  SimpleUtils.ItemUI:Filter()
  SimpleUtils.VehicleUI:Filter()
end

function Dumper:OnInit()
  ObserveAfter('EquipmentSystem', 'OnPlayerAttach', function()
    isInitialized = true
    self:Dump()
  end)
end

function Dumper:OnUpdate()
  if Game.GetPlayer() ~= nil then
    if not isInitialized then
      isInitialized = true
      self:Dump()
    end
  else
    isInitialized = false
  end
end

return Dumper
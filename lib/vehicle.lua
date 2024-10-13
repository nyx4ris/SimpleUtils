local inspect = require "lib/inspect"

-- Taken mostly from https://github.com/cyberscript77/release/blob/main/bin/x64/plugins/cyber_engine_tweaks/mods/cyberscript/mod/modules/npc.lua
SimpleUtils.Vehicle = SimpleUtils.Vehicle or {}
SimpleUtils.Vehicle.LastCommand = {}

function VehicleCancelLastCommand(veh, vehId)
  vehId = vehId or tostring(veh:GetEntityID().hash)

  if (SimpleUtils.Vehicle.LastCommand[vehId] ~= nil) then
    local AI = veh:GetAIComponent()
    AI:CancelCommand(SimpleUtils.Vehicle.LastCommand[vehId])
    AI:StopExecutingCommand(SimpleUtils.Vehicle.LastCommand[vehId], true)
    SimpleUtils.Vehicle.LastCommand[vehId] = nil
  end
end

function VehicleManageCmd(veh, cmd)
  local vehId = tostring(veh:GetEntityID().hash)

  if (SimpleUtils.Vehicle.LastCommand[vehId] ~= nil) then
    VehicleCancelLastCommand(veh, vehId)
  end

  SimpleUtils.Vehicle.LastCommand[vehId] = cmd
end

function Autopilot(veh, target, minSpeed, maxSpeed, clearTraffic, useKinematic, minDist)
  local cmd = NewObject("handle:AIVehicleDriveToPointAutonomousCommand")

  cmd.minSpeed = minSpeed or 10
  cmd.maxSpeed = maxSpeed or 30

  cmd.clearTrafficOnPath = clearTraffic or false
  cmd.minimumDistanceToTarget = minDist or 0
  cmd.targetPosition = target
  cmd.driveDownTheRoadIndefinitely = false

  cmd.needDriver = true

  cmd.useKinematic = useKinematic or true
  cmd = cmd:Copy()

  VehicleManageCmd(veh, cmd)

  local AINPCCommandEvent = NewObject("handle:AINPCCommandEvent")
  AINPCCommandEvent.command = cmd
  veh:QueueEvent(AINPCCommandEvent)
end
-- Taken mostly from https://github.com/cyberscript77/release/blob/main/bin/x64/plugins/cyber_engine_tweaks/mods/cyberscript/mod/modules/npc.lua
local lastcmd = {}

function VehicleCancelLastCommand(veh)
  if (lastcmd[veh] ~= nil) then
    local AI = veh:GetAIComponent()
    AI:CancelCommand(lastcmd[veh])
    AI:StopExecutingCommand(lastcmd[veh], true)
    lastcmd[veh] = nil
  end
end

function VehicleManageCmd(veh, cmd)
  if (lastcmd[veh] ~= nil) then
    VehicleCancelLastCommand(veh)
    lastcmd[veh] = cmd
  end
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
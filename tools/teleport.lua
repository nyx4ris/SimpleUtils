local fzy = require("lib/fuzz/fzy").filter
local dl = require("lib/fuzz/dl")
local jw = require("lib/fuzz/jw")

Teleporter = {Enabled = true}
ImGui = ImGui or {}

function Teleporter:DrawGUI()
  if not Teleporter.Enabled then return end

  ImGui.SetWindowSize(320, 480)

end

return Teleporter

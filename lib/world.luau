--!strict
--!native
--!optimize 2
local jecs = require("@pkg/jecs")

--- Note: This is not supposed to be used as the main world in your application.
--- This is purely the world to contain all systems and phases.
return jecs.World.new()

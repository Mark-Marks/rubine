--!strict
--!native
--!optimize 2
local jecs = require("@pkg/jecs")

local world = jecs.World.new()

local function a() end

local x = {
	a = a,
}

print(tostring(x.a))
print(tostring(table.clone(x).a))

--!strict
local fs = require("@lune/fs")

local function shim(from: string, to: string)
    for _, entry in fs.readDir(from) do
        fs.copy(`{from}/{entry}`, `{to}/{entry}`)
    end
end

shim("shims", "")
shim("extensions/roblox/shims", "extensoins/roblox")

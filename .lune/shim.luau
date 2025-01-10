--!strict
local fs = require("@lune/fs")

for _, entry in fs.readDir("shims") do
    fs.copy(`shims/{entry}`, entry)
end
for _, entry in fs.readDir("extensions/roblox/shims") do
    fs.copy(`extensions/roblox/shims/{entry}`, `extensions/roblox/{entry}`)
end

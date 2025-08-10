local fs = zune.fs

for _, entry in fs.readDir("shims") do
    local shim = entry.name
    fs.copy(`shims/{shim}`, shim)
end

for _, entry in fs.readDir("extensions/roblox/shims") do
    local shim = entry.name
    fs.copy(`extensions/roblox/shims/{shim}`, `extensions/roblox/{shim}`)
end

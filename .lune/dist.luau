--!strict
local spawn = require("./util/spawn")
local fs = require("@lune/fs")

spawn.start("lune run install-packages")
spawn.start("rojo sourcemap dev.project.json -o sourcemap.json")
spawn.start("darklua process --config .darklua.json lib/ dist/", { env = { ROBLOX_DEV = "false" } })
fs.copy("lib/abstractions.d.ts", "dist/abstractions.d.ts")
fs.copy("lib/index.d.ts", "dist/index.d.ts")
fs.copy("lib/scheduler.d.ts", "dist/scheduler.d.ts")
fs.copy("lib/types.d.ts", "dist/types.d.ts")
fs.copy("lib/world.d.ts", "dist/world.d.ts")

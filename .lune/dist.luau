--!strict
local spawn = require("./util/spawn")

spawn.start("lune run install-packages")
spawn.start("rojo sourcemap dev.project.json -o sourcemap.json")
spawn.start("darklua process --config .darklua.json lib/ dist/", { env = { ROBLOX_DEV = "false" } })

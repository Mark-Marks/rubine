--!strict
local spawn = require("./util/spawn")

spawn.start("lune run .lune/dist")
spawn.start("rojo build default.project.json -o build.rbxm")

--!strict
local spawn = require("./util/spawn")

spawn.start("lune run analyze")
spawn.start("stylua lib/")
spawn.start("selene lib/")

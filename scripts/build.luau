local build = require("./lib/build")

build {
    sourcemap_project = "sourcemap.project.json",
    build_project = "default.project.json",
    model_out = "build.rbxm",
    darklua_out = "out/",
}

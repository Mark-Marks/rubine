local Process = require("./util/Process")
local fs_util = require("./util/fs")
local fs = zune.fs

local function build(options: {
    sourcemap_project: string,
    build_project: string,
    model_out: string,
    darklua_out: string,
})
    if fs_util.exists(options.darklua_out) then
        fs_util.shell_remove(
            options.darklua_out,
            { recursive = true, force = true }
        )
    end

    Process.new("pesde"):argument("install"):option("stdio", "inherit"):run()

    Process.new("rojo")
        :argument("sourcemap")
        :argument(options.sourcemap_project)
        :argument("-o")
        :argument("sourcemap.json")
        :option("stdio", "inherit")
        :run()

    Process.new("darklua")
        :argument("process")
        :argument("--config")
        :argument(".darklua.json")
        :argument("lib/")
        :argument(options.darklua_out)
        :option("env", {
            ROBLOX_DEV = "false",
        })
        :option("stdio", "inherit")
        :run()

    Process.new("rojo")
        :argument("build")
        :argument(options.build_project)
        :argument("-o")
        :argument(options.model_out)
        :option("stdio", "inherit")
        :run()

    for _, entry in fs.readDir("lib") do
        local name = entry.name
        if not string.match(name, "^.+%.d%.ts$") then
            continue
        end

        fs.copy(`lib/{name}`, `{options.darklua_out}/{name}`)
    end
end

return build

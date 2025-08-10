local fs = zune.fs
local luau = zune.luau

type JECS = typeof(require("@pkg/jecs"))
type WORLD = typeof(require("@lib/world"))
type SCHEDULER = typeof(require("@lib/scheduler"))
type ABSTRACTIONS = typeof(require("@lib/abstractions"))

local JECS_BYTECODE
do
    local linker_source: string = fs.readFile("luau_packages/jecs.luau")
    local jecs_path = string.match(linker_source, '"%./%.pesde.+"')
        or error("Couldn't get jecs path")
    local subbed = string.gsub(jecs_path, '"', "")
    local direct = string.match(subbed, "%.pesde.+")
        or error("Couldn't get direct path for jecs")
    local source = fs.readFile(`luau_packages/{direct}/init.luau`)
    JECS_BYTECODE = luau.compile(source)
end

local WORLD_BYTECODE
do
    local source = fs.readFile("lib/world.luau")
    WORLD_BYTECODE = luau.compile(source)
end

local SCHEDULER_BYTECODE
do
    local source = fs.readFile("lib/scheduler.luau")
    SCHEDULER_BYTECODE = luau.compile(source)
end

local ABSTRACTIONS_BYTECODE
do
    local source = fs.readFile("lib/abstractions.luau")
    ABSTRACTIONS_BYTECODE = luau.compile(source)
end

local function make_require()
    local ENV = getfenv(1)
    local function load(bytecode: string)
        return luau.load(bytecode, {
            env = ENV,
        })()
    end

    local cache = {}

    ENV.require = function(source: string)
        if cache[source] then
            return cache[source]
        end

        local lib
        if source == "@pkg/jecs" then
            lib = load(JECS_BYTECODE)
        elseif source == "./world" then
            lib = load(WORLD_BYTECODE)
        elseif source == "./scheduler" then
            lib = load(SCHEDULER_BYTECODE)
        elseif source == "./abstractions" then
            lib = load(ABSTRACTIONS_BYTECODE)
        else
            print(`Got invalid require {source}`)
            return
        end
        cache[source] = lib
        return lib
    end

    return (
            ENV :: any
        ).require :: ((path: "@pkg/jecs") -> JECS) & ((path: "./world") -> WORLD) & ((path: "./scheduler") -> SCHEDULER) & ((
            path: "./abstractions"
        ) -> ABSTRACTIONS)
end

return make_require

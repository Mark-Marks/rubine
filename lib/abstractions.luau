--!strict
--!native
--!optimize 2
--# selene: allow(global_usage)
local jecs = require("@pkg/jecs")
type Entity<T = nil> = jecs.Entity<T>

local scheduler = require("./scheduler")
local world = require("./world")
local PreviousData = scheduler.PreviousSystemData
type SystemData = scheduler.System

--- A pipe to schedule systems under - abstraction over phases for the abstracted scheduler.
export type Pipe = string

--- Abstraction over phases.
--- Need to be registered with the low level scheduler in order to be used in it.
local function create_pipe(name: string?): Pipe
    local pipe_name
    if name then
        pipe_name = name
    else
        local _name, _line = debug.info(2, "sl")
        pipe_name = `{_name}:{_line}`
    end
    return pipe_name
end

--- An ordered set of pipes (phases).
--- Needs to be built for usage with the low level scheduler or used in the abstracted scheduler.
export type Pipeline = {
    --- Includes a pipe implicitly.
    with: (self: Pipeline, pipe: Pipe) -> Pipeline,
    --- Builds the pipeline following the given event.
    --- Optionally takes a table which it will turn into a map of pipe name -> phase entity, and check against to ensure no duplicate pipes.
    --- Returns an array of phase entities, with corresponding indexes.
    build: (
        self: Pipeline,
        event: scheduler.Event,
        other_built: { [Pipe]: Entity }?,
        after: Entity?
    ) -> { Entity },
    --- Internal array of all pipes.
    pipes: { Pipe },
}

local function build_pipes(built: { Entity }, pipes: { Pipe }, event: scheduler.Event, other_built: { [Pipe]: Entity }?)
    local this = table.remove(pipes, 1)
    if not this then
        return
    end

    if other_built and other_built[this] then
        error(`[rubine] Tried building pipe {this} which already is built`)
    end

    -- Take advantage of the implicit ordering and automatic event -> master phase resolution of `scheduler.phase()` like a boss
    local phase = scheduler.phase(this, event)
    table.insert(built, phase)
    if other_built then
        other_built[this] = phase
    end
    build_pipes(built, pipes, event, other_built)
end

--- Creates an ordered set of pipes.
local function create_pipeline(): Pipeline
    local pipeline = {
        pipes = {},
    } :: Pipeline

    function pipeline:with(pipe)
        table.insert(self.pipes, pipe)
        return self
    end

    function pipeline:build(event, other_built)
        table.freeze(self.pipes)
        local built = {}
        build_pipes(built, table.clone(self.pipes), event, other_built)
        return built
    end

    return pipeline
end

local on_call: { (system_id: Entity, system_data: SystemData, previous_data: SystemData) -> () } = {}
local on_add: { (system_id: Entity, system_data: SystemData) -> () } = {}
local on_remove: { (system_id: Entity) -> () } = {}
local on_change: { (system_id: Entity, system_data: SystemData, previous_data: SystemData) -> () } = {}

world:set(scheduler.System, jecs.OnSet, function(system_id, system_data: SystemData)
    if not system_data.propagated then
        for _, hook in on_add do
            hook(system_id, system_data)
        end
        system_data.propagated = true
        return
    end

    local previous: SystemData = world:get(system_id, PreviousData) :: any
    if not previous then
        world:set(system_id, PreviousData, system_data)
        previous = system_data
    end

    for _, hook in on_change do
        hook(system_id, system_data, previous)
    end

    if previous.frame_end ~= system_data.frame_end then
        for _, hook in on_call do
            hook(system_id, system_data, previous)
        end
    end
end)

world:set(scheduler.System, jecs.OnRemove, function(system_id)
    for _, hook in on_remove do
        hook(system_id)
    end
end)

--- Hooks onto `jecs.OnSet` and `jecs.OnRemove` for the system data component behind the scenes.
---
--- `SystemCall` is ran every time a system is called.
--- `SystemAdd` is ran every time a system is added.
--- `SystemRemove` is ran every time a system is removed.
--- `SystemChange` is ran every time a system is changed in any way.
export type Hookable = "SystemCall" | "SystemAdd" | "SystemRemove" | "SystemChange"
--- Hooks onto the given event.
local hook_on = function(on: Hookable, hook: any)
    if on == "SystemCall" then
        table.insert(on_call, hook)
    elseif on == "SystemAdd" then
        table.insert(on_add, hook)
    elseif on == "SystemRemove" then
        table.insert(on_remove, hook)
    elseif on == "SystemChange" then
        table.insert(on_change, hook)
    end
end :: ((
    on: "SystemCall" | "SystemChange",
    hook: (system_id: Entity, system_data: SystemData, previous_data: SystemData) -> ()
) -> ()) & ((on: "SystemAdd", hook: (system_id: Entity, system_data: SystemData) -> ()) -> ()) & ((on: "SystemRemove", hook: (system_id: Entity) -> ()) -> ())

local abstractions = {
    pipe = create_pipe,
    pipeline = create_pipeline,
    hook = hook_on,
}

return abstractions

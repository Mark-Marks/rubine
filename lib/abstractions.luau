--!strict
--!native
--!optimize 2
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
    return name or debug.info(2, "sl")
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

local function build_pipes(
    built: { Entity },
    pipes: { Pipe },
    event: scheduler.Event,
    other_built: { [Pipe]: Entity }?,
    last: Entity?
)
    local this = table.remove(pipes, 1)
    if not this then
        return
    end

    if other_built and other_built[this] then
        error(`[rubine] Tried building pipe {this} which already is built`)
    end

    local phase = scheduler.phase(this, event, last)
    table.insert(built, phase)
    if other_built then
        other_built[this] = phase
    end
    build_pipes(built, pipes, event, other_built, phase)
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

    function pipeline:build(event, other_built, after)
        table.freeze(self.pipes)
        local built = {}
        build_pipes(built, table.clone(self.pipes), event, other_built, after)
        return built
    end

    return pipeline
end

local on_call: { (system_id: Entity, system_data: SystemData, previous_data: SystemData) -> () } = {}
local on_add: { (system_id: Entity, system_data: SystemData) -> () } = {}
local on_remove: { (system_id: Entity) -> () } = {}
local on_change: { (system_id: Entity, system_data: SystemData, previous_data: SystemData) -> () } = {}

world:set(scheduler.System, jecs.OnSet, function(system_id, system_data: SystemData)
    local previous = world:get(system_id, PreviousData)
    if previous == nil then
        for _, hook in on_add do
            hook(system_id, system_data)
        end
        return
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

export type System<T... = ...any> = (T...) -> ()

--- An abstraction over the low level scheduler under `rubine/scheduler`.
--- Mutually exclusive with `rubine/scheduler`.
export type Scheduler = {
    --- @readonly Is the scheduler started?
    started: boolean,
    --- @readonly Map of system functions to names
    system_names: { [System]: string },
    --- @readonly Map of pipe names to phases
    built_pipes: { [Pipe]: Entity },
    --- @readonly Map of pipelines to their built phases
    built_pipelines: { [Pipeline]: { Entity } },

    --- Builds the given pipeline ordering explicitly by the given pipe / pipeline or implicitly.
    with_pipeline: (
        self: Scheduler,
        pipeline: Pipeline,
        event: scheduler.Event,
        after: Pipe | Pipeline?
    ) -> Scheduler,
    --- Builds the given pipe ordering explicitly by the given pipe / pipeline or implicitly.
    with_pipe: (self: Scheduler, pipe: Pipe, event: scheduler.Event, after: (Pipe | Pipeline)?) -> Scheduler,
    --- Registers all of the given systems under the given pipe.
    with_systems: (self: Scheduler, systems: { System }, pipe: Pipe) -> Scheduler,
    --- Registers the given system under the given pipe.
    with_system: (self: Scheduler, system: System, pipe: Pipe) -> Scheduler,

    --- Pauses the system with the given function or name.
    pause_system: (self: Scheduler, system: string | System) -> Scheduler,
    --- Unpauses the system with the given function or name.
    unpause_system: (self: Scheduler, system: string | System) -> Scheduler,

    --- Starts the scheduler.
    start: (self: Scheduler) -> Scheduler,
}

local function create_abstract_scheduler(): Scheduler
    local abstract_scheduler = {
        started = false,
        system_names = {},
        built_pipes = {},
        built_pipelines = {},
    } :: Scheduler

    function abstract_scheduler:with_pipeline(pipeline, event, after)
        if self.built_pipelines[pipeline] then
            error(`[rubine] Tried building pipeline {pipeline} which is already built`)
        end

        if not after then
            self.built_pipelines[pipeline] = pipeline:build(event, self.built_pipes)
            return abstract_scheduler
        end

        if type(after) == "string" then
            local phase = self.built_pipes[after]
            if not phase then
                error(`[rubine] Tried building pipeline {pipeline} after pipe {after} which isn't built`)
            end

            self.built_pipelines[pipeline] = pipeline:build(event, self.built_pipes, phase)
            return abstract_scheduler
        end

        local dependency_pipeline = self.built_pipelines[after]
        if not dependency_pipeline then
            error(`[rubine] Tried building pipeline {pipeline} after pipeline {after} which isn't built`)
        end

        local last_pipe = dependency_pipeline[#dependency_pipeline]
        self.built_pipelines[pipeline] = pipeline:build(event, self.built_pipes, last_pipe)

        return abstract_scheduler
    end

    function abstract_scheduler:with_pipe(pipe, event, after)
        if self.built_pipes[pipe] then
            error(`[rubine] Tried building pipe {pipe} which is already built`)
        end

        if not after then
            self.built_pipes[pipe] = scheduler.phase(pipe, event)
            return abstract_scheduler
        end

        if type(after) == "string" then
            local phase = self.built_pipes[after]
            if not phase then
                error(`[rubine] Tried building pipe {pipe} after pipe {after} which isn't built`)
            end

            self.built_pipes[pipe] = scheduler.phase(pipe, event, phase)
            return abstract_scheduler
        end

        local dependency_pipeline = self.built_pipelines[after]
        if not dependency_pipeline then
            error(`[rubine] Tried building pipe {pipe} after pipeline {after} which isn't built`)
        end

        local last_pipe = dependency_pipeline[#dependency_pipeline]
        self.built_pipes[pipe] = scheduler.phase(pipe, event, last_pipe)

        return abstract_scheduler
    end

    function abstract_scheduler:with_systems(systems, pipe)
        for _, system in systems do
            self:with_system(system, pipe)
        end
        return abstract_scheduler
    end

    function abstract_scheduler:with_system(system, pipe)
        if self.system_names[system] then
            error(`[rubine] Tried registering system with function address {tostring(system)} which already exists`)
            return abstract_scheduler
        end

        local name = debug.info(system, "n")
        if not name or string.len(name) == 0 then
            name = debug.info(system, "sl")
        end

        scheduler.on(pipe, system)
        self.system_names[system] = name
        return abstract_scheduler
    end

    function abstract_scheduler:pause_system(system)
        if type(system) == "function" then
            local name = self.system_names[system]
            if not name then
                print(`[rubine] Tried pausing system with function address {tostring(system)} which doesn't exist`)
                return abstract_scheduler
            end

            scheduler.pause(name)
            return abstract_scheduler
        end

        scheduler.pause(system)

        return abstract_scheduler
    end

    function abstract_scheduler:unpause_system(system)
        if type(system) == "function" then
            local name = self.system_names[system]
            if not name then
                print(`[rubine] Tried unpausing system with function address {tostring(system)} which doesn't exist`)
                return abstract_scheduler
            end

            scheduler.unpause(name)
            return abstract_scheduler
        end

        scheduler.unpause(system)

        return abstract_scheduler
    end

    function abstract_scheduler:start()
        if self.started then
            print("[rubine] Tried to start the scheduler more than once, continuing")
            return abstract_scheduler
        end

        self.started = true
        table.freeze(self.system_names)
        table.freeze(self.built_pipelines)
        table.freeze(self.built_pipes)

        scheduler.start()

        return abstract_scheduler
    end

    return abstract_scheduler
end

local abstractions = {
    pipe = create_pipe,
    pipeline = create_pipeline,
    hook = hook_on,
    scheduler = create_abstract_scheduler,
}

return abstractions

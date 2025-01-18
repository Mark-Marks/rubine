--!strict
--!native
--!optimize 2
--# selene: allow(global_usage)
--# selene: allow(empty_loop)
local jecs = require("@pkg/jecs")
local pair = jecs.pair
local Name = jecs.Name

type Entity<T = nil> = jecs.Entity<T>
type Pair<First, Second> = jecs.Pair<First, Second>
type World = jecs.World
type Tag = Entity<nil>

local world = require("./world")

export type System = {
    run: (...any) -> (),
    paused: boolean,
    frame_start: number,
    frame_end: number,
    propagated: boolean,
}

--- What ends up being called every frame, not the singleton itself
type FunctionEvent<T... = ...any> = ((T...) -> ()) -> any?
type SnakeSignalEvent<T... = ...any> = { connect: (self: SnakeSignalEvent<T...>, (T...) -> ()) -> any?, [any]: any }
type PascalSignalEvent<T... = ...any> = { Connect: (self: PascalSignalEvent<T...>, (T...) -> ()) -> any?, [any]: any }
export type Event<T... = ...any> = FunctionEvent<T...> | SnakeSignalEvent<T...> | PascalSignalEvent<T...>

local System: Entity<System> = world:component()
local DependsOn: Entity<Entity> = world:component()
local Event: Entity<Event> = world:component()
local Previous: Entity<any> = world:component()
--- We lie about the type here to get better types when doing `world:get(system_entity, scheduler.PreviousSystemData)`
local PreviousSystemData: Entity<System> = pair(Previous, System)
local Phase: Tag = world:entity()

local function collect_systems_under_phase(systems: { Entity }, phase: Entity)
    for system in world:query(System):with(pair(DependsOn, phase)):iter() do
        table.insert(systems, system)
    end

    for dependency in world:query(Phase):with(pair(DependsOn, phase)):iter() do
        collect_systems_under_phase(systems, dependency)
    end
end

type Runnables = { [Event]: { Entity } }
local PHASES = world:query(Event):with(Phase):cached()
local function collect_runnables(existing: Runnables)
    for phase, event in PHASES:iter() do
        existing[event] = {}
        collect_systems_under_phase(existing[event], phase)
    end
end

-- Faster than querying every time
local runnables: Runnables = {}
-- Faster than querying every time
local registered_phases: { [string]: Entity } = {}
-- Faster than querying every time
local registered_systems: { [string]: Entity } = {}

local started = false
local function start()
    assert(not started, "Cannot start the scheduler twice")
    started = true

    world:set(System, Name, "System")
    world:set(DependsOn, Name, "DependsOn")
    world:set(Event, Name, "Event")
    world:set(Phase, Name, "Phase")

    local function runner(event: Event): (...any) -> ()
        local running_system: (...any) -> () = nil
        local running_arguments: { any } = nil

        local function call_system()
            running_system(unpack(running_arguments))
        end

        -- Make it as cheap as possible
        local call_systems
        if _G.__RUBINE_DEBUG_MODE == true then
            call_systems = call_system
        else
            function call_systems()
                for _ in call_system :: any do
                end
            end
        end

        return function(...)
            running_arguments = table.pack(...)

            for _, system in runnables[event] do
                local data = world:get(system, System)
                if not data then
                    continue
                end

                if data.paused then
                    continue
                end

                -- Very low cost hooks using jecs hooks and reading previous data inside them
                world:set(system, PreviousSystemData, table.clone(data))

                data.frame_start = os.clock()
                running_system = data.run
                call_systems()
                data.frame_end = os.clock()

                -- Make sure hooks are ran
                world:set(system, System, data)
            end
        end
    end

    if _G.__RUBINE_DEBUG_MODE == true then
        print([[
            [rubine]
            ⚠️ DEBUG MODE IS CURRENTLY ACTIVE! ⚠️
            This means that systems are able to yield.
            It can lead to undesirable behavior, and therefore debug mode should be off in production to catch yielding.
        ]])
    end

    for _, event in PHASES:iter() do
        local run = runner(event)
        if type(event) == "function" then
            event(run)
            continue
        end

        if event.connect then
            event:connect(run)
            continue
        end

        event:Connect(run)
    end
end

local function get_farthest_dependant(master: Entity): (Entity, number)
    local farthest, by = master, 1
    for dependant in world:query(pair(DependsOn, master)):iter() do
        local this_farthest, this_by = get_farthest_dependant(dependant)
        if this_farthest and (by + this_by) > by then
            farthest = this_farthest
            by += this_by
        end
    end
    return farthest, by
end

--- Creates a phase.
---
--- Phases must either be bound to an event, or depend on another phase, which if gone up the dependency tree will result in a phase with an event.
--- A phase cannot have both an event and a dependency, as that would result in duplicate systems being ran.
---
--- Multiple phases which are bound to the same event will be changed to elect the first phase to be created as the master phase and the rest to depend on it.
local function create_phase(name: string, event_or_dependency: Entity | Event): Entity
    if registered_phases[name] then
        error(`[rubine] The phase {name} already exists`)
    end

    local phase = world:entity()
    world:add(phase, Phase)
    world:set(phase, Name, name)
    registered_phases[name] = phase

    if type((event_or_dependency :: any) :: number) == "number" then
        world:add(phase, pair(DependsOn, event_or_dependency))
        return phase
    end

    local master_phase_exists = false
    for p, e in PHASES:iter() do
        if event_or_dependency ~= e then
            continue
        end

        local farthest_dependant = get_farthest_dependant(p)
        world:add(phase, pair(DependsOn, farthest_dependant))
        master_phase_exists = true
        break
    end

    if not master_phase_exists then
        world:set(phase, Event, event_or_dependency)
    end

    return phase
end

--- Registers a system to run on the phase with the given name.
---
--- Multiple systems with the same name cannot exist.
--- Systems are internally named by either the function name or the script name and line number.
local function on(phase: string | Entity, fn: (...any) -> ()): Entity
    local entity = if type(phase) == "string" then registered_phases[phase] else phase
    if not entity then
        error(`[rubine] The phase {phase} doesn't exist`)
    end

    local phase_name = world:get(entity, Name)
    if not phase_name or not registered_phases[phase_name] then
        error(`[rubine] The phase {phase} doesn't exist`)
    end

    local name = debug.info(fn, "n")
    if not name or string.len(name) == 0 then
        local _name: string, _line: string = debug.info(fn, "sl")
        name = `{_name}:{_line}`
    end

    if registered_systems[name] ~= nil then
        error(`[rubine] Tried registering system called {name} which already exists`)
    end

    local system = world:entity()
    world:add(system, pair(DependsOn, entity))
    world:set(system, Name, name)
    world:set(system, System, {
        run = fn,
        paused = false,
        frame_start = 0,
        frame_end = 0,
        propagated = false,
    })
    registered_systems[name] = system

    collect_runnables(runnables)

    return system
end

--- Removes an existing system.
---
--- This function identifies systems either by their name or entity id.
local function remove(system: string | Entity)
    local entity = if type(system) == "number" then system else registered_systems[system]
    if not entity then
        if _G.__RUBINE_DEBUG_MODE == true then
            error(`[rubine] Tried removing a system called {system} which doesn't exist`)
        else
            print(`[rubine] Tried removing a system called {system} which doesn't exist`)
        end
        return
    end

    local name = world:get(entity, Name)
    if not name or (type(system) == "number" and not registered_systems[name]) then
        if _G.__RUBINE_DEBUG_MODE == true then
            error(`[rubine] Tried removing a system called {system} which doesn't exist`)
        else
            print(`[rubine] Tried removing a system called {system} which doesn't exist`)
        end
        return
    end
    registered_systems[name] = nil

    world:delete(entity)

    collect_runnables(runnables)
end

--- This function identifies systems either by their name or entity id.
local function pause(system: string | Entity)
    local entity = if type(system) == "number" then system else registered_systems[system]
    if not entity then
        if _G.__RUBINE_DEBUG_MODE == true then
            error(`[rubine] Tried pausing a system called {system} which doesn't exist`)
        else
            print(`[rubine] Tried pausing a system called {system} which doesn't exist`)
        end
        return
    end

    local name = world:get(entity, Name)
    if not name or (type(system) == "number" and not registered_systems[name]) then
        if _G.__RUBINE_DEBUG_MODE == true then
            error(`[rubine] Tried pausing a system called {system} which doesn't exist`)
        else
            print(`[rubine] Tried pausing a system called {system} which doesn't exist`)
        end
        return
    end

    local data = world:get(entity, System)
        or error(`[rubine] Irrecoverable error: system {system} doesn't have any data attached`)
    data.paused = true
    world:set(entity, System, data)
end

--- Unpauses an existing system.
---
--- This function identifies systems either by their name or entity id.
local function unpause(system: string | Entity)
    local entity = if type(system) == "number" then system else registered_systems[system]
    if not entity then
        if _G.__RUBINE_DEBUG_MODE == true then
            error(`[rubine] Tried unpausing a system called {system} which doesn't exist`)
        else
            print(`[rubine] Tried unpausing a system called {system} which doesn't exist`)
        end
        return
    end

    local name = world:get(entity, Name)
    if not name or (type(system) == "number" and not registered_systems[name]) then
        if _G.__RUBINE_DEBUG_MODE == true then
            error(`[rubine] Tried unpausing a system called {system} which doesn't exist`)
        else
            print(`[rubine] Tried unpausing a system called {system} which doesn't exist`)
        end
        return
    end

    local data = world:get(entity, System)
        or error(`[rubine] Unrecoverable error: system {system} doesn't have any data attached`)
    data.paused = false
    world:set(entity, System, data)
end

local scheduler = {
    start = start,

    phase = create_phase,
    on = on,
    remove = remove,
    pause = pause,
    unpause = unpause,

    System = System,
    PreviousSystemData = PreviousSystemData,
    DependsOn = DependsOn,
    Event = Event,
    Phase = Phase,
}

return scheduler

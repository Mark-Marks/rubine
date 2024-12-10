--!strict
--!native
--!optimize 2
local jecs = require("@pkg/jecs")
local pair = jecs.pair
local Name = jecs.Name

type Entity<T = nil> = jecs.Entity<T>
type Id<T = nil> = jecs.Id<T>
type Pair<First, Second> = jecs.Pair<First, Second>
type World = jecs.World
type Tag = Entity<nil>

local world = require("./world")

export type System = {
    run: (...any) -> (),
    paused: boolean,
    frame_start: number,
    frame_end: number,
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
-- We lie about the type here to get better types when doing `world:get(system_entity, scheduler.PreviousSystemData)`
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
local function collect_runnables(existing: Runnables)
    for phase, event in world:query(Event):with(Phase):iter() do
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

local function start()
    world:set(System, Name, "System")
    world:set(DependsOn, Name, "DependsOn")
    world:set(Event, Name, "Event")
    world:set(Phase, Name, "Phase")

    local function runner(event: Event): (...any) -> ()
        local running_system: (...any) -> () = nil
        local running_arguments: {} = nil

        local function call_system()
            running_system(unpack(running_arguments))
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
                for _ in call_system :: any do
                    break
                end
                data.frame_end = os.clock()

                -- Make sure hooks are ran
                world:set(system, System, data)
            end
        end
    end

    for _, event in world:query(Event):with(Phase):iter() do
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

local function create_phase(name: string, event: Event, after: Entity?): Entity
    if registered_phases[name] then
        error(`[rubine] The phase {name} already exists`)
    end

    local phase = world:entity()
    world:add(phase, Phase)
    if after then
        world:add(phase, pair(DependsOn, after))
    end
    world:set(phase, Event, event)
    world:set(phase, Name, name)

    registered_phases[name] = phase

    return phase
end

local function on(phase_name: string, fn: (...any) -> ()): Entity
    local phase = registered_phases[phase_name]
    if not phase then
        error(`[rubine] The phase {phase_name} doesn't exist`)
    end

    local name = debug.info(fn, "n")
    if not name or string.len(name) == 0 then
        name = debug.info(fn, "sl")
    end

    if registered_systems[name] ~= nil then
        print(`[rubine] Tried registering system called {name} which already exists, aborting`)
        return 0 :: Entity
    end

    local system = world:entity()
    world:set(system, System, {
        run = fn,
        paused = false,
        frame_start = 0,
        frame_end = 0,
    })
    world:add(system, pair(DependsOn, phase))
    world:set(system, Name, name)
    registered_systems[name] = system

    collect_runnables(runnables)

    return system
end

local function remove(system: string | Entity)
    local entity = if type(system) == "number" then system else registered_systems[system]
    if not entity then
        print(`[rubine] Tried removing a system called {system} which doesn't exist`)
        return
    end

    local name = world:get(entity, Name)
    if not name or (type(system) == "number" and not registered_systems[name]) then
        print(`[rubine] Tried removing a system called {system} which doesn't exist`)
        return
    end
    registered_systems[name] = nil

    world:delete(entity)
end

--- Pause a
local function pause(system: string | Entity)
    local entity = if type(system) == "number" then system else registered_systems[system]
    if not entity then
        print(`[rubine] Tried pausing a system called {system} which doesn't exist`)
        return
    end

    local name = world:get(entity, Name)
    if not name or (type(system) == "number" and not registered_systems[name]) then
        print(`[rubine] Tried pausing a system called {system} which doesn't exist`)
        return
    end

    local data = world:get(entity, System)
        or error(`[rubine] Irrecoverable error: system {system} doesn't have any data attached`)
    data.paused = true
    world:set(entity, System, data)
end

local function unpause(system: string | Entity)
    local entity = if type(system) == "number" then system else registered_systems[system]
    if not entity then
        print(`[rubine] Tried unpausing a system called {system} which doesn't exist`)
        return
    end

    local name = world:get(entity, Name)
    if not name or (type(system) == "number" and not registered_systems[name]) then
        print(`[rubine] Tried npausing a system called {system} which doesn't exist`)
        return
    end

    local data = world:get(entity, System)
        or error(`[rubine] Irrecoverable error: system {system} doesn't have any data attached`)
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

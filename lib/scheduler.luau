--!strict
--!native
--!optimize 2
local jecs = require("@pkg/jecs")
local pair = jecs.pair
local Name = jecs.Name

export type Entity<T = nil> = jecs.Entity<T>
export type Id<T = nil> = jecs.Id<T>
export type World = jecs.World
export type Tag = Entity<nil>

local world = require("./world")

type System = {
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
local registered_systems: { [string]: true } = {}

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

	if registered_systems[name] then
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
	registered_systems[name] = true

	collect_runnables(runnables)

	return system
end

local function pause(name: string)
	for id, system, system_name in world:query(System, Name):iter() do
		if name ~= system_name then
			continue
		end

		system.paused = true
		-- Make sure hooks run
		world:set(id, System, system)
		return
	end
	print(`Tried to pause system {name} which doesn't exist`)
end

local function unpause(name: string)
	for id, system, system_name in world:query(System, Name):iter() do
		if name ~= system_name then
			continue
		end

		system.paused = false
		-- Make sure hooks run
		world:set(id, System, system)
		return
	end
	print(`Tried to unpause system {name} which doesn't exist`)
end

local scheduler = {
	start = start,

	phase = create_phase,
	on = on,
	pause = pause,
	unpause = unpause,

	System = System,
	DependsOn = DependsOn,
	Event = Event,
	Phase = Phase,
}

return scheduler

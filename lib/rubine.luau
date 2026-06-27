--!strict
--!optimize 2
const jecs = require("../jecs")
const types = require("./types")

type Pack<T...> = types.Pack<T...>

export type it<QueryTerms... = (), Singletons... = ()> = {
    read delta_time: number,
    read archetype: jecs.Archetype,
    read columns: {
        [types.any_of<Pack<QueryTerms...>>]: {
            types.any_of<
                types.strip_components<Pack<QueryTerms...>>
            >
        },
    },
    read singletons: {
        [types.any_of<Pack<Singletons...>>]: types.any_of<
            types.strip_components<Pack<Singletons...>>
        >,
    },
    read entities: { jecs.Entity },
}

export type it_untyped<QueryTerms... = (), Singletons... = ()> = {
    read delta_time: number,
    read archetype: jecs.Archetype,
    read columns: { [jecs.Component<any>]: { any } },
    read singletons: {
        [jecs.Component<any>]: any,
    },
    read entities: { jecs.Entity },
}

@native
const function ecs_field<Component, QueryTerms..., Singletons...>(
    it: it_untyped<
        QueryTerms...,
        Singletons...
    >,
    component: Component
): types.ecs_field_return<
    types.is_one_of<
        Component,
        types.any_of<Pack<QueryTerms...>> | types.any_of<Pack<Singletons...>>
    >,
    types.any_of<Pack<QueryTerms...>>,
    types.any_of<Pack<Singletons...>>
>
    return (it.columns[component] or it.singletons[component]) :: any
end

export type FrameData = {
    read delta_time: number,
    read started_at: number,
    read finished_at: number,
}

export type Phase = jecs.Entity

export type Scheduler = {
    read world: jecs.World,

    read System: jecs.Component<it<...any, ...any>>,
    read Runner: jecs.Component<(it<...any, ...any>) -> ()>,
    read Query: jecs.Component<jecs.Query<...any>>,
    read Paused: jecs.Component,
    read FrameData: jecs.Component<FrameData>,
    read Phase: jecs.Component<Phase>,
    read DependsOn: jecs.Component<Phase>,
    read Previous: jecs.Component<any>,
    read PreviousFrameData: jecs.Pair<FrameData, any>,
}

--- Creates a scheduler.
--- The passed in world must be the same as the world you're using in your codebase in order for Rubine to work properly.
const function construct_scheduler(world: jecs.World): Scheduler
    const System = world:component<<it<...any, ...any>>>()
    world:set(System, jecs.Name, "System")

    const Runner = world:component<<(it<...any, ...any>) -> ()>>()
    world:set(Runner, jecs.Name, "Runner")

    const Query = world:component<<jecs.Query<...any>>>()
    world:set(Query, jecs.Name, "Query")

    const Paused = world:component()
    world:set(Paused, jecs.Name, "Paused")

    const FrameData = world:component<<FrameData>>()
    world:set(FrameData, jecs.Name, "FrameData")

    const Phase = world:component<<jecs.Entity>>()
    world:set(Phase, jecs.Name, "Phase")

    const DependsOn = world:component<<Phase>>()
    world:set(DependsOn, jecs.Name, "DependsOn")

    const Previous = world:component()
    world:set(Previous, jecs.Name, "Previous")

    const PreviousFrameData =
        jecs.pair(Previous, FrameData) :: jecs.Pair<FrameData, FrameData>
    world:set(PreviousFrameData, jecs.Name, "PreviousFrameData")

    return table.freeze {
        world = world,

        System = System,
        Runner = Runner,
        Query = Query,
        Paused = Paused,
        FrameData = FrameData,
        Phase = Phase,
        DependsOn = DependsOn,
        Previous = Previous,
        PreviousFrameData = PreviousFrameData,
    }
end

--- Creates a phase.
const function construct_phase(scheduler: Scheduler): Phase
    const phase = scheduler.world:entity()
    scheduler.world:add(phase, scheduler.Phase)
    scheduler.world:set(phase, jecs.Name, "phase")
    return phase
end

export type Pipeline = { Phase }
--- Orders all of the passed phases in-ECS, based on the order they're in the array.
const function construct_pipeline(
    scheduler: Scheduler,
    phases: { Phase }
): Pipeline
    const world = scheduler.world

    for idx, phase in phases do
        if idx < 2 then
            continue
        end

        const previous = phases[idx - 1]
        world:add(phase, jecs.pair(scheduler.DependsOn, previous))
    end

    return table.clone(phases)
end

type SystemBuilder = {
    read query_terms: <QueryTerms...>(QueryTerms...) -> SystemBuilder,
    read singletons: <Singletons...>(Singletons...) -> SystemBuilder,
    read id: () -> jecs.Entity,
}

--- Registers a system with the given callback and phase.
--- Returns a builder, which allows for query terms and singletons to be added.
--- A system without query terms is called a task, which doesn't iterate over any entities, and only optionally has access to any passed singletons. As the name suggests, it performs a task every tick.
const function register_system<QueryTerms..., Singletons...>(
    scheduler: Scheduler,
    fn: (
        it_untyped<QueryTerms..., Singletons...>
    ) -> (),
    phase: Phase
): SystemBuilder
    local it: types.writeable<it> = {
        delta_time = 0,
        archetype = nil :: any,
        columns = {},
        singletons = {},
        entities = {},
    }

    const world = scheduler.world
    const system = world:entity()
    world:set(system, scheduler.System, it)
    world:set(system, scheduler.Runner, fn)
    world:add(system, jecs.pair(scheduler.DependsOn, phase))
    world:set(system, scheduler.FrameData, nil :: any)
    world:set(system, scheduler.PreviousFrameData, nil :: any)
    world:set(system, jecs.Name, "system")

    const builder = {}

    const function with_query_terms<QueryTerms...>(...: QueryTerms...): SystemBuilder
        const query = world:query(... :: any)
        world:set(system, scheduler.Query, query)

        return builder
    end
    builder.query_terms = with_query_terms

    const function with_singletons<Singletons...>(...: Singletons...): SystemBuilder
        it.singletons = {}

        for idx = 1, select("#", ...) do
            const singleton = select(idx, ...)
            it.singletons[singleton] = world:get(singleton, singleton)
        end

        return builder
    end
    builder.singletons = with_singletons

    const function id(): jecs.Entity
        return system
    end
    builder.id = id

    return builder
end

@native
const function no_yield<A..., R...>(callback: (A...) -> R..., ...: A...): (number, number)
    const thread = coroutine.create(callback)
    const started = os.clock()
    const ok, msg = coroutine.resume(thread, ...)
    const finished = os.clock()

    if not ok then
        error(debug.traceback(thread, msg), 2)
    end

    if coroutine.status(thread) ~= "dead" then
        error(debug.traceback(thread, "Attempted to yield"), 2)
    end

    return started, finished
end

export type Stepper = (step: (dt: number) -> ()) -> () -> ()
--- A type helper aimed at creating a stepper.
const function construct_stepper(stepper: Stepper): Stepper
    return stepper
end

--- Takes the provided stepper and pipelines, and schedules all systems bound to the phases within the pipelines to run on the given stepper.
--- Systems will be ordered based on the order given to the phase they're bound to. For example, given pipelines `{ pipeline { phase_a, phase_b, phase_c }, pipeline { phase_d, phase_e, phase_f } }`, all systems bound to Phase A will be run first, afterwards systems bound to Phase B, et cetera, till Phase F.
--- A disconnect function is returned, which runs the disconnect function returned by the stepper, therefore stopping the systems from running.
--- If you wish to add and/or remove any systems after this function is called, be mindful for all of the phases you plan on using to have at least one bound system. This is because systems are collected only once, and more specifically the archetypes which encapsulate them - therefore, systems may be added/removed at will, as long as at least one has existed beforehand to collect the necessary archetype.
--- Keep in mind that you may also just pause systems to have them not run.
const function run_pipelines(
    scheduler: Scheduler,
    stepper: Stepper,
    pipelines: { Pipeline }
): () -> ()
    const world = scheduler.world
    local system_archetypes: { jecs.Archetype } = {}

    const System, Runner, Query, FrameData, PreviousFrameData =
        scheduler.System,
        scheduler.Runner,
        scheduler.Query,
        scheduler.FrameData,
        scheduler.PreviousFrameData

    for _, pipeline in pipelines do
        for _, phase in pipeline do
            const query = world
                :query(
                    System,
                    Runner,
                    FrameData,
                    PreviousFrameData,
                    jecs.pair(scheduler.DependsOn, phase)
                )
                :without(scheduler.Paused)
            for _, archetype in query:archetypes() do
                table.insert(system_archetypes, archetype)
            end
        end
    end

    @native
    const function step(delta_time: number)
        for _, system_archetype in system_archetypes do
            const system_entities = system_archetype.entities
            if #system_entities <= 0 then
                continue
            end

            const columns = system_archetype.columns_map
            const it_columns: { types.writeable<it> }, runner_columns: { (it) -> () }, query_columns: { jecs.Query<...any> }, framedata_columns: { FrameData }, prev_framedata_columns: { FrameData } =
                columns[System],
                columns[Runner],
                columns[Query],
                columns[FrameData],
                columns[PreviousFrameData]

            for row in system_entities do
                local it = it_columns[row]
                it.delta_time = delta_time

                local singletons = it.singletons
                for singleton in singletons do
                    singletons[singleton] = world:get(singleton, singleton)
                end

                const runner, query = runner_columns[row], query_columns[row]
                prev_framedata_columns[row] = framedata_columns[row]
                if query == nil then
                    const started, finished = no_yield(runner, it)
                    it_columns[row] = it

                    framedata_columns[row] = {
                        delta_time = delta_time,
                        started_at = started,
                        finished_at = finished,
                        took = finished - started,
                    }
                    continue
                end

                const runs_started = os.clock()
                local took = 0

                for _, archetype in query:archetypes() do
                    const entities = archetype.entities
                    if #entities <= 0 then
                        continue
                    end

                    it.archetype = archetype
                    it.columns = archetype.columns_map
                    it.entities = entities

                    const started, finished = no_yield(runner, it)
                    took += finished - started
                end

                const runs_finished = os.clock()
                framedata_columns[row] = {
                    delta_time = delta_time,
                    started_at = runs_started,
                    finished_at = runs_finished,
                    took = took,
                }

                it_columns[row] = it
            end
        end
    end

    const disconnect = stepper(step)
    return disconnect
end

return table.freeze {
    ecs_field = ecs_field,

    scheduler = construct_scheduler,
    phase = construct_phase,
    pipeline = construct_pipeline,
    system = register_system,

    stepper = construct_stepper,
    run_pipelines = run_pipelines,
}

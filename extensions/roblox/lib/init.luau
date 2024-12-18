--!strict
local abstractions = require(script.Parent.rubine.abstractions)
local jabby = require(script.Parent.jabby)
local jecs = require(script.Parent.jecs)
local scheduler = require(script.Parent.rubine.scheduler)
local world = require(script.Parent.rubine.world)

local RunService = game:GetService("RunService")

local Name = jecs.Name
local Phase = scheduler.Phase
local JabbySystemId = world:component()

--- Loads all of the children of an instance.
--- rubine-roblox doesn't do anything fancy to load modules with systems.
--- Modules should return `scheduler.on("phase", system_function)`, and therefore there nothing else is required to load them other than to require them.
local function load_children(parent: Instance)
    for _, child in parent:GetChildren() do
        if not child:IsA("ModuleScript") then
            continue
        end

        (require)(child)
    end
end

--- Loads all of the descendants of an instance.
--- rubine-roblox doesn't do anything fancy to load modules with systems.
--- Modules should return `scheduler.on("phase", system_function)`, and therefore there nothing else is required to load them other than to require them.
local function load_descendants(parent: Instance)
    for _, descendant in parent:GetDescendants() do
        if not descendant:IsA("ModuleScript") then
            continue
        end

        (require)(descendant)
    end
end

--- Adds a world to jabby.
local function add_jabby_world(world: jecs.World, named: string)
    table.insert(jabby.public, {
        class_name = "World",
        name = named,
        world = world,
        debug = Name,
    })
    jabby.public.updated = true
end

--- Sets the traffic check function in jabby.
local function set_jabby_check_function(fn: (player: Player) -> boolean)
    jabby.set_check_function(fn)
end

--- Sets up some phases from `RunService`.
--- The returns shouldn't be used, but they can if you want to be 100% sure you're getting the phases right.
---
--- `heartbeat`: `RunService.Heartbeat`
--- `pre_render`: `RunService.PreRender` -- Only set up on the client, won't work at all on the server
--- `pre_animation`: `RunService.PreAnimation`
--- `pre_simulation`: `RunService.PreSimulation`
--- `post_simulation`: `RunService.PostSimulation`
local function setup_default_phases(): {
    heartbeat: "heartbeat",
    pre_render: "pre_render",
    pre_animation: "pre_animation",
    pre_simulation: "pre_simulation",
    post_simulation: "post_simulation",
}
    local is_client = RunService:IsClient()

    if is_client then
        scheduler.phase("pre_render", RunService.PreRender)
    end
    scheduler.phase("heartbeat", RunService.Heartbeat)
    scheduler.phase("pre_animation", RunService.PreAnimation)
    scheduler.phase("pre_simulation", RunService.PreSimulation)
    scheduler.phase("post_simulation", RunService.PostSimulation)

    return {
        heartbeat = "heartbeat",
        pre_render = "pre_render",
        pre_animation = "pre_animation",
        pre_simulation = "pre_simulation",
        post_simulation = "post_simulation",
    }
end

--- Starts the scheduler and returns the jabby scheduler.
--- Make sure to only call this once per run context.
--- If you're using the abstracted scheduler alongside this, don't call the provided `:start` method.
--- Instead, build the abstracted scheduler and only afterwards call this function.
local function start()
    -- We store this map because you can't get a component from a deleted entity.
    local id_to_jabby_id = {}

    table.insert(jabby.public, {
        class_name = "World",
        name = "rubine-world",
        world = world,
        debug = Name,
    })
    jabby.public.updated = true

    local jabby_scheduler = jabby.scheduler.create("rubine-roblox")
    table.insert(jabby.public, jabby_scheduler)
    jabby.public.updated = true

    abstractions.hook("SystemAdd", function(id, data)
        local system_name = world:get(id, Name)
        if not system_name then
            error(`[rubine-roblox] Failed registering system with id {id}, couldn't get system name.`)
        end

        local system_phase = world:get(id, Phase)
        if not system_phase then
            error(`[rubine-roblox] Failed registering system with id {id}, couldn't get system phase.`)
        end

        local system_phase_name = world:get(system_phase, Name)
        if not system_phase_name then
            error(`[rubine-roblox] Failed registering system with id {id}, couldn't get system phase name.`)
        end

        local registered_system = jabby_scheduler:register_system({
            name = system_name,
            phase = system_phase_name,
        })
        id_to_jabby_id[id] = registered_system
        world:set(id, JabbySystemId, registered_system)
    end)

    abstractions.hook("SystemCall", function(id, data)
        local jabby_system_id = world:get(id, JabbySystemId)
        if not jabby_system_id then
            warn(`[rubine-roblox] Failed setting frame data for system {id}, couldn't get jabby system id.`)
            return
        end

        jabby_scheduler.processing_frame[id] = {
            started_at = data.frame_start,
        }

        scheduler:_mark_system_frame_end(jabby_system_id)
    end)

    abstractions.hook("SystemRemove", function(id)
        local jabby_system_id = id_to_jabby_id[id]
        if not jabby_system_id then
            warn(`[rubine-roblox] Failed to deregister system with id {id}, couldn't get jabby system id.`)
            return
        end

        jabby_scheduler:remove_system(jabby_system_id)
    end)

    abstractions.hook("SystemChange", function(id, data, previous)
        local jabby_system_id = world:get(id, JabbySystemId)
        if not jabby_system_id then
            warn(`[rubine-roblox] Failed to check changes in hook for system {id}, couldn't get jabby system id.`)
            return
        end

        if data.paused == previous.paused then
            -- There isn't really much else to check for
            return
        end

        local old_system_data = jabby_scheduler:get_system_data(jabby_system_id)
        if not old_system_data then
            warn(`[rubine-roblox] Couldn't get old jabby system data for system with id {id}`)
            return
        end

        old_system_data.paused = data.paused
        -- Make sure the changes are registered
        jabby_scheduler:set_system_data(old_system_data)
    end)

    scheduler.start()

    return jabby_scheduler
end

return {
    load_children = load_children,
    load_descendants = load_descendants,
    start = start,
    setup_default_phases = setup_default_phases,

    add_jabby_world = add_jabby_world,
    set_jabby_check_function = set_jabby_check_function,
    --- Component storing the id of the jabby system.
    JabbySystemId = JabbySystemId,

    --- Reexport of the rubine scheduler.
    scheduler = scheduler,
    --- Reexport of the rubine abstractions.
    abstractions = abstractions,
    --- Reexport of jabby.
    jabby = jabby,
    --- Reexport of the world used by rubine.
    --- It's the default world added to jabby, although you can add more using the provided `rubine-roblox.add_world` function.
    world = world,
}

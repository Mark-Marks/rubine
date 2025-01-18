--!strict
--!optimize 0
-- stylua: ignore start
local make_custom_require = require("./custom_require")
local signal = require("./signal")
local task = require("@lune/task")

type Entity<T = nil> = number & { __T: T }

local testkit = require("./testkit")

local phase_id = 0
local function make_name(): string
    phase_id += 1
    return `Phase{phase_id}`
end

local TEST, CASE, CHECK, FINISH, SKIP, FOCUS = testkit.test()

_G.__RUBINE_DEBUG_MODE = true
local function noop()
end

TEST("scheduler.phase()", function()
    do CASE "Registers phase"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        CHECK(world:has(p1, scheduler.Phase))
        CHECK(world:get(p1, jecs.Name) == p1_name)
    end

    do CASE "Can't register two phases named the same"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local ok = pcall(function()
            scheduler.phase(p1_name, event)
            scheduler.phase(p1_name, event)
        end)
        -- Should fail
        CHECK(not ok)
    end

    do CASE "When passed another phase, it depends on it"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name, p2_name = make_name(), make_name()
        local p1 = scheduler.phase(p1_name, event)
        local p2 = scheduler.phase(p2_name, p1)
        CHECK(world:has(p2, jecs.pair(scheduler.DependsOn, p1)))
    end

    do CASE "When passed an event that isn't yet assigned to a phase, assigns the event to the created phase"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)
        CHECK(world:get(p1, scheduler.Event) == event)
    end

    do CASE "When passed an event that's already assigned to a phase, makes the created phase depend on that phase"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name, p2_name = make_name(), make_name()
        local p1, p2 = scheduler.phase(p1_name, event), scheduler.phase(p2_name, event)
        CHECK(world:get(p1, scheduler.Event) == event)
        CHECK(not world:has(p2, scheduler.Event))
        CHECK(world:has(p2, jecs.pair(scheduler.DependsOn, p1)))
    end

    do CASE "Phases created with the same event properly order to the farthest dependant"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name, p2_name, p3_name, p4_name, p5_name = make_name(), make_name(), make_name(), make_name(), make_name()
        local p1 = scheduler.phase(p1_name, event)
        local p2 = scheduler.phase(p2_name, event)
        local p3 = scheduler.phase(p3_name, p2)
        local p4 = scheduler.phase(p4_name, p2)
        local p5 = scheduler.phase(p5_name, event)

        local pair = jecs.pair
        local DependsOn = scheduler.DependsOn
        CHECK(world:get(p1, scheduler.Event) == event)
        CHECK(world:has(p2, pair(DependsOn, p1)))
        CHECK(world:has(p3, pair(DependsOn, p2)))
        CHECK(world:has(p4, pair(DependsOn, p2)))
        CHECK(world:has(p5, pair(DependsOn, p3)) or world:has(p5, pair(DependsOn, p4)))
    end
end)

TEST("scheduler.on()", function()
    do CASE "Can't register a system with an invalid phase"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local ok = pcall(function()
            scheduler.on("DOESNT EXIST", noop)
        end)
        CHECK(not ok)
        local ok2 = pcall(function()
            scheduler.on(1234 :: any, noop)
        end)
        CHECK(not ok2)
    end

    do CASE "Registers system with phase entity"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)
        local e = scheduler.on(p1, noop)
        CHECK(world:has(e, jecs.pair(scheduler.DependsOn, p1)))
        CHECK(world:has(e, jecs.Name))
        CHECK(world:has(e, scheduler.System))
    end

    do CASE "Registers system with phase name"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)
        local e = scheduler.on(p1_name, noop)
        CHECK(world:has(e, jecs.pair(scheduler.DependsOn, p1)))
        CHECK(world:has(e, jecs.Name))
        CHECK(world:has(e, scheduler.System))
    end

    do CASE "Can't register two systems named the same"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)
        local ok = pcall(function()
            scheduler.on(p1, noop)
            scheduler.on(p1, noop)
        end)
        CHECK(not ok)
    end
end)

TEST("scheduler.remove()", function()
    do CASE "Can't remove system which doesn't exist"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local ok = pcall(function()
            scheduler.remove("doesnt exist")
        end)
        CHECK(not ok)
        local ok2 = pcall(function()
            scheduler.remove(1234 :: any)
        end)
        CHECK(not ok2)
    end

    do CASE "Removes system by entity"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)
        local sys = scheduler.on(p1, noop)
        scheduler.remove(sys)
        CHECK(not world:contains(sys))
    end

    do CASE "Removes system by name"
        local load = make_custom_require()
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)
        local sys1 = scheduler.on(p1, noop)
        local name = world:get(sys1, jecs.Name)
        assert(name)
        scheduler.remove(name)
        CHECK(not world:contains(sys1))
    end
end)

TEST("scheduler.start()", function()
    do CASE "Starts registered systems"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local ran1 = false
        local function SYSTEM_1()
            ran1 = true
        end
        scheduler.on(p1, SYSTEM_1)

        local ran2 = false
        local function SYSTEM_2()
            ran2 = true
        end
        scheduler.on(p1, SYSTEM_2)

        scheduler.start()
        event:fire()
        CHECK(ran1)
        CHECK(ran2)
    end

    do CASE "Systems are ordered properly"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name, p2_name = make_name(), make_name()
        local p1 = scheduler.phase(p1_name, event)
        local p2 = scheduler.phase(p2_name, p1)

        local last_ran = ""
        local function SYSTEM_1()
            last_ran = "SYSTEM_1"
        end
        scheduler.on(p1, SYSTEM_1)

        local function SYSTEM_2()
            last_ran = "SYSTEM_2"
        end
        scheduler.on(p2, SYSTEM_2)

        scheduler.start()
        event:fire()
        CHECK(last_ran == "SYSTEM_2")
    end

    do CASE "Systems can't yield in standard mode"
        _G.__RUBINE_DEBUG_MODE = false

        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local ok = pcall(function()
            local function SYSTEM_1()
                require("@lune/task").wait()
            end
            scheduler.on(p1, SYSTEM_1)

            scheduler.start()
            event:fire()
        end)
        CHECK(not ok)

        _G.__RUBINE_DEBUG_MODE = true
    end

    do CASE "Systems can yield in debug mode"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local ran = false
        local function SYSTEM_1()
            task.wait()
            ran = true
        end
        scheduler.on(p1, SYSTEM_1)

        scheduler.start()
        event:fire()

        local start = os.clock()
        while true do
            if os.clock() >= (start + 0.3) then
                CHECK(false)
                break
            end

            if ran then
                CHECK(ran)
                break
            end
        end
    end
end)

TEST("scheduler.pause()", function()
    do CASE "Can't pause an invalid system"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local ok = pcall(function()
            scheduler.pause("asd")
        end)
        CHECK(not ok)

        local ok2 = pcall(function()
            scheduler.pause(1234 :: any)
        end)
        CHECK(not ok2)
    end

    do CASE "System gets paused successfully"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local ran = false
        local function SYSTEM_1()
            ran = true
        end
        local sys1 = scheduler.on(p1, SYSTEM_1)

        scheduler.pause(sys1)
        scheduler.start()
        event:fire()
        CHECK(not ran)
    end
end)

TEST("scheduler.unpause()", function()
    do CASE "Can't unpause an invalid system"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local ok = pcall(function()
            scheduler.unpause("asd")
        end)
        CHECK(not ok)

        local ok2 = pcall(function()
            scheduler.unpause(1234 :: any)
        end)
        CHECK(not ok2)
    end

    do CASE "System gets unpaused successfully"
        local load = make_custom_require()
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local ran = false
        local function SYSTEM_1()
            ran = true
        end
        local sys1 = scheduler.on(p1, SYSTEM_1)

        scheduler.pause(sys1)
        scheduler.start()
        event:fire()
        CHECK(not ran)
        scheduler.unpause(sys1)
        event:fire()
        CHECK(ran)
    end
end)

TEST("abstractions.pipe()", function()
    do CASE "Pipes will always be unique"
        local load = make_custom_require()
        local abstractions = load("./abstractions")

        local pi1 = abstractions.pipe()
        local pi2 = abstractions.pipe()
        CHECK(pi1 ~= pi2)
    end

    do CASE "Pipes can be registered with rubine and used as phases"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local pi1 = abstractions.pipe()
        local p1 = scheduler.phase(pi1, event)
        local sys = scheduler.on(pi1, noop)
        CHECK(world:contains(sys))
        CHECK(world:has(sys, jecs.pair(scheduler.DependsOn, p1)))
    end
end)

TEST("abstractions.pipeline()", function()
    do CASE "Pipelines order correctly"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local pi1 = abstractions.pipe()
        local pi2 = abstractions.pipe()
        local pi3 = abstractions.pipe()
        abstractions.pipeline()
            :with(pi1)
            :with(pi2)
            :with(pi3)
            :build(event)

        local lookup = world:query(jecs.Name):cached()
        local function lookup_by_name(name: string): Entity
            for entity, entity_name in lookup:iter() do
                if entity_name == name then
                    return entity
                end
            end

            return 0 :: any
        end

        local p1, p2, p3 = lookup_by_name(pi1), lookup_by_name(pi2), lookup_by_name(pi3)
        CHECK(p1 ~= 0 :: any and world:contains(p1))
        CHECK(p2 ~= 0 :: any and world:contains(p2))
        CHECK(p3 ~= 0 :: any and world:contains(p3))

        CHECK(world:get(p1, scheduler.Event) == event)
        CHECK(world:has(p2, jecs.pair(scheduler.DependsOn, p1)))
        CHECK(world:has(p3, jecs.pair(scheduler.DependsOn, p2)))
    end

    do CASE "Pipes can't be duplicated within a pipeline"
        local load = make_custom_require()
        local abstractions = load("./abstractions")

        local event = signal()
        local pi1 = abstractions.pipe()
        local pi2 = abstractions.pipe()
        local ok = pcall(function()
            abstractions.pipeline()
                :with(pi1)
                :with(pi2)
                :with(pi2)
                :build(event)
        end)
        CHECK(not ok)
    end

    do CASE "Pipes can't be duplicated across pipelines"
        local load = make_custom_require()
        local abstractions = load("./abstractions")

        local event = signal()
        local pi1 = abstractions.pipe()
        local pi2 = abstractions.pipe()
        abstractions.pipeline()
            :with(pi1)
            :with(pi2)
            :build(event)

        local ok = pcall(function()
            abstractions.pipeline()
                :with(pi1)
                :build(event)
        end)
        CHECK(not ok)
    end

    do CASE "Pipelines can be used within rubine"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")
        local world = load("./world")
        local jecs = load("@pkg/jecs")

        local event = signal()
        local pi1 = abstractions.pipe()
        local built = abstractions.pipeline()
            :with(pi1)
            :build(event)
        local p1 = table.remove(built, 1) or error("Couldn't get phase")

        local sys1 = scheduler.on(pi1, noop)
        CHECK(world:contains(sys1))
        CHECK(world:has(sys1, jecs.pair(scheduler.DependsOn, p1)))
    end
end)

TEST("abstractions.hook()", function()
    do CASE "SystemCall"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local sys1 = scheduler.on(p1, noop)

        local ran = false
        abstractions.hook("SystemCall", function(sys)
            ran = true
            CHECK(sys1 == sys)
        end)

        scheduler.start()
        event:fire()

        CHECK(ran)
    end

    do CASE "SystemAdd"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local ran = false
        abstractions.hook("SystemAdd", function(sys)
            ran = true
        end)

        scheduler.on(p1, noop)

        CHECK(ran)
    end

    do CASE "SystemRemove"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local sys1 = scheduler.on(p1, noop)

        local ran = false
        abstractions.hook("SystemRemove", function(sys)
            ran = true
            CHECK(sys == sys1)
        end)

        scheduler.remove(sys1)

        CHECK(ran)
    end

    do CASE "SystemChange"
        local load = make_custom_require()
        local abstractions = load("./abstractions")
        local scheduler = load("./scheduler")

        local event = signal()
        local p1_name = make_name()
        local p1 = scheduler.phase(p1_name, event)

        local sys1 = scheduler.on(p1, noop)

        local ran = false
        abstractions.hook("SystemChange", function(sys)
            ran = true
            CHECK(sys == sys1)
        end)

        local ran2 = false
        abstractions.hook("SystemCall", function(sys)
            if sys == sys1 then
                ran2 = true
            end
        end)

        scheduler.pause(sys1)

        CHECK(ran)
        CHECK(not ran2)
    end
end)

FINISH()
-- stylua: ignore end

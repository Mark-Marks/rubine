--!strict
-- !!! NOT UNIT TESTS !!!
local scheduler = require("@lib/scheduler")

local function tick(tick_time: number)
    return function(run: (number) -> ())
        local last = os.clock()
        while true do
            local now = os.clock()
            if now < (last + tick_time) then
                continue
            end

            local dt = now - last
            run(dt)

            last = now
        end
    end
end

-- Luau deduplicates closures so each event needs to be unable to be deduplicated
local on_tick = scheduler.phase("tick", tick(1 / 6))
scheduler.phase("after_tick", on_tick)

local function on_tick_system(dt)
    print(`Running on tick, dt: {dt}s`)
end
scheduler.on("tick", on_tick_system)

local function after_tick_system(dt)
    print(`Running after tick, dt: {dt}s`)
end
scheduler.on("after_tick", after_tick_system)

scheduler.start()

print("Pausing on_tick_system")
scheduler.pause("on_tick_system")

print("Unpausing on_tick_system")
scheduler.unpause("on_tick_system")

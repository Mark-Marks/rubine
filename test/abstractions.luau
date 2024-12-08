--!strict
-- !!! NOT UNIT TESTS !!!
local abstractions = require("@lib/abstractions")
local world = require("@lib/world")

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

-- some weird luau screwery makes `debug.info(2, "sl")` for each of these `test/abstractions.luau`
local tick_a = abstractions.pipe("tick_a")
local tick_b = abstractions.pipe("tick_b")
local tick_c = abstractions.pipe("tick_c")

local tick_pipeline = abstractions.pipeline():with(tick_a):with(tick_b)

local function tick_a_system(dt: number)
	print(`Running on tick_a, dt: {dt}s`)
end

local function tick_b_system(dt: number)
	print(`Running on tick_b, dt: {dt}s`)
end

local function tick_c_system(dt: number)
	print(`Running on tick_c, dt: {dt}s`)
end

local scheduler = abstractions
	.scheduler()
	:with_pipeline(tick_pipeline, tick(1 / 5))
	:with_pipe(tick_c, tick(1 / 6), tick_pipeline)
	:with_system(tick_a_system, tick_a)
	:with_system(tick_b_system, tick_b)
	:with_system(tick_c_system, tick_c)
	:start()

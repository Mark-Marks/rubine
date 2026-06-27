```luau
const scheduler = rubine.scheduler()
const phase = rubine.phase(scheduler)

const ecs_field = rubine.ecs_field
-- This gets called for every single archetype matching a query of (Position, Velocity, BoundingBox)
-- The singleton Physics is also passed each time
-- The generics passed to rubine.it may be ommited for QOL --- passing them simply narrows down the type of ecs_field to make sure nothing unintentional can be done
-- However, you may find that for singletons, without the aforementioned generics you'll have to type cast the result of ecs_field to the value type of each singleton
-- You may also use it.columns and it.singletons
const function move_bodies(it: rubine.it<(Position, Velocity, BoundingBox), (Physics)>)
    const dt = it.delta_time
    const physics = ecs_field(it, Physics)
    
    local positions = ecs_field(it, Position)
    const velocities = ecs_field(it, Velocity)
    const bounding_boxes = ecs_field(it, BoundingBox)

    for row, entity in it.entities do
        positions[row] = physics.move_body(positions[row], velocities[row] * dt, bounding_boxes[row])
    end
end
-- These aren't strictly typed due to current limitations of the new solver
rubine.system(scheduler, move_bodies, phase)
    .with_query_terms(Position, Velocity, BoundingBox)
    .with_singletons(Physics)

const stepper = rubine.stepper(function(step)
    const connection = RunService.Heartbeat:Connect(function(dt)
        step(dt)
    end)

    return function()
        connection:Disconnect()
    end
end)

-- rubine.pipeline orders all of the passed phases to depend on the previous one in line
const pipeline = rubine.pipeline(scheduler, { phase })
rubine.run_pipelines(scheduler, stepper, { pipeline })
```

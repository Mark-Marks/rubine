local module = require(script.Parent.Parent.jecs)
export type Archetype = module.Archetype
export type Id<T = nil> = module.Id<T>
export type Pair<First, Second> = module.Pair<First, Second>
export type Entity<T = nil> = module.Entity<T>
export type World = module.World
return module

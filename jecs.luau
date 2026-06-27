--!strict
--!native
--!optimize 2
-- Pesde adds dependencies by including a folder with them in the package
-- Wally just adds a file for each dependency
-- This is here to mitigate that, acting as another linker file
local jecs = require("./luau_packages/jecs")
export type Archetype = jecs.Archetype
export type QueryInner = jecs.QueryInner
export type Entity<T = nil> = jecs.Entity<T>
export type Id<T = any> = jecs.Id<T>
export type Pair<First = any, Second = any> = jecs.Pair<First, Second>
export type Component<T = any> = jecs.Component<T>
export type Id2<First, Second = nil> = jecs.Id2<First, Second>
export type Item<T...> = jecs.Item<T...>
export type Iter<T...> = jecs.Iter<T...>
export type Cached_Query_Iter<T...> = jecs.Cached_Query_Iter<T...>
export type Cached_Query<T...> = jecs.Cached_Query<T...>
export type Query<T...> = jecs.Query<T...>
export type Observer = jecs.Observer
export type observer = jecs.observer
export type World = jecs.World
export type Record = jecs.Record
export type ComponentRecord = jecs.ComponentRecord
export type ComponentIndex = jecs.ComponentIndex
export type Archetypes = jecs.Archetypes
export type EntityIndex = jecs.EntityIndex
return jecs

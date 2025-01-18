import { Entity, World } from "@rbxts/jecs";
import jabby from "@rbxts/jabby";
export type * from "@rbxts/rubine";

import { Scheduler, Abstractions } from "@rbxts/rubine";

export interface RubineRoblox {
  load_children: (parent: Instance) => void;
  load_descendants: (parent: Instance) => void;
  setup: () => void;
  setup_default_phases: () => void;
  add_jabby_world: (world: World, named: string) => void;
  set_jabby_check_function: (fn: (player: Player) => boolean) => void;
  JabbySystemId: Entity;
  scheduler: Scheduler;
  abstractions: Abstractions;
  jabby: typeof jabby;
  world: World;
}

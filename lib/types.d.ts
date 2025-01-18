import { Entity } from "@rbxts/jecs";
import { World } from "@rbxts/jecs";

// path: lib/scheduler.luau
export type SchedulerSystem = {
  run: (...args: unknown[]) => void;
  paused: boolean;
  frame_start: number;
  frame_end: number;
  propagated: boolean;
};

type FunctionConnection = () => void;
type SnakeSignalConnection = { disconnect(): void };
type PascalSignalConnection = { Disconnect(): void };
type FunctionEvent<T extends unknown[]> = (
  run: (...args: T) => void,
) => FunctionConnection | void;
type SnakeSignalEvent<T extends unknown[]> = {
  connect(run: (...args: T) => SnakeSignalConnection): void;
};
type PascalSignalEvent<T extends unknown[]> = {
  Connect(run: (...args: T) => PascalSignalConnection): void;
};
type Event<T extends unknown[]> =
  | FunctionEvent<T>
  | SnakeSignalEvent<T>
  | PascalSignalEvent<T>;

export interface Scheduler {
  start: () => void;
  phase: (
    name: string,
    event_or_dependency: Entity | Event<unknown[]>,
  ) => Entity;
  on: (phase_name: string, fn: (...args: unknown[]) => void) => Entity;
  remove: (system: string | Entity) => void;
  pause: (system: string | Entity) => void;
  unpause: (system: string | Entity) => void;

  System: Entity<SchedulerSystem>;
  PreviousSystemData: Entity<SchedulerSystem>;
  DependsOn: Entity<Entity>;
  Event: Entity<Event<unknown[]>>;
  Phase: Entity;
}

// path: lib/abstractions.luau
export type Pipe = string;
export interface Pipeline<T extends unknown[]> {
  with(pipe: Pipe): Pipeline<T>;
  build(
    event: Event<T>,
    otherBuilt?: { [key: Pipe]: Entity },
    after?: Entity,
  ): Array<Entity>;
  pipes: Array<Pipe>;
}
export type Hookable =
  | "SystemCall"
  | "SystemAdd"
  | "SystemRemove"
  | "SystemChange";
type systemCallHook = (
  system_id: Entity,
  system_data: SchedulerSystem,
  previous_data: SchedulerSystem,
) => void;
type systemChangeHook = systemCallHook;
type systemAddHook = (system_id: Entity, system_data: SchedulerSystem) => void;
type systemRemoveHook = (system_id: Entity) => void;
type hook<T extends Hookable> = T extends "SystemCall"
  ? systemCallHook
  : T extends "SystemChange"
    ? systemChangeHook
    : T extends "SystemAdd"
      ? systemAddHook
      : systemRemoveHook;
export interface Abstractions {
  pipe: (name?: string) => Pipe;
  pipeline: () => Pipeline<unknown[]>;
  hook: <T extends Hookable>(on: T, hook: hook<T>) => void;
}

// path: lib/index.luau
export interface Rubine {
  scheduler: Scheduler;
  abstractions: Abstractions;
  world: World;
}

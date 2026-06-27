# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0-alpha.0] - 2026-06-27

### Added

- Explicit scheduler object. Nearly all provided functions rely on it being provided.
- Steppers, which directly replace events. The aim of this is for the user to be able to completely control the circumstances under which given pipelines (and by extension systems) are stepped, while also making it more universal.

### Changed

- Rewrite from the ground up.
- Rubine now expects the user to provide their own world to it.
- Systems are now more explicitly defined. They now take all used query terms and singletons, with the aim of better organization and forcing the user to inline queries, albeit with a better and more intuitive UX than doing it regularly.
- Phases no longer accept a name.
- Phases are no longer ordered at the site of their creation. Instead, they're explicitly ordered via pipelines, and more specifically the order in which they're passed to a pipeline.
- There's no longer one, unified start function to begin stepping all systems. Instead, all pipelines are explicitly started with the desired stepper using `.run_pipelines`.

## Removed

- Pipes & pipelines from abstractions. They were no longer needed due to restructuring of how the scheduler works, and because of the unneeded increased complexity they introduced.
- Hooks. It's fairly straight-forward to implement them yourself, if needed.
- The Roblox extension. An alternative will be introduced in the future.
- Typescript support. May be reintroduced in the future, if someone PRs it.
- Multiple utility functions - `remove`, `pause`, `unpause`. All of these may be directly replaced with Jecs' functionality.
- Events are no longer supported. In its place, pipelines are bound to steppers.
- Debug mode. There's no unexpected behaviour provided by the library that'll need to be caught at runtime, which won't be safe-guarded against in the future once the new type solver matures enough. This does entail complete removal of any ability to yield, however I don't think there's any use for it.

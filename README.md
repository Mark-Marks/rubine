# rubine
[![CI](https://img.shields.io/github/actions/workflow/status/mark-marks/rubine/ci.yml?style=for-the-badge&label=CI)](https://github.com/mark-marks/rubine/actions/workflows/ci.yml)
[![Wally](https://img.shields.io/github/v/tag/mark-marks/rubine?&style=for-the-badge)](https://wally.run/package/mark-marks/rubine)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/Mark-Marks/rubine/blob/main/LICENSE)

An ergonomic, runtime agnostic scheduler for [Jecs](https://github.com/ukendio/jecs)
<br/>

</div>

## Features

Rubine provides two schedulers - one with a fairly low level interface abstracting over directly adding entities and setting components,
and another abstracting over the low level one, with a "higher level" scheduler and utilities for phases.

Both can be used alongside each other, although some abstractions require to be "built" first.

In the case of pipes, they have to be either included within the abstracted scheduler
```luau
abstracted_scheduler
    :with_pipe(my_pipe, my_event)
```
or registered as a phase
```luau
scheduler.phase(my_pipe, my_event)
```

In the case of pipelines, they have to be either included within the abstracted scheduler
```luau
abstracted_scheduler
    :with_pipeline(my_pipeline, my_event)
```
or built
```luau
my_pipeline:build(my_event)
```

The abstracted scheduler starts the low level one by itself, so don't use both start functions together.

## Installation

### Pesde
1. `pesde add mark_marks/rubine` -- In case of release candidates, do `pesde add mark_marks/rubine@VERSION-rc.WHICH_RC`
2. `pesde install`

### Wally
1. Add it to your wally manifest
```toml
[dependencies]
rubine = "mark-marks/rubine@LATEST" # Replace LATEST with the latest version
```
2. `wally install`

## Todo

Before the 0.1.0 release, the following need to be done:

- [ ] Unit tests
- [x] Automatic CI & CD
- [x] Packaging
  - [x] Pesde luau package
  - [x] Wally roblox package
- [x] Extensibility
- [x] Built-in Roblox scheduling extension

## Mentions

Abstractions were inspired by the ecs agnostic [Planck scheduler](https://github.com/YetAnotherClown/Planck)

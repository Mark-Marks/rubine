# rubine
[![CI](https://img.shields.io/github/actions/workflow/status/mark-marks/rubine/ci.yml?style=for-the-badge&label=CI)](https://github.com/mark-marks/rubine/actions/workflows/ci.yml)
[![Wally](https://img.shields.io/github/v/tag/mark-marks/rubine?&style=for-the-badge)](https://wally.run/package/mark-marks/rubine)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/Mark-Marks/rubine/blob/main/LICENSE)

An ergonomic, runtime agnostic scheduler for [Jecs](https://github.com/ukendio/jecs)
<br/>

</div>

## Usage

Rubine provides two schedulers - one with a fairly low level interface abstracting over directly adding entities and setting components,
and another abstracting over the low level one, with a "higher level" scheduler and utilities for phases.

As for other abstractions:
- Pipes
```luau
local my_pipe = abstractions.pipe()

abstracted_scheduler:with_pipe(my_pipe, my_event)
-- or
scheduler.phase(my_pipe, my_event)

abstracted_scheduler:with_system(function() end, my_pipe)
-- Pipes are strings with their name. As long as they're registered with either scheduler, they can be used with the low level one.
scheduler.on(my_pipe, function() end)
```
- Pipelines
```luau
local pipe_a = abstractions.pipe()
local pipe_b = abstractions.pipe()

-- Abstracted scheduler:

local my_pipeline = abstractions.pipeline()
    :with(pipe_a)
    :with(pipe_b)

abstracted_scheduler:with_pipeline(my_pipeline, my_event)

-- Low level scheduler:

local my_pipeline = abstractions.pipeline()
    :with(pipe_a)
    :with(pipe_b)
    :build(my_event)

...

-- Works, pipeline was built and all pipes were registered
scheduler.on(pipe_a, function() end)
abstracted_scheduler:with_system(function() end, pipe_a)
```

Some examples can be found in the `test/` directory.

## Installation

Rubine can currently only be installed via [pesde](https://pesde.dev) git dependencies:
```sh
pesde add gh#mark-marks/rubine#main
```
When it's ready for an initial release, it'll be available on both pesde and wally.

## Todo

Before the initial release, the following need to be done:

- [ ] Unit tests
- [ ] Automatic CI & CD
- [ ] Packaging
  - [ ] Pesde luau package
  - [ ] Wally roblox package
- [ ] Extensibility
- [ ] Built-in Roblox scheduling extension

## Mentions

Abstractions were inspired by the ecs agnostic [Planck scheduler](https://github.com/YetAnotherClown/Planck)

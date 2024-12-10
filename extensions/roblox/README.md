# rubine-roblox
[![CI](https://img.shields.io/github/actions/workflow/status/mark-marks/rubine/ci.yml?style=for-the-badge&label=CI)](https://github.com/mark-marks/rubine/actions/workflows/ci.yml)
[![Wally](https://img.shields.io/github/v/tag/mark-marks/rubine?&style=for-the-badge)](https://wally.run/package/mark-marks/rubine)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/Mark-Marks/rubine/blob/main/LICENSE)

A rubine extension for Roblox.
<br/>

</div>

## Usage

`rubine-roblox` should ideally be used alongside `rubine` itself.
It's built as something that provides out of the box support for jabby and slightly easier setup, not as a framework.

```luau
-- server/main.server.luau
local rubinerbx = require("@pkg/rubine_roblox")

-- Sets up basic RunService events, see the function docs for more
rubinerbx.setup_default_phases()

rubinerbx.load_children(script.systems)
```
```luau
-- server/main.server.luau/systems
local scheduler = require("@pkg/rubine/scheduler")

return scheduler.on("heartbeat", function(dt: number)
    print(`Heartbeat, dt: {dt}`)
end)
```

## Installation

`rubine-roblox` is only available on wally, as it's a roblox package.
1. Add it to your wally manifest
```toml
[dependencies]
rubine_roblox = "mark-marks/rubine-roblox@LATEST" # Replace LATEST with the latest version
```
2. `wally install`

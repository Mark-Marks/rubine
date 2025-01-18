# rubine-roblox
[![CI](https://img.shields.io/github/actions/workflow/status/mark-marks/rubine/ci.yml?style=for-the-badge&label=CI)](https://github.com/mark-marks/rubine/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/Mark-Marks/rubine/blob/main/LICENSE)
<a href="https://wally.run/package/mark-marks/rubine-roblox"><img alt="Wally" src="https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmark-marks%2Frubine%2Frefs%2Fheads%2Fmain%2Fextensions%2Froblox%2Fwally.toml&query=package.version&prefix=mark-marks%2Frubine-roblox%40&style=for-the-badge&label=Wally&color=ad4646&logo=data:image/svg%2bxml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48dGl0bGU+V2FsbHk8L3RpdGxlPjxwYXRoIGZpbGw9Im5vbmUiIGQ9Ik0yMC4zMjUgMTguMTkxYy0xLjkxNSAyLjU5OS01LjEyNyA0LjI1NC04LjM1OCA0LjE4MS0uMjk2LS41MjgtLjc2My0xLjY3My4zNDgtMS4yOTcgMi4zNTUtLjA3NiA0Ljc3LTEuMDE0IDYuMzc1LTIuNzYxLjI5OS0uODUzLjgyLS45ODcgMS4zOC0uMzAxbC4xMjcuMDkuMTI4LjA4OHpNMTIuNzg1IDYuMmMtLjg5Mi4yNjQtLjEwNCAyLjY2LjQ1OSAxLjI3Mi0uMDc1LS40MDcuMjItMS4yODgtLjQ1OC0xLjI3MnptLS41OS0uMjQyYy0uNjY0LTEuMzM1IDEuOTY2LS4zNTMgMS44ODItLjIyOC0uMzI2LS44NTYtMi4zMDItMS4yNC0yLjI2My0uMTA4bC4xNzMuMTk3ek0xMS41NCAxOS4zOGMtLjI4LTEuMzY0IDEuOTY1LS45NTggMS45My0xLjgwMS0uOTkyLS4xNi0yLjM4Mi0uODMyLTEuMzQtMS45NjMgMS4wMjctMS4wMjIgMi41MzMtMS45NTYgMi40OTItMy42NDktLjI4NS42MTItLjkyIDEuOTMtMS44MzUgMi4zODctMS41NzMgMS4wOC00LjA5IDEuMTc5LTUuMjYtLjU1LS4zNDktLjQ2My0uNjg3LTEuNDkxLS40NC0uMzQyLjQ2Ni42NjguNiAxLjcwMi0uNTYxIDEuNDUzLTEuMjQ1LS40NDEtLjM2Mi0xLjc2NC0uNC0yLjY0Ni0uNi0xLjE0NCAxLjM3Ni0uNjA4IDEuNjIzLTEuNjk0QzguNjQgOS40MyA2LjcyIDguODMgNS44NDggOC45MWMtLjk5Ni4xNjUuODUxLS40OTUgMS4xOC0uNzkuNzczLS40NTMgMS41MDYtLjk5NiAyLjA5LTEuNjgyLS41NjIuNDgyLS43NjEuNTE2LS43NDktLjI4LTEuMTUyLS41Ny0uMTM3IDEuNjkzLTEuMzk3IDEuNjY4LS45MTIuNjA1LjYxOS0xLjE0NC4yMzItMS43ODctLjIxOS0xLjIzNCAxLjUtMS4zMjIgMS40My0uMjMuNzYyLS42MjQtLjYxNi0xLjAyMy0uNjE2LTEuMTczIDEuMzQ3LTEuMzA3IDMuNDEzLTEuMzk1IDUuMTItLjg3My45MTYuMjUgMS43MDQuODYyIDIuMDA2IDEuNzg2Ljg5NCAyLjA2NC40NzMgNC4zNTEuMjc4IDYuNTA0LS4xOCAxLjExNi40OTMgMi4wNzcgMS4zODEgMi40NjYuNDI2LjkxNyAxLjkxIDEuNzUyLjU3NSAyLjYwOC0xLjUzOSAxLjQ4OC0zLjY2MyAyLjQ3Ny01LjgzOCAyLjI1MnptOS4xMjMtMS42NjVjLTEuMjctLjQ3MS0xLjc3My0xLjc0Mi0yLjg4NC0yLjM2NS0uNTMzLS42MzgtLjk2LTEuMTU0LS4yOS0xLjc4My4yOTktMS4zNjggMS43OC0xLjg1MiAyLjQ1NC0yLjk4Ljc4Ny0uOTY4LjcwNC0yLjQzMS0uMjAyLTMuMjkxLS43OTctLjg2LTIuMDc2LTEuMjA2LTIuNTI3LTIuMzg1LTEuMjMtMS4wMi0zLjAyMS0xLjA1NS00LjQ5OS0xLjY3NS0xLjMyOC0uMTk0LTIuOTA1LS4yNjEtNC4wMjEuNjA2LTEuNDkyLjAzLTEuODA3IDEuNzc3LTIuNTk0IDIuNzI2LS43My42NDktMS42NTMgMS4yNjYtMS4xNTMgMi4zMzQtMS4wNDguNzE3LjE3OCAyLjAzNi42OTIgMi43NTQuMzA3IDEuMjAyLS45OTQgMy4xNzYuOTY4IDMuNTM4Ljc4NC4wMjYgMS4xNzMtLjg2OCAxLjc5Ni0uMDQzIDEuMzc1LjIyNSAxLjA5IDEuODk4IDEuMDE4IDIuOTM2LjA4Mi45MDItMS4wMiAxLjU2NS0uMzI5IDIuNS0uMTQuODc4LS4zMDMgMS42Ni0xLjI3Ni45MjMtMy45OTktMS43MTgtNi42NDktNi4xMy02LjE2Ny0xMC40NzMuMzM0LTQuMTIyIDMuMzc3LTcuODM0IDcuMzQ1LTguOTg4IDQuMDgtMS4zMSA4Ljg0Ny4yODggMTEuMzUzIDMuNzU1IDIuNTg0IDMuNDAxIDIuNzMxIDguMzguMzE2IDExLjkxWk0xMS43NjguMDAzQzYuODQ4LjAzOSAyLjE4NSAzLjQ0NS42NTIgOC4xMmMtMS40OTUgNC4xOC0uMzU4IDkuMTEzIDIuNzc2IDEyLjI0OSAzLjI1NiAzLjQ0IDguNjMzIDQuNTY5IDEzLjAxIDIuNzc0IDQuNjM2LTEuNzg5IDcuODMtNi42OTIgNy41NDItMTEuNjYtLjE1NS00LjY2My0zLjMtOS4wNC03LjY3MS0xMC42NzJhMTEuODcyIDExLjg3MiAwIDAgMC00LjU0LS44MVoiIHN0eWxlPSJmaWxsOiNGRkY7ZmlsbC1vcGFjaXR5OjE7c3Ryb2tlOm5vbmUiLz48L3N2Zz4=" /></a>
[![Typescript Version](https://img.shields.io/npm/v/@rbxts/rubine-roblox.svg?style=for-the-badge&logo=npm)](https://www.npmjs.com/package/@rbxts/rubine-roblox)

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

### Wally
1. Add it to your wally manifest
```toml
[dependencies]
rubine_roblox = "mark-marks/rubine-roblox@LATEST" # Replace LATEST with the latest version
```
2. `wally install`

### NPM
1. `npm add @rbxts/rubine-roblox`
2. `npm install`

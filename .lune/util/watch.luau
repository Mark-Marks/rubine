--!strict
local fs = require("@lune/fs")
local task = require("@lune/task")

local function watch(path: string, on_change: (path: string, contents: string) -> (), run_initially: boolean?)
    local initial_metadata = fs.metadata(path)
    if not initial_metadata.exists then
        return
    end

    if run_initially then
        local initial_contents = fs.readFile(path)

        local initial_success, why = pcall(on_change :: any, path, initial_contents) -- :: any because otherwise it shits itself and the type doesn't give (boolean, string)??
        if not initial_success then
            warn(`There was an error while trying to start the watcher thread:\n{why}`)
            return
        end
    end

    local last_modification = initial_metadata.modifiedAt

    while true do
        local metadata = fs.metadata(path)

        if not metadata.exists then
            continue
        end

        if metadata.modifiedAt == last_modification then
            continue
        end
        last_modification = metadata.modifiedAt

        local contents = fs.readFile(path)

        local success, err = pcall(on_change :: any, path, contents)
        if not success then
            warn(err)
        end

        task.wait(1)
    end
end

return watch

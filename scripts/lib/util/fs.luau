local fs = zune.fs
local task = zune.task
local process = zune.process

local function exists(path: string): boolean
    local _, res = pcall(fs.readDir, path)
    return res ~= "FileNotFound"
end

local function ensure_dirs(dirs: { string })
    for _, dir in dirs do
        if exists(dir) and fs.isDir(dir) then
            continue
        end
        fs.writeDir(dir, true)
    end
end

local function remove(path: string, recursive: boolean?)
    if fs.isDir(path) then
        fs.removeDir(path, recursive)
        return
    end
    fs.removeFile(path)
end

local function remove_safe(path: string, recursive: boolean?)
    if not exists(path) then
        return
    end
    remove(path, recursive)
end

local function shell_remove(
    path: string,
    flags: { recursive: boolean?, force: boolean? }?
)
    local args = table.create(3)
    if flags then
        if flags.recursive then
            table.insert(args, "-r")
        end

        if flags.force then
            table.insert(args, "-Force")
        end
    end
    table.insert(args, path)
    process.run("rm", args, { shell = "pwsh" })
end

local function mime_folders(paths: { string }): () -> ()
    local acting: { [string]: true } = {}
    for _, path in paths do
        if fs.isDir(path) then
            continue
        end
        fs.writeDir(path)
        acting[path] = true
    end

    local function cleanup()
        for path in acting do
            fs.removeDir(path)
        end
    end

    return cleanup
end

local function traverse(
    dir: string,
    fn: (
        path: string,
        name: string,
        metadata: Metadata
    ) -> ()
)
    assert(fs.isDir(dir))

    for _, entry in fs.readDir(dir) do
        local path = `{dir}/{entry.name}`
        local child = fs.metadata(path)
        if not child then
            continue
        end

        fn(path, entry.name, child)
        if child.kind == "directory" then
            traverse(path, fn)
            continue
        end
    end
end

local function watch_file(
    path: string,
    fn: (metadata: Metadata) -> ()
): () -> ()
    local origin_metadata = fs.metadata(path)
    local last_modified = origin_metadata.modified_at

    local thread = task.spawn(function()
        while true do
            task.wait(1)

            local metadata = fs.metadata(path)
            if last_modified < metadata.modified_at then
                last_modified = metadata.modified_at
                fn(metadata)
            end
        end
    end)

    return function()
        task.cancel(thread)
    end
end

return {
    exists = exists,
    ensure_dirs = ensure_dirs,
    remove = remove,
    remove_safe = remove_safe,
    shell_remove = shell_remove,
    mime_folders = mime_folders,
    traverse = traverse,
    watch_file = watch_file,
}

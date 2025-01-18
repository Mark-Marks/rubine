-- licensed under MIT
-- @author jackdotink
-- https://github.com/red-blox/Util/blob/main/libs/Signal/Signal.luau
-- adapted to work in pure luau

type node<T...> = {
    next: node<T...>?,
    callback: (T...) -> (),
}

export type signal<T...> = {
    root: node<T...>?,

    connect: (self: signal<T...>, Callback: (T...) -> ()) -> () -> (),
    wait: (self: signal<T...>) -> T...,
    once: (self: signal<T...>, Callback: (T...) -> ()) -> () -> (),
    fire: (self: signal<T...>, T...) -> (),
    disconnect_all: (self: signal<T...>) -> (),
}

local Signal = {}
Signal.__index = Signal

-- Extracted this function from Connect as it results in the closure
-- made in Connect using less memory because this function can be static
local function disconnect<T...>(self: signal<T...>, Node: node<T...>)
    if self.root == Node then
        self.root = Node.next
    else
        local Current = self.root

        while Current do
            if Current.next == Node then
                Current.next = Node.next
                break
            end

            Current = Current.next
        end
    end
end

function Signal.connect<T...>(self: signal<T...>, Callback: (T...) -> ()): () -> ()
    local node = {
        next = self.root,
        callback = Callback,
    }

    self.root = node

    return function()
        disconnect(self, node)
    end
end

function Signal.wait<T...>(self: signal<T...>): T...
    local Thread = coroutine.running()
    local Disconnect

    Disconnect = self:connect(function(...)
        Disconnect()
        coroutine.resume(Thread, ...)
    end)

    return coroutine.yield()
end

function Signal.once<T...>(self: signal<T...>, Callback: (T...) -> ()): () -> ()
    local Disconnect

    Disconnect = self:connect(function(...)
        Disconnect()
        Callback(...)
    end)

    return Disconnect
end

function Signal.fire<T...>(self: signal<T...>, ...: T...)
    local Current = self.root

    while Current do
        Current.callback(...)
        Current = Current.next
    end
end

function Signal.disconnect_all<T...>(self: signal<T...>)
    self.root = nil
end

return function<T...>(): signal<T...>
    return setmetatable({
        root = nil,
    }, Signal) :: any
end

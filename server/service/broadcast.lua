local Skynet = require "local_skynet"
local Debug = require "lualib.debug"
local Cmd = require "broadcast.command"
local service_name = ...

local function __init__()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(Cmd[cmd], cmd)
        Skynet.retpack(f(...))
    end)
    Skynet.register(service_name)
    Debug.fprint("====service %s start====",service_name)
end

Skynet.start(__init__)
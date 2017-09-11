local Skynet = require "local_skynet"
local Debug = require "lualib.debug"
local Handle = import "scene/command"

local iNo = ...
iNo = math.floor(tonumber(iNo))

local function __init__()
    Skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(Handle.command[cmd], cmd)
        Skynet.retpack(f(...))
    end)
    Skynet.register("SCENE" .. iNo)
    Debug.fprint("====service %s start====","SCENE" .. iNo)
end

Skynet.start(__init__)
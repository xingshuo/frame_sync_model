local Debug = require "lualib.debug"
local Skynet = require "skynet"
require "skynet.manager"

local M = {}

local skynet_register = Skynet.register
local service_name
function M.register(name)
    if service_name ~= nil then
        Debug.fprint("=====register same service name %s======",name)
    end
    service_name = name
    skynet_register(name)
end
-- assert(not Skynet.service_name)
function M.service_name()
    return service_name or "__none"
end

function M.SendAgent(pid, cmd, ...)
	local AgentApi = import "agent/api"
	local agent = AgentApi.get_user_agent( pid )
	Skynet.send(agent, "lua", cmd, pid, ...)
end

function M.CallAgent(pid, cmd,  ...)
	local AgentApi = import "agent/api"
	local agent = AgentApi.get_user_agent( pid )
	return Skynet.call(agent, "lua", cmd, pid, ...)
end

for k, v in pairs(M) do
    Skynet[k] = v
end

return Skynet
local Skynet = require "lualib.local_skynet"

local broadcast_list = {}

--通用广播服
table.insert(broadcast_list, "PUB_BC")

--场景广播服
local iSceneBCNum = Skynet.getenv("SCENE_BC_CNT")
for i=1,iSceneBCNum do
	table.insert(broadcast_list, "SCENE_BC"..i)
end

function init_broadcast_services()
	for _,service in ipairs(broadcast_list) do
		Skynet.newservice("broadcast", service)
	end
end

function register_fd(uuid, fd)
	for _,service in ipairs(broadcast_list) do
		Skynet.send(service, "lua", "register_fd", uuid, fd)
	end
end

function unregister_fd(uuid)
	for _,service in ipairs(broadcast_list) do
		Skynet.send(service, "lua", "unregister_fd", uuid)
	end
end


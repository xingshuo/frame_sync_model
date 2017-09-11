local Socketdriver = require "socketdriver"
local fd_map = {}

local M = {}

function M.register_fd(uuid, fd)
	fd_map[uuid] = fd
end

function M.unregister_fd(uuid)
	fd_map[uuid] = nil
end

function M.send_to_player(uuid, data)
	local fd = fd_map[uuid]
	if fd then
		Socketdriver.send(fd, data)
	end
end

function M.send_to_list(uuid_list, data)
	for _,uuid in pairs(uuid_list) do
		local fd = fd_map[uuid]
		if fd then
			Socketdriver.send(fd, data)
		end
	end
end

function M.send_to_tbl(uuid_tbl, data)
	for uuid in pairs(uuid_tbl) do
		local fd = fd_map[uuid]
		if fd then
			Socketdriver.send(fd, data)
		end
	end
end

function M.world_broadcast(data)
	for uuid,fd in pairs(fd_map) do
		Socketdriver.send(fd, data)
	end
end

return M

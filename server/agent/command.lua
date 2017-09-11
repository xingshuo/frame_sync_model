local Skynet = require "lualib.local_skynet"
local env = import "agent/env"
local net = import "lualib/net"
local player = import "agent/player"
local NetCmd = import "lualib/netcmd"

command = {}

function command.start(pid, mArgs)
	local pobj = player.NewPlayer(pid, mArgs)
	pobj:login()
    pobj:enterwar()
end

function command.kick(pid)
	local pobj = env.get_player(pid)
	if pobj then
        pobj:leavewar()
		pobj:quit()
	end
end

function command.Unpack(pid, msg, sz)
	local proto,param = net.unpack(msg, sz)
	NetCmd.Analysis(pid, proto, param)
end
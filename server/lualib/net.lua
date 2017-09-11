local SprotoEnv = require 'sproto_env'
local Skynet = require "local_skynet"
local NetCmd = import "lualib/netcmd"
local sp = SprotoEnv.load()
local sp_recv = sp:host(SprotoEnv.BASE_PACKAGE)
local sp_send = sp_recv:attach(sp)
local PACK_FMT = '>s2'

function send_to_player(uuid, proto, param, broadcast_addr)
	broadcast_addr = broadcast_addr or "PUB_BC"
	local now = GetSecond()
	local ud = {timestamp = now}
    local data = string.pack(PACK_FMT, sp_send(proto, param, nil, ud))
    Skynet.send(broadcast_addr, "lua", "send_to_player", uuid, data)
end

function send_to_list(uuid_list, proto, param, broadcast_addr)
	broadcast_addr = broadcast_addr or "PUB_BC"
	local now = GetSecond()
	local ud = {timestamp = now}
	local data = string.pack(PACK_FMT, sp_send(proto, param, nil, ud))
	Skynet.send(broadcast_addr, "lua", "send_to_list", uuid_list, data)
end

function send_to_tbl(uuid_tbl, proto, param, broadcast_addr)
	broadcast_addr = broadcast_addr or "PUB_BC"
	local now = GetSecond()
	local ud = {timestamp = now}
	local data = string.pack(PACK_FMT, sp_send(proto, param, nil, ud))
	Skynet.send(broadcast_addr, "lua", "send_to_tbl", uuid_tbl, data)
end

function world_broadcast(proto, param, broadcast_addr)
	broadcast_addr = broadcast_addr or "PUB_BC"
	local now = GetSecond()
	local ud = {timestamp = now}
	local data = string.pack(PACK_FMT, sp_send(proto, param, nil, ud))
	Skynet.send(broadcast_addr, "lua", "world_broadcast", data)
end

function unpack(msg, sz)
	local msg_type, proto, param = sp_recv:dispatch(msg, sz)
	return proto,param
end
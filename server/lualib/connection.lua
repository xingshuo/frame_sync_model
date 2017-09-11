local Debug = require "lualib.debug"
local Class = require "lualib.class"
local Skynet = require "lualib.local_skynet"

conlist = conlist or {}

Connection = Class("Connection")

function Connection:init(fd)
	self.m_fd = fd
	self.m_StartTime = GetSecond()
end

function Connection:loginsuc(agent, pid)
	self.m_Agent = agent
	self.m_Pid = pid
end

function NewConnection(fd)
	conlist[fd] = Connection:new(fd)
	Debug.fprint("new connction %s",fd)
end

function DelConnection(fd)
	local conn = conlist[fd]
	if conn then
		Debug.fprint("del connction %s",fd)
		if conn.m_Agent then
			Skynet.send(conn.m_Agent, "lua", "kick", conn.m_Pid)
		end
		conlist[fd] = nil
	end
end

function GetConnection(fd)
	return conlist[fd]
end

function CheckConnections()
	local now = GetSecond()
	for fd,conn in pairs(conlist) do
		if not conn.m_Agent and now - conn.m_StartTime > 5*60 then
			DelConnection(fd)
		end
	end
end
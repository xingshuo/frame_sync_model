local Class = require "lualib.class"
local Debug = require "lualib.debug"
local Skynet = require "lualib.local_skynet"
local TimerObj = import "lualib/object"
local Env = import "agent/env"
local Net = import "lualib/net"
local BCApi = import "broadcast/api"

local Player = Class("Player", "TimerObject")

function Player:__tostring()
	return string.format("[id:%s name:%s fd:%s]",self.m_ID,self.m_Name,self.m_FD)
end

function Player:init(id, mArgs)
	TimerObj.TimerObject.init(self)
	self.m_ID = id
	self.m_Name = mArgs.name
	self.m_FD = mArgs.fd
	self.m_GameModeID = mArgs.game_mode_id
	self.m_Color = mArgs.color
	self.m_PingSession = 0
	self.m_LastPingSession = 0
	self.m_PingTime = GetSecond()
	self.m_lRTTValues = {}
	self.m_RTT = 0
end

function Player:login()
	Env.set_player(self.m_ID, self)
	BCApi.register_fd(self.m_ID, self.m_FD)
	Debug.fprint("====player %s==login==",self)
	local ti = GGameConfig[self.m_GameModeID]["ping_interval"]
	self:AddTimer(ti//10, function () self:check_gs_ping() end, "ServerPing")
end

function Player:quit()
	Env.del_player(self.m_ID)
	BCApi.unregister_fd(self.m_ID)
	Debug.fprint("====player %s==quit===",self)
end

function Player:enterwar()
	local mt = Skynet.call("SCENE_MGR", "lua", "enter_player", self.m_GameModeID, self.m_ID, self:PackData())
	self.m_GameID = mt.game_id
	self.m_SceneAgent = mt.agent
end

function Player:leavewar()
	if self.m_SceneAgent then
		Skynet.send(self.m_SceneAgent, "lua", "leave_player", self.m_GameID, self.m_ID)
	end
end

function Player:client_ping(session)
	Debug.fprint("==%s=recv=cs ping resp=%s=gs pingsession %s lastpingsession %s=",self,session,self.m_PingSession,self.m_LastPingSession)
	if session ~= self.m_PingSession then
		return
	end
	if self.m_LastPingSession == self.m_PingSession then
		return
	end
	self.m_LastPingSession = self.m_PingSession
	self:calc_rtt()
	Net.send_to_player(self.m_ID, "gs2c_ping", {session = session, timestamp = GetCSecond(), is_resp = true})
end

function Player:check_gs_ping()
	if self.m_PingSession == self.m_LastPingSession then
		self.m_PingSession = self.m_PingSession + 1
		self.m_PingTime = GetCSecond()
		Net.send_to_player(self.m_ID, "gs2c_ping", {session = self.m_PingSession, timestamp = GetCSecond(), is_resp = false})
	else
		self:calc_rtt()
		Net.send_to_player(self.m_ID, "gs2c_ping", {session = self.m_PingSession, timestamp = GetCSecond(), is_resp = false}) --resend
	end
end

function Player:calc_rtt()
	if #self.m_lRTTValues > 0 then
		if self.m_lRTTValues[#self.m_lRTTValues][1] == self.m_PingSession then
			self.m_lRTTValues[#self.m_lRTTValues][2] = GetCSecond()-self.m_PingTime
		else
			table.insert(self.m_lRTTValues, {self.m_PingSession, GetCSecond()-self.m_PingTime})
		end
	else
		table.insert(self.m_lRTTValues, {self.m_PingSession, GetCSecond()-self.m_PingTime})
	end
	if #self.m_lRTTValues > 5 then
		table.remove(self.m_lRTTValues, 1)
	end
	self.m_RTT = table.list_avg_value2(self.m_lRTTValues, 2)
	-- print(string.format("----%s: rtt: %s---%s--",self.m_Name,self.m_RTT,table.tostring(self.m_lRTTValues)))
end

function Player:PackData()
	local mt = {}
	mt.name = self.m_Name
	mt.pid = self.m_ID
	mt.fd = self.m_FD
	mt.color = self.m_Color
	return mt
end

function Player:sync_ctrl(data)
	if self.m_SceneAgent then
		Skynet.send(self.m_SceneAgent, "lua", "sync_ctrl", self.m_GameID, self.m_ID, data)
	end
end

function NewPlayer(pid, mArgs)
	local pobj = Player:new(pid, mArgs)
	return pobj
end
--飞机大战
local Class = require "lualib.class"
local Skynet = require "lualib.local_skynet"
local Debug = require "lualib.debug"
local Socketdriver = require "socketdriver"
local Env = import "scene/env"
local TimerObj = import "lualib/object"
local FrameMgr = import "scene/frame_mgr"
local SceneApi = import "scene/api"
local Net = import "lualib/net"

FWPlayer = Class("FWPlayer")

function FWPlayer:init(oGame, mArgs)
    self.m_Name = mArgs.name
    self.m_Pid = mArgs.pid
    self.m_Fd = mArgs.fd
    self.m_Color = mArgs.color
    self.m_GameObj = oGame
    self.m_Pos = {x = math.random(1,800), z = math.random(550,600)}
    self.m_RTT = 0
    self.m_MaxRTT = -1
    self.m_MinRTT = 10000
    self.m_AvgRTT = 0
    self.m_SumRTT = 0
    self.m_RTTStartCS = GetCSecond()
end

function FWPlayer:sync_data(key, val)
    if key == "rtt" then
        local dt
        local ti = GetCSecond()
        if self.m_RTTLastCS then
            dt = ti - self.m_RTTLastCS
        else
            dt = ti - self.m_RTTStartCS
        end
        self.m_RTTLastCS = ti
        self.m_SumRTT = self.m_SumRTT + dt*self.m_RTT
        self.m_RTT = val
        if val > self.m_MaxRTT then
            self.m_MaxRTT = val
        end
        if val < self.m_MinRTT then
            self.m_MinRTT = val
        end
        dt = ti - self.m_RTTStartCS
        if dt > 0 then
            self.m_AvgRTT = math.floor(self.m_SumRTT/dt)
        end
    end
end

function FWPlayer:gs2c_rtt_data()
    if not self.m_RTTLastCS then
        return
    end
    self:sync_data("rtt", self.m_RTT)
    self.m_GameObj:Send2Player(self.m_Pid, "gs2c_rtt_data", {cur_rtt = self.m_RTT, avg_rtt = self.m_AvgRTT, min_rtt = self.m_MinRTT, max_rtt = self.m_MaxRTT})
end

function FWPlayer:release()
    self.m_GameObj = nil
end

FighterWar = Class("FighterWar", "TimerObject")
FighterWar.m_GameModeID = GAME_FIGHTER_WAR

function FighterWar:init(game_id, mArgs)
    TimerObj.TimerObject.init(self)
    self.m_GameID = game_id
    Env.AddGameObj(self.m_GameID, self)
    self.m_FrameMgr = FrameMgr.NewFrameMgr(self)
    self.m_Players = {}
    self.m_RndSeed = math.random(1,10000)
    self.m_FrameMgr:start()
    self:AddTimer(500, function () self:check_over() end, "CheckOver")
    self:AddTimer(100, function () self:sync_rtt() end, "SyncRtt")
    Debug.fprint("---game %s-%s start---",self.m_GameModeID,self.m_GameID)
end

function FighterWar:release()
    Env.DelGameObj(self.m_GameID)
    self.m_FrameMgr:release()
    self.m_FrameMgr = nil
end

function FighterWar:sync_rtt()
    for pid,pobj in pairs(self.m_Players) do
        pobj:gs2c_rtt_data()
    end
end

function FighterWar:check_over()
    if next(self.m_Players) ~= nil then
        return
    end
    self:game_over()
end

function FighterWar:game_over()
    local ret = skynet_call("SCENE_MGR", "game_over", self.m_GameModeID, self.m_GameID)
    Debug.fprint("---game %s-%s over %s---",self.m_GameModeID,self.m_GameID,ret)
    self:RemoveTimer("CheckOver")
end

function FighterWar:add_player(pid, mArgs)
    if not self.m_FSMInitTime then
        self.m_FSMInitTime = Skynet.now()
    end
    local oPlayer = FWPlayer:new(self, mArgs)
    self.m_Players[pid] = oPlayer
    local frame_cache = self.m_FrameMgr:frame_cache()
    local frame_cache_num = #frame_cache
    local param = {
        game_id = self.m_GameID,
        rndseed = self.m_RndSeed,
        timestamp = Skynet.now(),
        init_time = self.m_FSMInitTime,
        frame_cache_num = frame_cache_num,
    }
    self:Send2Player(pid, "gs2c_loginsuc", param)
    local iPiece = 500
    local iCnt = 1
    local i = 1
    local pkglist = {}
    while iCnt <= frame_cache_num do
        pkglist[i] = frame_cache[iCnt]
        if i >= iPiece then
            self:Send2Player(pid, "gs2c_frame_cache_data", {frame_cache = pkglist})
            pkglist = {}
            i = 0
        end
        i = i + 1
        iCnt = iCnt + 1
    end
    if #pkglist > 0 then
        self:Send2Player(pid, "gs2c_frame_cache_data", {frame_cache = pkglist})
    end
    local ctrl_data = {
        pid = pid,
        action = ACTION_ENTER,
        enter_info = {
            name = oPlayer.m_Name,
            color = oPlayer.m_Color,
            pos = oPlayer.m_Pos,
        },
    }
    self.m_FrameMgr:push_frame(ctrl_data)
end

function FighterWar:del_player(pid)
    local oPlayer = self.m_Players[pid]
    if oPlayer then
        self.m_Players[pid] = nil
        local ctrl_data = {
            pid = pid,
            action = ACTION_LEAVE,
        }
        self.m_FrameMgr:push_frame(ctrl_data)
        oPlayer:release()
    end
end

function FighterWar:get_player(pid)
    return self.m_Players[pid]
end

function FighterWar:sync_ctrl(pid, param)
   local oPlayer = self.m_Players[pid]
   if oPlayer then
        self.m_FrameMgr:push_frame(param.ctrl_data)
   end
end

function FighterWar:Send2Player(pid, proto, param)
    Net.send_to_player(pid, proto, param, self:get_bc())
end

function FighterWar:BC2Players(proto, param, except_tbl)
    except_tbl = except_tbl or {}
    local sendlist = {}
    for pid in pairs(self.m_Players) do
        if not except_tbl[pid] then
            table.insert(sendlist, pid)
        end
    end
    Net.send_to_list(sendlist, proto, param, self:get_bc())
end

function FighterWar:get_bc()
    return SceneApi.get_scene_broadcast(self.m_GameID)
end

function FighterWar:kick_player(pid)
    local oPlayer = self.m_Players[pid]
    if oPlayer then
        Socketdriver.close(oPlayer.m_Fd)
    end
end

function NewGame(game_id, mArgs)
    return FighterWar:new(game_id, mArgs)
end
local Class = require "lualib.class"
local Skynet = require "lualib.local_skynet"
local TimerObj = import "lualib/object"

FrameMgr = Class("FrameMgr", "TimerObject")

function FrameMgr:init(gameobj)
    TimerObj.TimerObject.init(self)
    self.m_CtrlDataQueue = {}
    self.m_FrameCacheQueue = {}
    self.m_CurFrameNo = 1
    self.m_GameObj = gameobj
end

function FrameMgr:start()
    local ti = math.floor(100/GGameConfig[self.m_GameObj.m_GameModeID]["frame_rate"])
    self:AddTimer(ti, function () self:frame_skip() end, "FrameSkip")
end

function FrameMgr:frame_skip()
    if #self.m_CtrlDataQueue > 0 then
        local param = {
            frame_number = self.m_CurFrameNo,
            ctrl_data = self.m_CtrlDataQueue,
            timestamp = Skynet.now(),
        }
        self.m_GameObj:BC2Players("gs2c_frame_data", {frame_data = param})
        table.insert(self.m_FrameCacheQueue, param)
        self.m_CtrlDataQueue = {}
    end
    self.m_CurFrameNo = self.m_CurFrameNo + 1
end

function FrameMgr:push_frame(ctrl_data)
    table.insert(self.m_CtrlDataQueue, ctrl_data)
end

function FrameMgr:frame_cache()
    return self.m_FrameCacheQueue
end

function FrameMgr:release()
    self.m_CtrlDataQueue = {}
    self.m_FrameCacheQueue = {}
    self.m_GameObj = nil
end



function NewFrameMgr(gameobj)
    return FrameMgr:new(gameobj)
end
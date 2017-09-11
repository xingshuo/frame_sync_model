local Skynet = require "lualib.local_skynet"
local Class = require "lualib.class"

TimerObject = Class("TimerObject")

function TimerObject:init()
    self.m_ID = NewServiceUniqID("Object")
    self.m_TimerList = {}
    self.m_TimerNo = 0
    self.m_TimerDefaultHdl = 0
end

function TimerObject:AddTimer(ti, func, handle, count)
    assert(ti >= 0)
    count = count or 0
    count = (count>0) and count or true
    if handle == nil then
        handle = self.m_TimerDefaultHdl
        self.m_TimerDefaultHdl = self.m_TimerDefaultHdl + 1
    end
    local tno = self.m_TimerNo
    self.m_TimerNo = self.m_TimerNo + 1
    self.m_TimerList[handle] = {tno, count}
    local f
    f = function ()
        if not self.m_TimerList[handle] then
            return
        end
        if self.m_TimerList[handle][1] ~= tno then
            return
        end
        if self.m_TimerList[handle][2] == true then
            Skynet.timeout(ti, f)
        else
            self.m_TimerList[handle][2] = self.m_TimerList[handle][2] - 1
            if self.m_TimerList[handle][2] > 0 then
                Skynet.timeout(ti, f)
            else
                self.m_TimerList[handle] = nil
            end
        end
        func()
    end
    Skynet.timeout(ti, f)
    return handle
end

function TimerObject:RemoveTimer(handle)
    self.m_TimerList[handle] = nil
end

function TimerObject:RemoveAllTimers()
    self.m_TimerList = {}
end

function TimerObject:FindTimer(handle)
    return self.m_TimerList[handle]
end
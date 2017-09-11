local Skynet = require "lualib.local_skynet"

GAME_FIGHTER_WAR = 1001

GGameConfig = {
    [GAME_FIGHTER_WAR] = {
        frame_rate = 50, --times of per second
        ping_interval = 1000, --ms
    },
}

ACTION_ENTER = 1
ACTION_LEAVE = 2
ACTION_ATTACK = 3
ACTION_MOVE = 4

local ostime = os.time
function GetSecond()
	return ostime()
end

function GetCSecond()
    return Skynet.now()
end

local mathrand = math.random 
function RandomList(lst)
	if #lst == 0 then
		return nil
	end
	return lst[mathrand(1,#lst)]
end

function IsValueInList(value, list)
    for _,v in ipairs(list) do
        if value == v then
            return true
        end
    end
    return false
end

-- ti: 执行间隔，单位百分之一秒(10ms)
-- count：0表示无限次数, >0 有限次
-- handle : 自定义(int,string等常量key)或系统分配
local timer_no = 0
local timer_list = {}
local timer_default_hdl = 0
function AddTimer(ti, func, handle, count)
    assert(ti >= 0)
    count = count or 0
    count = (count>0) and count or true
    if handle == nil then
        handle = timer_default_hdl
        timer_default_hdl = timer_default_hdl + 1
    end
    local tno = timer_no
    timer_no = timer_no + 1
    timer_list[handle] = {tno, count}
    local f
    f = function ()
        if not timer_list[handle] then
            return
        end
        if timer_list[handle][1] ~= tno then
            return
        end
        if timer_list[handle][2] == true then
            Skynet.timeout(ti, f)
        else
            timer_list[handle][2] = timer_list[handle][2] - 1
            if timer_list[handle][2] > 0 then
                Skynet.timeout(ti, f)
            else
                timer_list[handle] = nil
            end
        end
        func()
    end
    Skynet.timeout(ti, f)
    return handle
end

function RemoveTimer(handle)
    timer_list[handle] = nil
end

function RemoveAllTimers()
    timer_list = {}
end

function FindTimer(handle)
    return timer_list[handle]
end

local UniqIDList = {}
function NewServiceUniqID(sType)
    if not UniqIDList[sType] then
        UniqIDList[sType] = 0
    end
    UniqIDList[sType] = UniqIDList[sType] + 1
    return UniqIDList[sType]
end
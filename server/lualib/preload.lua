math.randomseed(os.clock()*1000000)
require "reload"
require "globaldefines"

table.keylist = function (tbl)
    local lst = {}
    for k,_ in pairs(tbl) do
        table.insert(lst, k)
    end
    return lst
end

table.valuelist = function (tbl)
    local lst = {}
    for _,v in pairs(tbl) do
        table.insert(lst, v)
    end
    return lst
end

table.keydict = function ( tbl, default_val )
    if default_val == nil then
        default_val = 1
    end
    local dict = {}
    for k,_ in pairs(tbl) do
        dict[k] = default_val
    end
    return dict
end

table.valuedict = function ( tbl, default_val)
    if default_val == nil then
        default_val = 1
    end
    local dict = {}
    for _,v in pairs(tbl) do
        dict[v] = default_val
    end
    return dict
end

table.getlen = function ( tbl )
    local n = 0
    for k,v in pairs(tbl) do
        n = n + 1
    end
    return n
end

table.tostring = function ( tbl )
    local Utils = require "lualib.utils"
    return Utils.table_str(tbl)
end

table.list_avg_value = function (lst)
    if #lst == 0 then
        return 0
    end
    local sum = 0
    for i=1,#lst do
        sum = sum + lst[i]
    end

    return sum/#lst
end

table.list_avg_value2 = function (lst, pos)
    if #lst == 0 then
        return 0
    end
    local sum = 0
    for i=1,#lst do
        sum = sum + lst[i][pos]
    end

    return sum/#lst
end

table.list_sum_value = function (lst)
    local sum = 0
    for i=1,#lst do
        sum = sum + lst[i]
    end

    return sum
end

-- local skynet = require "local_skynet"
--弱引用
--[[eg:
    function CXXX:AddWeakObject(skey, oReal)
        self.m_Objects[skey] = ShadowObject(oReal)
    end

    function CXXX:GetRealObject(skey)
        return self.m_Objects[skey]:Get()
    end
]]
local function ShadowObjectGet(oWeak)
    return oWeak[1]
end

function ShadowObject(oReal)
    local oWeak = setmetatable({}, {__mode = "v"})
    oWeak[1] = oReal
    oWeak.Get = ShadowObjectGet --防止闭包和oReal一起被回收
    return oWeak
end
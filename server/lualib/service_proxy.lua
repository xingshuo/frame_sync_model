local Skynet = require "lualib.local_skynet"

local M = {}
M.serverid = 0

local function bind_name(info)
    info.realname = info.sname
end

local CallMeta = {}
function CallMeta.__index(t, k)
    local info = t.info
    if not info.realname then
        bind_name(info)
    end
    local call_func = function(...)
        return Skynet.call(info.realname, "lua", k, ...)
    end
    t[k] = call_func
    return call_func
end

local SendMeta = {}
function SendMeta.__index(t, k)
    local info = t.info
    if not info.realname then
        bind_name(info)
    end
    local send_func = function(...)
        return Skynet.send(info.realname, "lua", k, ...)
    end
    t[k] = send_func
    return send_func
end

local function new(service_name, raw)
    local info = {}
    info.sname = service_name
    info.raw = raw
    if raw then
        info.realname = service_name
    end
    local proxy = {}
    proxy.req = setmetatable({info=info}, CallMeta)
    proxy.post = setmetatable({info=info}, SendMeta)
    return proxy
end

local function _get(sname, raw)
    if not M[sname] then
        M[sname] = new(sname, raw)
    end
    return M[sname]
end

function M.get(sname)
    return _get(sname, false)
end

function M.rawget(sname)
    return _get(sname, true)
end

return M

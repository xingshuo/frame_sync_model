local skynet = require "local_skynet"
local netpack = require "netpack"
local socketdriver = require "socketdriver"
local Utils = require "lualib.utils"
local Debug = require "lualib.debug"
local handlecon = import "lualib/connection"
local socket    -- listen socket
local queue     -- message queue
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })

function CMD.open(source, conf)
    local address = conf.address or "0.0.0.0"
    local port = assert(conf.port)
    skynet.error(string.format("====Listen on %s:%d start====", address, port))
    socket = socketdriver.listen(address, port)
    socketdriver.start(socket)
    skynet.error(string.format("====Listen on %s:%d %d end====", address, port,socket))
end

function CMD.close()
    assert(socket)
    socketdriver.close(socket)
end

function CMD.loginsuc(source, fd, mArgs)
    local conn = handlecon.GetConnection(fd)
    if not conn then
        print("login error:no conn",fd,Utils.table_str(mArgs))
        return
    end
    if conn.m_Agent then
        print("login error:re login",fd,Utils.table_str(mArgs))
        return
    end
    conn:loginsuc(mArgs.agent, mArgs.pid)
    skynet.send(conn.m_Agent, "lua", "start", mArgs.pid, mArgs)
    print("login suc",fd,Utils.table_str(mArgs))
end

local MSG = {}

local function dispatch_msg(fd, msg, sz)
    local conn = handlecon.GetConnection(fd)
    if not conn then
        return
    end
    if conn.m_Agent then
        skynet.send(conn.m_Agent, "lua", "Unpack", conn.m_Pid, msg, sz)
    else
        skynet.send("GAMELOGIN", "lua", "UpackData", fd, msg, sz)
    end
end

MSG.data = dispatch_msg

local function dispatch_queue()
    local fd, msg, sz = netpack.pop(queue)
    if fd then
        -- may dispatch even the handler.message blocked
        -- If the handler.message never block, the queue should be empty, so only fork once and then exit.
        skynet.fork(dispatch_queue)
        dispatch_msg(fd, msg, sz)

        for fd, msg, sz in netpack.pop, queue do
            dispatch_msg(fd, msg, sz)
        end
    end
end

MSG.more = dispatch_queue

function MSG.open(fd, msg)
    socketdriver.start(fd)
    socketdriver.nodelay(fd)
    handlecon.NewConnection(fd)
end

function MSG.close(fd)
    handlecon.DelConnection(fd)
end

function MSG.error(fd, msg)
    handlecon.DelConnection(fd)
end

skynet.register_protocol {
    name = "socket",
    id = skynet.PTYPE_SOCKET,   -- PTYPE_SOCKET = 6
    unpack = function ( msg, sz )
        return netpack.filter( queue, msg, sz)
    end,
    dispatch = function (_, _, q, type, ...)
        queue = q
        if type then
            MSG[type](...)
        end
    end
}

skynet.start(function()
    AddTimer(5*60*100, function () handlecon.CheckConnections() end, "CheckConnections")
    skynet.dispatch("lua", function (_, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(address, ...)))
        end
    end)
    skynet.register("GAMEGATE")
    Debug.print("====service GAMEGATE start====")
end)
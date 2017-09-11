local socketdriver = require "socketdriver"
local Skynet = require "lualib.local_skynet"
local Utils = require "lualib.utils"
local Proxy = require "lualib.service_proxy"
local Debug = require "lualib.debug"
local Net = import "lualib/net"
local AgentApi = import "agent/api"

command = {}

function command.UpackData(fd, msg, sz)
    local proto,param = Net.unpack(msg, sz)
    if proto == "c2gs_login" then
        local pid = param.pid
        print("c2gs_login",pid)
        local name = Utils.random_name()
        local color = Utils.random_color()
        local agent = AgentApi.get_user_agent(pid)
        local mArgs = {pid = pid, agent = agent, name = name, color = color, fd = fd, game_mode_id = GAME_FIGHTER_WAR}
        Skynet.send("GAMEGATE", "lua", "loginsuc", fd, mArgs)
    end
end
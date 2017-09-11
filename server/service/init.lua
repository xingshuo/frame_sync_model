local Skynet = require "lualib.local_skynet"
local BroadcastApi = import "broadcast/api"
local AgentApi = import "agent/api"
local SceneApi = import "scene/api"
local SprotoEnv = require "lualib.sproto_env"


function game_init()
    print("===========game_init begin=========")
    local sproto_path = assert(Skynet.getenv("sproto"), "no sproto path")
    SprotoEnv.init(sproto_path)
    BroadcastApi.init_broadcast_services()
    AgentApi.init_agent_services()
    local login_port = Skynet.getenv("login_port")
    login_port = tonumber(login_port)
    local gate = Skynet.newservice("gamegate")
    Skynet.send(gate, "lua", "open", {port = login_port})
    Skynet.newservice("gamelogin")
    SceneApi.init_scene_services()
    Skynet.newservice("scene_mgr")
    local debug_console_port = tonumber(Skynet.getenv("debug_console_port"))
    if debug_console_port then
        Skynet.newservice("debug_console", debug_console_port)
    end
    print("===========game_init end=========")
end

Skynet.start(function ()
    game_init()
    Skynet.exit()
end)
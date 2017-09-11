local Class = require "lualib.class"
local Skynet = require "lualib.local_skynet"
local SceneApi = import "scene/api"

game_mgr_list = game_mgr_list or {}

function get_game_mgr(game_mode_id)
    if not game_mgr_list[game_mode_id] then
        game_mgr_list[game_mode_id] = GameMgr:new(game_mode_id)
    end
    return game_mgr_list[game_mode_id]
end

GameMgr = Class("GameMgr")

function GameMgr:init(game_mode_id)
    self.m_GameModeID = game_mode_id
    self.m_SceneProxyList = {}
end

function GameMgr:new_proxy()
    local game_id = NewServiceUniqID("GAMEID")
    local agent = SceneApi.get_scene_service(game_id)
    local mArgs = {
        game_mode_id = self.m_GameModeID,
    }
    local game_id = Skynet.call(agent, "lua", "new_game", game_id, mArgs)
    assert(game_id, "new game error")
    local oProxy = {
        ["playercnt"] = 0,
        ["game_id"] = game_id,
        ["agent"] = agent,
    }
    table.insert(self.m_SceneProxyList, oProxy)
    return oProxy
end

function GameMgr:get_proxy()
    return self.m_SceneProxyList[1]
end

function GameMgr:pop_proxy()
    table.remove(self.m_SceneProxyList, 1)
end

command = {}

function command.enter_player(game_mode_id, pid, mArgs)
    local mobj = get_game_mgr(game_mode_id)
    local pobj = mobj:get_proxy()
    if not pobj then
        pobj = mobj:new_proxy()
    end
    pobj.playercnt = pobj.playercnt + 1
    Skynet.send(pobj.agent, "lua", "enter_player", pobj.game_id, pid, mArgs)
    if pobj.playercnt >= 5 then
        mobj:pop_proxy()
    end
    return pobj
end
local Debug = require "lualib.debug"
local FighterGame = import "scene/fighter_war"
local Env = import "scene/env"

command = {}

function command.new_game(game_id, mArgs)
    if mArgs.game_mode_id == GAME_FIGHTER_WAR then
        local gobj = FighterGame.NewGame(game_id, mArgs)
        return gobj.m_GameID
    end
end

function command.enter_player(game_id, pid, mArgs)
    local gobj = Env.GetGameObj(game_id)
    if gobj then
        gobj:add_player(pid, mArgs)
    end
end

function command.leave_player(game_id, pid)
    local gobj = Env.GetGameObj(game_id)
    if gobj then
        gobj:del_player(pid)
    end
end

function command.sync_ctrl(game_id, pid, data)
    local gobj = Env.GetGameObj(game_id)
    if gobj then
        gobj:sync_ctrl(pid, data)
    end
end

function command.sync_data(game_id, pid, mt)
    local gobj = Env.GetGameObj(game_id)
    if gobj then
        local pobj = gobj:get_player(pid)
        if pobj then
            for k,v in pairs(mt) do
                pobj:sync_data(k, v)
            end
        end
    end
end

function command.c2gs_rtt_data(game_id, pid)
    local gobj = Env.GetGameObj(game_id)
    if gobj then
        local pobj = gobj:get_player(pid)
        if pobj then
            Debug.fprint("===cs_rtt_data:[%s,%s,%s]===gs_rtt_data:[%s,%s,%s]==",
                data["min_rtt"],data["avg_rtt"],data["max_rtt"],pobj.m_MinRTT,pobj.m_AvgRTT,pobj.m_MaxRTT)
        end
    end
end
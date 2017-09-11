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
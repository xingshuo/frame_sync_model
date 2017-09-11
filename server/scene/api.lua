local skynet = require "local_skynet"

function get_scene_service(game_id)
    local iSceneCnt = skynet.getenv("SCENESERVICE_CNT")
    local n = game_id % iSceneCnt
    if n == 0 then
        n = iSceneCnt
    end
    n = math.floor(n)
    return "SCENE" .. n
end

function get_scene_broadcast(game_id)
    local iSceneBCNum = skynet.getenv("SCENE_BC_CNT")
    local n = game_id % iSceneBCNum
    if n == 0 then
        n = iSceneBCNum
    end
    n = math.floor(n)
    return "SCENE_BC" .. n
end

function init_scene_services()
    local iSceneCnt = skynet.getenv("SCENESERVICE_CNT")
    for i=1,iSceneCnt do
        skynet.newservice("scene", i)
    end
end
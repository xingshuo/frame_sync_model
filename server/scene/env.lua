
gameobj_list = gameobj_list or {}

function AddGameObj(gid, gobj)
    gameobj_list[gid] = gobj
end

function GetGameObj(gid)
    return gameobj_list[gid]
end

function DelGameObj(gid)
    gameobj_list[gid] = nil
end
playerlist = playerlist or {}

function set_player(pid, pobj)
	playerlist[pid] = pobj
end

function get_player(pid)
	return playerlist[pid]
end

function del_player(pid)
	playerlist[pid] = nil
end
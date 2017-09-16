local utils = require "lualib.utils"
local env = import "agent/env"

function Analysis(pid, proto, param)
	local pobj = env.get_player(pid)
	if proto == "c2gs_ping" then
		if pobj then
			pobj:client_ping(param.session)
		end
	elseif proto == "c2gs_ctrl_data" then
		if pobj then
			pobj:sync_ctrl(param)
		end
	elseif proto == "c2gs_rtt_data" then
		if pobj then
			skynet_send(pobj.m_SceneAgent, "c2gs_rtt_data", pobj.m_GameID, pobj.m_ID, param)
		end
	end
end
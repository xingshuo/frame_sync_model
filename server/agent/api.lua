local skynet = require "local_skynet"

function get_user_agent( pid )
	local iAgentCnt = skynet.getenv("AGENT_CNT")
	local n = pid % iAgentCnt
	if n == 0 then
		n = iAgentCnt
	end
	n = math.floor(n)
	return "AGENT" .. n
end

function init_agent_services()
	local iAgentCnt = skynet.getenv("AGENT_CNT")
	for i=1,iAgentCnt do
		skynet.newservice("agent", i)
	end
end
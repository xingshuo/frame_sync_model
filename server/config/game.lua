-- 登录端口
login_port = 9100

-- debug_console端口
debug_console_port = 8400

-- 线程数
thread = 4

-- 启动路径
start = "init"

-- service位置
luaservice = "./server/service/?.lua;" .. "./service/?.lua"

-- 搜索路径
lua_path = "./server/?.lua;" .. "./server/lualib/?.lua;" .. "./lualib/?.lua"
lua_cpath = "../build/luaclib/?.so;" .. "./luaclib/?.so;" .. "./cservice/?.so"
-- 提前preload一些东西
preload = "./server/lualib/preload.lua"

-- 节点地址
address = "127.0.0.1:2528"

-- master地址
master = "127.0.0.1:2017"

-- master节点专有
standalone = "0.0.0.0:2017"

-- 协议
sproto = "../build"

AGENT_CNT = 2
SCENESERVICE_CNT = 2
SCENE_BC_CNT = 2

SERVERID = 1
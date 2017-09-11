package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/?.lua"
local socket = require "socket"

local ip = "127.0.0.1"
local port = 8300
for k,v in pairs(socket) do
	print("k,v ",k,v)
end
local fd = socket.open(ip, port)
assert(fd, "err socket !")

socket.write(fd, "aaaaaaa")
local str = socket.read(fd)
print("---socket read str---",str)
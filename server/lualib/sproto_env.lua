local SprotoLoader = require 'sprotoloader'

local M = {}

local SPROTO_INDEX = 1

M.BASE_PACKAGE = "BasePackage"

function M.init(sproto_path)
    local fpath = sproto_path .. "/" .. 'sproto.spb'
    local fp = assert(io.open(fpath, "rb"), "Can't open sproto file")
    local bin = fp:read "*all"
    SprotoLoader.save(bin, SPROTO_INDEX)
end

function M.load()
    return SprotoLoader.load(SPROTO_INDEX)
end

return M

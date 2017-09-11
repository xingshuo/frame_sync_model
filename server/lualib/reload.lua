
local Modules = {}

function import(modname, dir)
    dir = dir or "server"
    modname = dir.."/"..modname
    local oldModule = Modules[modname]
    if oldModule then
        return oldModule
    end
    local pathname = modname .. ".lua"
    local newModule = {}
    Modules[modname] = newModule
    setmetatable(newModule, {__index = _G})
    local func = loadfile(pathname, "bt", newModule)
    func()
    return newModule
end

function importall(env, modname, dir)
    local mod = import(modname, dir)
    for k,v in pairs(mod) do
        env[k] = mod[k]
    end
    return mod
end

function reload(modname, dir)
    dir = dir or "server"
    modname = dir.."/"..modname
    local pathname = modname .. ".lua"
    local oldModule = Modules[modname]
    if not oldModule then
        return
    end
    local oldCache = {}
    for k,v in pairs(oldModule) do
        if type(v) == 'table' then
            oldCache[k] = v
        end
    end
    local newModule = oldModule
    local func = loadfile(pathname, "bt", newModule)
    func()
    for k,v in pairs(oldCache) do
        if type(v) == 'table' and v ~= newModule[k] then
            local mt = getmetatable(newModule[k])
            if mt then
                setmetatable(v, mt)
            end
            for newkey,newvalue in pairs(newModule[k]) do
                v[newkey] = newvalue
            end
            newModule[k] = v
        end
    end
    return newModule
end

function getmodes()
    return Modules
end
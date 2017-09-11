local Utils = require "lualib.utils"

local sformat = string.format 

local M = {}

function M.print( ... )
    print(...)
end

function M.fprint(fmat, ...)
    local s = sformat(fmat, ...)
    print(s)
end

function M.error( ... )
    local n = select("#",...)
    local lst = {}
    for i=1,n do
        local v = select(i, ...)
        if type(v) == "table" then
            table.insert(lst, Utils.table_str(v))
        else
            table.insert(lst, tostring(v))
        end
    end
    local s = table.concat(lst," ")
    local str = sformat("\27[31m%s\27[0m",s)
    print(str)
end

function M.ferror(fmat, ...)
    local s = sformat(fmat, ...)
    local str = sformat("\27[31m%s\27[0m",s)
    print(str)
end

function M.warning( ... )
    local n = select("#",...)
    local lst = {}
    for i=1,n do
        local v = select(i, ...)
        if type(v) == "table" then
            table.insert(lst, Utils.table_str(v))
        else
            table.insert(lst, tostring(v))
        end
    end
    local s = table.concat(lst," ")
    local str = sformat("\27[33m%s\27[0m",s)
    print(str)
end

function M.fwarning(fmat, ...)
    local s = sformat(fmat, ...)
    local str = sformat("\27[33m%s\27[0m",s)
    print(str)
end

function M.log_file( ... )
    -- body
end

return M
local M = {}

function M.table_str(mt, max_floor, cur_floor)
    cur_floor = cur_floor or 1
    max_floor = max_floor or 5
    if max_floor and cur_floor > max_floor then
        return tostring(mt)
    end
    local str
    if cur_floor == 1 then
        str = string.format("%s{\n",string.rep("--",max_floor))
    else
        str = "{\n"
    end
    for k,v in pairs(mt) do
        if type(v) == 'table' then
            v = M.table_str(v, max_floor, cur_floor+1)
        else
            if type(v) == 'string' then
                v = "'" .. v .. "'"
            end
            v = tostring(v) .. "\n"
        end
        str = str .. string.format("%s[%s] = %s",string.rep("--",cur_floor),k,v)
    end
    str = str .. string.format("%s}\n",string.rep("--",cur_floor-1))
    return str
end

function M.table_len(mt)
    local len = 0
    for k,v in pairs(mt) do
        len = len + 1
    end
    return len
end

local function split(str, sep)
    local s, e = str:find(sep)
    if s then
        return str:sub(0, s - 1), str:sub(e + 1)
    end
    return str
end

function M.split_all(str, sep)
    local res = {}
    while true do
        local lhs, rhs = split(str, sep)
        table.insert(res, lhs)
        if not rhs then
            break
        end
        str = rhs
    end
    return res
end

local first_names = {
    "李", "王", "张", "刘", "陈", "杨", "赵", "黄", "周", "吴",
    "司徒","西门","欧阳","司马"
}
local last_names = {
    "秀娟", "英华", "慧", "巧", "美娜", "静", "淑惠", "翠珠",
    "辰逸","浩宇","瑾瑜","瑾瑜","天佑","大刀","小帅","伟","帅","进","振东"
}
function M.random_name()
    return RandomList(first_names) .. RandomList(last_names)
end

function M.random_color()
    return {
        r = math.random(1, 254),
        g = math.random(1, 254), 
        b = math.random(1, 254)
    }
end

function M.unit_dir(dir)
    local len = math.sqrt(dir.x^2 + dir.z^2)
    if len == 0 then
        return {x = 0, z = 0}
    else
        return {x = dir.x/len, z = dir.z/len}
    end
end

function M.vector_rotate(dir, rotate_rad)
    local cos_value = math.cos(rotate_rad)
    local sin_value = math.sin(rotate_rad)
    return {
        x = dir.x*cos_value - dir.z*sin_value,
        z = dir.z*cos_value + dir.x*sin_value,
    }
end

return M
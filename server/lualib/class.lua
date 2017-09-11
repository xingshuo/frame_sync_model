local sformat = string.format

local class_pool = {}
setmetatable(class_pool, {__mode = "kv"})

local function get_class(class_type)
    assert(class_pool[class_type], sformat("class_type<%s> not exists", class_type))
    return class_pool[class_type]
end

local function add_class(class_type, class_object)
    if class_pool[class_type] then
        print ("repeat define the same class "..class_type)
        return
    end
    class_pool[class_type] = class_object
end

local function index(self, k)
    local meta = getmetatable(self)
    local value = meta[k]
    if value then
        return value
    end
end

-- 所有类的默认tostring
local function default_tostring(o)
    return sformat("[ctype:%s]", o.__class_type)
end

-- 所有类的基类
local _G_class_meta = {}
_G_class_meta.__index = _G_class_meta
class_pool["class_meta"] = _G_class_meta

-- 创建obj接口
function _G_class_meta:new(...)
    local o = {}
    setmetatable(o, self)
    if o.init then
        o:init(...)
    end
    return o
end

-- 定义一个class
local function define_class(class_type, parent_type)
    local class = {}
    parent_type = parent_type or "class_meta"
    local parent_obj = get_class(parent_type)
    class.__parent_type = parent_type
    class.__class_type = class_type
    class.__tostring = default_tostring -- 这个方法只找一层metatable，不能继承
    class.__index = index
    add_class(class_type, class)
    return setmetatable(class, parent_obj)
end

return define_class
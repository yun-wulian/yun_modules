-- yun_modules/utils.lua
-- yun_modules系统的工具函数

local utils = {}

-- 将表转换为带缩进的字符串
---@param tbl table 表
---@param indent string 缩进
---@return string 字符串表示
function utils.tableToString(tbl, indent)
    local indent = indent or ""
    local result = {}
    if tbl == nil then return "nil" end
    
    -- 防止循环引用
    local seen = {}
    local function _tableToString(t, ind, depth)
        if depth > 10 then  -- 防止无限递归
            table.insert(result, ind .. "... (depth limit reached)\n")
            return
        end
        
        if seen[t] then
            table.insert(result, ind .. "... (circular reference)\n")
            return
        end
        seen[t] = true
        
        for key, value in pairs(t) do
            table.insert(result, string.format("%s%s: ", ind, tostring(key)))
            if type(value) == "table" then
                table.insert(result, "\n")
                _tableToString(value, ind .. "  ", depth + 1)
            else
                table.insert(result, tostring(value) .. "\n")
            end
        end
        seen[t] = nil
    end
    
    _tableToString(tbl, indent, 0)
    return table.concat(result)
end

-- 使用ImGui打印表
---@param tbl table 表
function utils.printTableWithImGui(tbl)
    local str = utils.tableToString(tbl)
    for line in string.gmatch(str, "[^\r\n]+") do
        imgui.text(line)
    end
end

-- 使用re.msg打印表
---@param tbl table 表
function utils.printTableWithMsg(tbl)
    local str = utils.tableToString(tbl)
    for line in string.gmatch(str, "[^\r\n]+") do
        re.msg(line)
    end
end

-- 深拷贝表
---@param orig table 原始表
---@return table 拷贝的表
function utils.deepCopy(orig)
    local copy
    if type(orig) == "table" then
        -- 防止循环引用
        local seen = {}
        local function _deepCopy(o)
            -- 如果不是table，直接返回原值
            if type(o) ~= "table" then
                return o
            end

            if seen[o] then
                return seen[o]
            end

            local c = {}
            seen[o] = c

            for k, v in pairs(o) do
                c[_deepCopy(k)] = _deepCopy(v)
            end

            local mt = getmetatable(o)
            if mt then
                setmetatable(c, _deepCopy(mt))
            end

            return c
        end

        copy = _deepCopy(orig)
    else
        copy = orig
    end
    return copy
end

-- 检查帧是否在范围内
---@param frame number 帧
---@param range table 范围表
---@return boolean 是否在范围内
function utils.isFrameInRange(frame, range)
    return frame >= range[1] and frame < range[2]
end

-- 获取游戏运行时间（秒）
---@return number 游戏运行时间
function utils.get_game_time()
    local appType = sdk.find_type_definition("via.Application")
    if not appType then return 0 end

    local get_UpTimeSecond = appType:get_method("get_UpTimeSecond")
    if not get_UpTimeSecond then return 0 end

    local result = get_UpTimeSecond:call(nil)
    return result or 0
end

-- ============================================================================
-- 距离计算函数
-- ============================================================================

-- 获取两个实体之间的距离
---@param entity1 userdata 实体1（需要有get_GameObject方法）
---@param entity2 userdata 实体2（需要有get_GameObject方法）
---@return number 距离（如果无法计算则返回math.huge）
function utils.get_distance_between(entity1, entity2)
    if not entity1 or not entity2 then return math.huge end

    local go1 = entity1:get_GameObject()
    local go2 = entity2:get_GameObject()
    if not go1 or not go2 then return math.huge end

    local tf1 = go1:get_Transform()
    local tf2 = go2:get_Transform()
    if not tf1 or not tf2 then return math.huge end

    local pos1 = tf1:get_Position()
    local pos2 = tf2:get_Position()
    if not pos1 or not pos2 then return math.huge end

    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- 获取实体的世界坐标
---@param entity userdata 实体（需要有get_GameObject方法）
---@return userdata|nil 位置向量，失败返回nil
function utils.get_entity_position(entity)
    if not entity then return nil end

    local go = entity:get_GameObject()
    if not go then return nil end

    local tf = go:get_Transform()
    if not tf then return nil end

    return tf:get_Position()
end

return utils

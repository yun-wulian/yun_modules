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

return utils

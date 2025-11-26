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
    for key, value in pairs(tbl) do
        table.insert(result, string.format("%s%s: ", indent, tostring(key)))
        if type(value) == "table" then
            table.insert(result, "\n" .. utils.tableToString(value, indent .. "  "))
        else
            table.insert(result, tostring(value) .. "\n")
        end
    end
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
        copy = {}
        for k, v in next, orig, nil do
            copy[utils.deepCopy(k)] = utils.deepCopy(v)
        end
        setmetatable(copy, utils.deepCopy(getmetatable(orig)))
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

return utils
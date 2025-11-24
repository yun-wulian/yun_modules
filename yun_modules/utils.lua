-- yun_modules/utils.lua
-- Utility functions for the yun_modules system

local utils = {}

-- Convert table to string with indentation
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

-- Print table using ImGui
function utils.printTableWithImGui(tbl)
    local str = utils.tableToString(tbl)
    for line in string.gmatch(str, "[^\r\n]+") do
        imgui.text(line)
    end
end

-- Print table using re.msg
function utils.printTableWithMsg(tbl)
    local str = utils.tableToString(tbl)
    for line in string.gmatch(str, "[^\r\n]+") do
        re.msg(line)
    end
end

-- Deep copy a table
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

-- Check if frame is in range
function utils.isFrameInRange(frame, range)
    return frame >= range[1] and frame < range[2]
end

return utils

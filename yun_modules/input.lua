-- yun_modules/input.lua
-- 输入检测函数（摇杆和按钮）

local input = {}
local core = require("yunwulian.yun_modules.core")

-- 检查左摇杆是否被推动
---@return boolean 是否推动摇杆
function input.is_push_lstick()
    local is_push_lstick = false
    for i = 0, 7 do
        is_push_lstick = core.master_player:call('get_RefPlayerInput'):call("checkAnaLever", i)
        if is_push_lstick then return true end
    end
    return false
end

-- 将角色转向摇杆方向，带角度范围限制
---@param range number 转向范围
function input.turn_to_lstick_dir(range)
    local is_push_lstick = false
    for i = 0, 7 do
        is_push_lstick = core.master_player:call('get_RefPlayerInput'):call("checkAnaLever", i)
        if is_push_lstick then break end
    end
    if not is_push_lstick then return end
    local input_angle = core.master_player:call('get_RefPlayerInput'):call("getHormdirLstick")
    local player_angle = core.master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")
    range = math.rad(range)

    if range >= 180.0 then
        core.master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", input_angle)
        return
    end

    local delta_angle_sin = math.sin(input_angle - player_angle)
    local delta_angle_cos = math.cos(input_angle - player_angle)

    if delta_angle_cos > math.cos(range) then
        core.master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", input_angle)
    else
        local left_target, right_target
        left_target = player_angle + range
        right_target = player_angle - range
        if left_target > math.pi then
            left_target = left_target - 2 * math.pi
        elseif right_target < -math.pi then
            right_target = 2 * math.pi - right_target
        end
        if delta_angle_sin > 0 then
            core.master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", left_target)
        else
            core.master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", right_target)
        end
    end
end

-- 检查摇杆方向（基于相机，8方向）
---@param direction number 方向
---@return boolean 是否匹配方向
function input.check_lstick_dir(direction)
    if not core.master_player then return false end
    if core.master_player:call('get_RefPlayerInput'):call("checkAnaLever", direction) then
        return true
    else
        return false
    end
end

-- 检查摇杆方向（基于玩家，8方向）
---@param direction number 方向
---@return boolean 是否匹配方向
function input.check_lstick_dir_for_player(direction)
    if not input.is_push_lstick() then return false end
    local player_angle = core.master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")
    local input_angle = core.master_player:call('get_RefPlayerInput'):call("getHormdirLstick")

    local delta_angle_sin = math.sin(input_angle - player_angle)
    local delta_angle_cos = math.cos(input_angle - player_angle)

    if direction == core.direction.Down then
        if delta_angle_sin > math.sin(math.rad(-22.5)) and delta_angle_sin < math.sin(math.rad(22.5)) and delta_angle_cos < 0 then return true end
    elseif direction == core.direction.Up then
        if delta_angle_sin > math.sin(math.rad(-22.5)) and delta_angle_sin < math.sin(math.rad(22.5)) and delta_angle_cos > 0 then return true end
    elseif direction == core.direction.Right then
        if delta_angle_cos > math.sin(math.rad(-22.5)) and delta_angle_cos < math.sin(math.rad(22.5)) and delta_angle_sin < 0 then return true end
    elseif direction == core.direction.Left then
        if delta_angle_cos > math.sin(math.rad(-22.5)) and delta_angle_cos < math.sin(math.rad(22.5)) and delta_angle_sin > 0 then return true end
    elseif direction == core.direction.LeftDown then
        if delta_angle_sin > math.sin(math.rad(22.5)) and delta_angle_sin < math.sin(math.rad(67.5)) and delta_angle_cos < 0 then return true end
    elseif direction == core.direction.LeftUp then
        if delta_angle_sin > math.sin(math.rad(22.5)) and delta_angle_sin < math.sin(math.rad(67.5)) and delta_angle_cos > 0 then return true end
    elseif direction == core.direction.RightDown then
        if delta_angle_sin > math.sin(math.rad(-67.5)) and delta_angle_sin < math.sin(math.rad(-22.5)) and delta_angle_cos < 0 then return true end
    elseif direction == core.direction.RightUp then
        if delta_angle_sin > math.sin(math.rad(-67.5)) and delta_angle_sin < math.sin(math.rad(-22.5)) and delta_angle_cos > 0 then return true end
    end

    return false
end

-- 检查摇杆方向（基于玩家，仅4方向）
---@param direction number 方向
---@return boolean 是否匹配方向
function input.check_lstick_dir_for_player_only_quad(direction)
    if not input.is_push_lstick() then return false end
    local player_angle = core.master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")
    local input_angle = core.master_player:call('get_RefPlayerInput'):call("getHormdirLstick")

    local delta_angle_sin = math.sin(input_angle - player_angle)
    local delta_angle_cos = math.cos(input_angle - player_angle)

    if direction == core.direction.Down then
        if delta_angle_sin > math.sin(math.rad(-45)) and delta_angle_sin < math.sin(math.rad(45)) and delta_angle_cos < 0 then return true end
    elseif direction == core.direction.Up then
        if delta_angle_sin > math.sin(math.rad(-45)) and delta_angle_sin < math.sin(math.rad(45)) and delta_angle_cos > 0 then return true end
    elseif direction == core.direction.Right then
        if delta_angle_cos > math.sin(math.rad(-45)) and delta_angle_cos < math.sin(math.rad(45)) and delta_angle_sin < 0 then return true end
    elseif direction == core.direction.Left then
        if delta_angle_cos > math.sin(math.rad(-45)) and delta_angle_cos < math.sin(math.rad(45)) and delta_angle_sin > 0 then return true end
    end

    return false
end

-- 检查按键是否被按住（使用isOn）
---@param cmd number|table 命令或命令表
---@return boolean 是否按下
function input.check_input_by_isOn(cmd)
    if not core.master_player then return false end
    local isAnyKeyPressed = false
    if type(cmd) == "table" then
        for _, key in ipairs(cmd) do
            if core.master_player:call('get_RefPlayerInput'):call("get_mNow"):call("isOn", key) then
                isAnyKeyPressed = true
                break
            end
        end
    else
        isAnyKeyPressed = core.master_player:call('get_RefPlayerInput'):call("get_mNow"):call("isOn", cmd)
    end
    return isAnyKeyPressed
end

-- 检查按键是否被按下（使用isCmd）
---@param cmd number|table 命令或命令表
---@return boolean 是否按下
function input.check_input_by_isCmd(cmd)
    if not core.master_player then return false end
    if cmd == nil then return true end
    local isAnyKeyPressed = false
    if type(cmd) == "table" then
        for _, key in ipairs(cmd) do
            if core.master_player:call('get_RefPlayerInput'):call("isCmd", sdk.to_ptr(key)) then
                isAnyKeyPressed = true
                break
            end
        end
    else
        isAnyKeyPressed = core.master_player:call('get_RefPlayerInput'):call("isCmd", sdk.to_ptr(cmd))
    end
    return isAnyKeyPressed
end

return input
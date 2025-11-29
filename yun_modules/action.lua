-- yun_modules/action.lua
-- 动作和运动控制函数

local action = {}
local core = require("yunwulian.yun_modules.core")
local input = require("yunwulian.yun_modules.input")

-- 动作改变回调（直接引用 core 中的回调数组）
action.action_change_functions = core.action_change_callbacks

-- 添加动作改变回调函数
---@param change_functions function 回调函数
function action.on_action_change(change_functions)
    if type(change_functions) == "function" then
        table.insert(action.action_change_functions, change_functions)
    end
end

-- 获取动作ID
---@return number 动作ID
function action.get_action_id()
    if core._action_id then
        return core._action_id
    end
    return 0
end

-- 获取前一个动作ID
---@return number 前一个动作ID
function action.get_pre_action_id()
    if core._pre_action_id then
        return core._pre_action_id
    end
    return 0
end

-- 获取动作库ID
---@return number 动作库ID
function action.get_action_bank_id()
    if core._action_bank_id then
        return core._action_bank_id
    end
    return 0
end

-- 获取当前动作帧
---@return number 当前动作帧
function action.get_now_action_frame()
    if not core.master_player then return 0 end
    return core._action_frame
end

-- 设置动作帧（跳转到特定帧）
---@param frame number 帧数
function action.set_now_action_frame(frame)
    if not core.master_player then return end
    return core.master_player:call("getMotionLayer", 0):call("set_Frame", frame)
end

-- 获取当前行为树节点ID
---@return number 节点ID
function action.get_current_node()
    if core._current_node then
        return core._current_node
    else
        return 0
    end
end

-- 强制派生到特定节点
---@param node_hash number 节点哈希
function action.set_current_node(node_hash)
    if not core.master_player then return end
    core.mPlBHVT:call("setCurrentNode", node_hash, nil, nil)
end

-- 检查动作ID是否在表中
---@param action_table table 动作表
---@param bank_id number 动作库ID
---@return boolean 是否在表中
function action.check_action_table(action_table, bank_id)
    bank_id = bank_id or 100
    if core._action_bank_id == bank_id then
        for i = 1, #action_table do
            if core._action_id == action_table[i] then
                return true
            end
        end
        return false
    else
        return false
    end
end

-- 获取当前动作的动作值
---@return number 动作值
function action.get_motion_value()
    if core._wep_type == core.weapon_type.SlashAxe then
        return core._slash_axe_motion_value or 0
    end
    return core._motion_value or 0
end

-- 获取当前动作的动作值ID
---@return number 动作值ID
function action.get_motion_value_id()
    if not core._motion_value_id and not core._slash_axe_motion_value_id then return 0 end
    if core._wep_type == core.weapon_type.SlashAxe then
        return core._slash_axe_motion_value_id
    end
    return core._motion_value_id
end

-- 向摇杆方向移动一段距离，与动作原本的位移有关。
---@param action_id number 动作ID
---@param frame_range number 帧范围
---@param no_move_frame number 不可移动帧
---@param move_multipier number 移动倍率
---@param dir_limit number 方向限制
function action.move_to_lstick_dir(action_id, frame_range, no_move_frame, move_multipier, dir_limit)
    if core._action_id == action_id then
        local motion = core.master_player:getMotion()
        local temp_vec3 = motion:get_RootMotionTranslation()
        local input_angle = core.master_player:call('get_RefPlayerInput'):call("getHormdirLstick")
        local move_distance = math.sqrt(temp_vec3.x ^ 2 + temp_vec3.z ^ 2)
        if move_multipier then
            move_distance = move_distance * move_multipier
        end
        if no_move_frame then
            if core._action_frame < no_move_frame then
                temp_vec3.x = -temp_vec3.x
                temp_vec3.z = -temp_vec3.z
            end
        end
        if core._action_frame < frame_range then
            if input.is_push_lstick() then
                if dir_limit ~= nil then
                    if not input.check_lstick_dir_for_player(dir_limit) then
                        return
                    end
                end
                temp_vec3.x = temp_vec3.x + move_distance * math.sin(input_angle)
                temp_vec3.z = temp_vec3.z + move_distance * math.cos(input_angle)
            end
        end

        local temp_rota = motion:get_RootMotionRotation()
        motion:rootApply(temp_vec3, temp_rota)
    end
end

return action

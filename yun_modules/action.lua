-- yun_modules/action.lua
-- Action and motion control functions

local action = {}
local core = require("yunwulian.yun_modules.core")

-- Action change callbacks
action.action_change_functions = {}

function action.on_action_change(change_functions)
    if type(change_functions) == "function" then
        table.insert(action.action_change_functions, change_functions)
    end
end

-- Get action ID
function action.get_action_id()
    if core._action_id then
        return core._action_id
    end
    return 0
end

-- Get previous action ID
function action.get_pre_action_id()
    if core._pre_action_id then
        return core._pre_action_id
    end
    return 0
end

-- Get action bank ID
function action.get_action_bank_id()
    if core._action_bank_id then
        return core._action_bank_id
    end
    return 0
end

-- Get current action frame
function action.get_now_action_frame()
    if not core.master_player then return end
    return core._action_frame
end

-- Set action frame (jump to specific frame)
function action.set_now_action_frame(frame)
    if not core.master_player then return end
    return core.master_player:call("getMotionLayer", 0):call("set_Frame", frame)
end

-- Get current behavior tree node ID
function action.get_current_node()
    if core._current_node then
        return core._current_node
    else
        return 0
    end
end

-- Force derive to a specific node
function action.set_current_node(node_hash)
    if not core.master_player then return end
    core.mPlBHVT:call("setCurrentNode", node_hash, nil, nil)
end

-- Check if action ID is in table
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

-- Motion value functions
function action.get_motion_value()
    if not core._motion_value or not core._slash_axe_motion_value then return 0 end
    if core._wep_type == core.weapon_type.SlashAxe then
        return core._slash_axe_motion_value
    end
    return core._motion_value
end

function action.get_motion_value_id()
    if not core._motion_value_id and not core._slash_axe_motion_value_id then return 0 end
    if core._wep_type == core.weapon_type.SlashAxe then
        return core._slash_axe_motion_value_id
    end
    return core._motion_value_id
end

-- Move character towards stick direction (deprecated, performance issues)
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
            local input = require("yunwulian.yun_modules.input")
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

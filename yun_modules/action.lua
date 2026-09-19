-- yun_modules/action.lua
-- 动作和运动控制函数

local action = {}
local core = require("yunwulian.yun_modules.core")
local input = require("yunwulian.yun_modules.input")
local move_mode = require("yunwulian.yun_modules.constant").move_direction_mode

local character_type = sdk.find_type_definition("snow.CharacterBase")
local motion_id = character_type:get_method("getMotionID_Layer")
local motion_bank = character_type:get_method("getMotionBankID_Layer")
local motion_frame = character_type:get_method("getMotionNowFrame_Layer")
local motion_prev_frame = character_type:get_method("getMotionPrevFrame_Layer")
local common_param = character_type:get_field("_commonParam")
local param_type = sdk.find_type_definition("snow.CharacterParam")
local is_trans_scale = param_type:get_method("get_IsMotTransScale")
local set_trans_scale_enabled = param_type:get_method("set_IsMotTransScale")
local get_position = character_type:get_method("get_Pos")
local set_position = character_type:get_method("set_Pos")
local get_radian = character_type:get_method("getRadian")
local direction_angles = {
    [core.direction.Up] = 0,
    [core.direction.Down] = math.pi,
    [core.direction.Left] = math.pi / 2,
    [core.direction.Right] = -math.pi / 2,
}
local pending_move = nil
local active_move = nil

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
    return core.master_player:getMotionLayer(0):set_Frame(frame)
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
    core.mPlBHVT:setCurrentNode(node_hash, nil, nil)
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

-- 每次更新提交一次请求，在原生根运动阶段重定向水平位移。
---@param action_id number 动作ID
---@param frame_range number 修改结束帧（不含）
---@param no_move_frame number|nil 此帧之前禁止水平位移，默认0
---@param move_multiplier number|nil 原动画水平位移倍率，默认1
---@param dir_limit number|nil 方向限制
---@param direction_mode number|nil move_direction_mode.Free 或 FourWay，默认Free
function action.move_to_lstick_dir(action_id, frame_range, no_move_frame, move_multiplier, dir_limit, direction_mode)
    direction_mode = direction_mode or move_mode.Free
    assert(direction_mode == move_mode.Free or direction_mode == move_mode.FourWay, "invalid move_direction_mode")
    local player = core.master_player
    if not player or motion_id:call(player, 0) ~= action_id then return end
    pending_move = {
        player = player,
        id = action_id,
        bank = motion_bank:call(player, 0),
        end_frame = frame_range,
        start_frame = no_move_frame or 0,
        multiplier = move_multiplier or 1,
        direction = dir_limit,
        mode = direction_mode,
    }
end

function action.hook_pre_motion_begin(args)
    local storage = thread.get_hook_storage()
    storage.move_param = nil
    local player = sdk.to_managed_object(args[2])
    if player ~= core.master_player then return end

    local request = pending_move
    pending_move = nil
    active_move = nil
    if not request or request.player ~= player
        or motion_id:call(player, 0) ~= request.id
        or motion_bank:call(player, 0) ~= request.bank
        or motion_frame:call(player, 0) >= request.end_frame then return end

    active_move = request
    local param = common_param:get_data(player)
    if not is_trans_scale:call(param) then
        -- MotionBegin 仅凭标志注册根运动回调；返回后立即恢复，不改变实际倍率。
        storage.move_param = param
        set_trans_scale_enabled:call(param, true)
    end
end

function action.hook_post_motion_begin(retval)
    local param = thread.get_hook_storage().move_param
    if param then
        set_trans_scale_enabled:call(param, false)
    end
    return retval
end

local function frame_weight(previous, current, last)
    if current <= previous then
        return current >= 0 and current < last and 1 or 0
    end
    return math.max(0, math.min(current, last) - math.max(previous, 0)) / (current - previous)
end

function action.hook_pre_root_apply(args)
    local storage = thread.get_hook_storage()
    storage.move_player = nil
    local player = sdk.to_managed_object(args[2])
    if player ~= core.master_player then return end

    local request = active_move
    active_move = nil
    if not request or request.player ~= player
        or motion_id:call(player, 0) ~= request.id
        or motion_bank:call(player, 0) ~= request.bank then return end

    local current = motion_frame:call(player, 0)
    local previous = motion_prev_frame:call(player, 0)
    local blocked = frame_weight(previous, current, math.min(request.start_frame, request.end_frame))
    local steered = 0
    local angle = 0
    if input.is_push_lstick()
        and (request.direction == nil or input.check_lstick_dir_for_player(request.direction)) then
        steered = frame_weight(previous, current, request.end_frame) - blocked
        angle = player:get_RefPlayerInput():getHormdirLstick()
        if steered > 0 and request.mode == move_mode.FourWay then
            local player_angle = get_radian:call(player).y
            for direction, offset in pairs(direction_angles) do
                if input.check_lstick_dir_for_player_only_quad(direction, player_angle) then
                    angle = player_angle + offset
                    break
                end
            end
        end
    end
    if blocked == 0 and steered == 0 then return end

    storage.move_player = player
    storage.move_start = get_position:call(player)
    storage.move_scale = 1 - blocked + (request.multiplier - 1) * steered
    storage.move_angle = steered > 0 and angle or nil
end

function action.hook_post_root_apply(retval)
    local storage = thread.get_hook_storage()
    local player = storage.move_player
    if player then
        -- 使用原生缩放、坡面处理后的增量；边界仅混合距离，避免方向相消。
        local position = get_position:call(player)
        local start = storage.move_start
        local x, z = position.x - start.x, position.z - start.z
        if storage.move_angle then
            local distance = math.sqrt(x * x + z * z) * storage.move_scale
            position.x = start.x + distance * math.sin(storage.move_angle)
            position.z = start.z + distance * math.cos(storage.move_angle)
        else
            position.x = start.x + x * storage.move_scale
            position.z = start.z + z * storage.move_scale
        end
        set_position:call(player, position)
    end
    return retval
end

return action

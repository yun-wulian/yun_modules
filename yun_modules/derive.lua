-- yun_modules/derive.lua
-- 派生系统，用于动作转换和连招

local derive = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local input = require("yunwulian.yun_modules.input")
local action = require("yunwulian.yun_modules.action")
local player = require("yunwulian.yun_modules.player")

-- 派生表注册
derive.deriveTable = {}

-- 内部派生状态
local need_clear = -1                    -- 需要清理的标志
local wrappered_id                       -- 包装ID
local derive_atk_data = {}               -- 派生攻击数据
local hit_counter_info = {}              -- 命中计数器信息
local need_hit_info = {}                 -- 需要命中的信息
local hit_success = -1                   -- 命中成功标志
local counter_success = false            -- 反击成功标志
local need_speed_change = {}             -- 需要速度改变的数据
local jmp_frame_cache = 0                -- 跳帧缓存
local jmp_frame_id = 0                   -- 跳帧ID
local ignore_keys = {}                   -- 忽略的按键
local this_derive_cmd = 0                -- 当前派生命令
local this_is_by_action_id = true        -- 是否通过动作ID
local input_cache = 0                    -- 输入缓存
local pressed_time = 0.0                 -- 按键按下时间

-- 钩子函数
derive.hook_evaluate_post = {}

-- 注册派生表
---@param derive_table table 派生表
function derive.push_derive_table(derive_table)
    if type(derive_table) == "table" then
        table.insert(derive.deriveTable, derive_table)
    end
end

-- 添加评估后函数
---@param func function 函数
function derive.push_evaluate_post_functions(func)
    if type(func) == "function" then
        table.insert(derive.hook_evaluate_post, func)
    end
end

-- 派生后跳转到特定帧
local function jmpFrame()
    if jmp_frame_cache ~= 0 and jmp_frame_id ~= 0 then
        if jmp_frame_id == core._pre_node_id or jmp_frame_id == core._pre_action_id then
            action.set_now_action_frame(jmp_frame_cache)
            jmp_frame_cache = 0
            jmp_frame_id = 0
        end
    end
end

-- 离开动作时清理派生数据
local function wrappered_id_clear_data()
    if core._pre_action_id ~= wrappered_id and core._pre_node_id ~= wrappered_id and need_clear == core._pre_node_id then
        need_clear = -1
        jmp_frame_cache = 0
        jmp_frame_id = 0
        hit_success = -1
        need_hit_info = {}
        derive_atk_data = {}
        counter_success = false
    end
end

-- 检查按键是否按住特定时长
---@param key number 按键
---@param time number 时间
---@return boolean 是否按住
local function holding_key(key, time)
    if input.check_input_by_isOn(key) then
        pressed_time = pressed_time + player.get_delta_time()
        if pressed_time > time then
            return true
        end
    elseif not input.check_input_by_isOn(key) and pressed_time ~= 0 then
        pressed_time = 0
    end
    return false
end

-- 主派生包装函数
local function derive_wrapper(derive_table)
    local derive_wrapper = {}
    if not core.master_player then return end

    local now_action_table

    -- 遍历武器表
    for _, sub_derive_table in ipairs(derive_table) do
        if sub_derive_table[core._wep_type] ~= nil then
            now_action_table = sub_derive_table[core._wep_type][core._action_id]
            wrappered_id = core._action_id
            this_is_by_action_id = true
            if now_action_table == nil then
                now_action_table = sub_derive_table[core._wep_type][core._current_node]
                wrappered_id = core._current_node
                this_is_by_action_id = false
            end
        end
        if now_action_table == nil then
            goto continue2
        end

        -- 遍历派生条件
        for index, subtable in ipairs(now_action_table) do
            if subtable['specialCondition'] == false then goto continue end

            local _targetNode = subtable['targetNode']          -- 目标节点
            local _preFrame = subtable['preFrame'] or 10.0      -- 前置帧
            local _startFrame = subtable['startFrame'] or core._derive_start_frame -- 开始帧
            local _targetCmd = subtable['targetCmd']            -- 目标命令
            local _isHolding = subtable['isHolding']            -- 是否按住
            local _tarLstickDir = subtable['tarLstickDir']      -- 目标左摇杆方向
            local _isByPlayerDir = subtable['isByPlayerDir']    -- 是否基于玩家方向
            local _turnRange = subtable['turnRange']            -- 转向范围
            local _jmpFrame = subtable['jmpFrame']              -- 跳帧
            local _preActionId = subtable['preActionId']        -- 前置动作ID
            local _preNodeId = subtable['preNodeId']            -- 前置节点ID
            local _useWire = subtable['useWire']                -- 使用翔虫
            local _actionSpeed = subtable['actionSpeed']        -- 动作速度
            local _holdingTime = subtable['holdingTime']        -- 按住时间

            -- 检查前置条件
            if _preActionId ~= nil and core._pre_action_id ~= _preActionId then
                goto continue
            end
            if _preNodeId ~= nil and core._pre_node_id ~= _preNodeId then
                goto continue
            end
            if subtable['counterAtk'] ~= nil and hit_counter_info[1] == nil then
                hit_counter_info = utils.deepCopy(subtable['counterAtk'])
            end
            if subtable['hit'] ~= nil then
                need_hit_info = { core._action_id, _startFrame }
            end
            if subtable['needIgnoreOriginalKey'] ~= nil then
                ignore_keys[wrappered_id] = {}
                table.insert(ignore_keys[wrappered_id], subtable['needIgnoreOriginalKey'])
                subtable['needIgnoreOriginalKey'] = nil
            end
            if _targetNode == nil then
                goto continue
            end

            -- 检查是否在输入窗口内
            if _startFrame - _preFrame < core._action_frame then
                -- 检查摇杆方向
                if _tarLstickDir ~= nil then
                    if _useWire ~= nil then
                        if _useWire[1] > core.master_player:getUsableHunterWireNum() then
                            goto continue
                        end
                    end
                    if _isByPlayerDir == nil or _isByPlayerDir then
                        if not input.check_lstick_dir_for_player_only_quad(_tarLstickDir) then
                            goto continue
                        end
                    elseif not _isByPlayerDir then
                        if not input.check_lstick_dir(_tarLstickDir) then
                            goto continue
                        end
                    end
                end

                -- 检查输入
                if input_cache == 0 then
                    if _targetCmd == nil and subtable['hit'] == nil and subtable['counterAtk'] == nil then
                        input_cache = _targetNode
                    elseif _targetCmd ~= nil then
                        if _holdingTime then
                            if holding_key(_targetCmd, _holdingTime) then
                                input_cache = _targetNode
                                pressed_time = 0.0
                            end
                        elseif _isHolding and not _holdingTime then
                            if input.check_input_by_isOn(_targetCmd) then
                                input_cache = _targetNode
                            end
                        else
                            if input.check_input_by_isCmd(_targetCmd) then
                                input_cache = _targetNode
                            end
                        end
                    end
                end
            end

            -- 执行派生函数
            function derive_wrapper.doDerive(target_node)
                if not target_node then
                    action.set_current_node(input_cache)
                else
                    action.set_current_node(target_node)
                end
                if _turnRange ~= nil then
                    input.turn_to_lstick_dir(_turnRange)
                end
                if _jmpFrame ~= nil then
                    jmp_frame_cache = _jmpFrame
                    jmp_frame_id = wrappered_id
                end
                if _actionSpeed ~= nil then
                    local __key = (target_node or input_cache)
                    need_speed_change[__key] = utils.deepCopy(_actionSpeed)
                end
                if subtable['atkMult'] ~= nil then
                    derive_atk_data['atkMult'] = utils.deepCopy(subtable['atkMult'])
                end
                if subtable['eleMult'] ~= nil then
                    derive_atk_data['eleMult'] = utils.deepCopy(subtable['eleMult'])
                end
                if subtable['stunMult'] ~= nil then
                    derive_atk_data['stunMult'] = utils.deepCopy(subtable['stunMult'])
                end
                if subtable['staMult'] ~= nil then
                    derive_atk_data['staMult'] = utils.deepCopy(subtable['staMult'])
                end
                need_clear = _targetNode or -1
                input_cache = 0
            end

            -- 在开始帧执行派生
            if _startFrame < core._action_frame then
                if input_cache ~= 0 then
                    if _useWire ~= nil then
                        core.master_player:useHunterWireGauge(_useWire[1], _useWire[2])
                    end
                    derive_wrapper.doDerive()
                    break
                end
                if hit_success ~= -1 and subtable['hit'] ~= nil then
                    if subtable['hitLag'] ~= nil then
                        if hit_success + subtable['hitLag'] > core._action_frame then
                            goto continue
                        end
                    end
                    derive_wrapper.doDerive(_targetNode)
                    hit_success = -1
                    break
                end
            end

            -- 反击派生
            if counter_success and subtable['counterAtk'] ~= nil then
                derive_wrapper.doDerive(_targetNode)
                counter_success = false
                break
            end

            ::continue::
        end
        ::continue2::
    end
end

-- 速度改变处理
local function speed_change()
    for id, speed_table in pairs(need_speed_change) do
        if core._current_node == id then
            for i, frameRange in ipairs(speed_table["frame"]) do
                if utils.isFrameInRange(core._action_frame, frameRange) then
                    player.set_player_timescale(speed_table["speed"][i])
                    break
                else
                    player.set_player_timescale(-1.0)
                end
            end
        elseif core._pre_node_id == id then
            need_speed_change[id] = nil
            player.set_player_timescale(-1.0)
        else
            player.set_player_timescale(-1.0)
        end
    end
end

-- 已弃用的模拟派生函数（保持兼容性）
---@param tar_action_id number 目标动作ID
---@param tar_action_bank_id number 目标动作库ID
---@param tar_cmd number 目标命令
---@param is_by_isCmd boolean 是否使用isCmd检查
---@param tar_lstick_dir number 目标左摇杆方向
---@param is_by_player_dir boolean 是否基于玩家方向
---@param pre_frame number 前置帧
---@param start_frame number 开始帧
---@param turn_range number 转向范围
---@param tar_node_hash number 目标节点哈希
---@param jmp_frame number 跳帧
function derive.analog_derive(tar_action_id, tar_action_bank_id, tar_cmd, is_by_isCmd, tar_lstick_dir,
                              is_by_player_dir, pre_frame, start_frame, turn_range, tar_node_hash, jmp_frame)
    local derive = {}
    derive.tar_action_id = tar_action_id
    derive.tar_action_bank_id = tar_action_bank_id
    derive.tar_cmd = tar_cmd
    derive.is_by_isCmd = is_by_isCmd
    derive.tar_lstick_dir = tar_lstick_dir
    derive.is_by_player_dir = is_by_player_dir
    derive.pre_frame = pre_frame
    derive.start_frame = start_frame
    derive.turn_range = turn_range
    derive.tar_node_hash = tar_node_hash
    derive.jmp_frame = jmp_frame
    derive.pre_input_flag = false

    function derive.analog_input()
        if not derive.tar_action_bank_id then derive.tar_action_bank_id = 100 end
        if not derive.is_by_isCmd then derive.is_by_isCmd = true end
        if core._action_bank_id == derive.tar_action_bank_id and core._action_id == derive.tar_action_id and action.get_now_action_frame() >= derive.pre_frame then
            if not derive.pre_input_flag then
                if derive.is_by_isCmd then
                    if not input.check_input_by_isCmd(tar_cmd) then
                        return
                    end
                else
                    if not input.check_input_by_isOn(tar_cmd) then
                        return
                    end
                end
                if derive.tar_lstick_dir then
                    if derive.is_by_player_dir then
                        if not input.check_lstick_dir_for_player_only_quad(derive.tar_lstick_dir) or derive.turn_range then
                            return
                        end
                    else
                        if not input.check_lstick_dir(derive.tar_lstick_dir) or derive.turn_range then
                            return
                        end
                    end
                end
                derive.pre_input_flag = true
                if derive.turn_range then
                    input.turn_to_lstick_dir(derive.turn_range)
                end
            end
        end
    end

    function derive.analog_derive_to_target()
        if derive.pre_input_flag and derive.tar_node_hash ~= 0 and action.get_now_action_frame() >= start_frame and core._action_id == derive.tar_action_id then
            action.set_current_node(derive.tar_node_hash)
            derive.pre_input_flag = false
        end
    end

    function derive.analog_jmp_frame()
        if derive.tar_node_hash == action.get_current_node() and derive.jmp_frame ~= nil and core._pre_action_id == derive.tar_action_id and action.get_now_action_frame() > 0.0 and action.get_now_action_frame() < derive.jmp_frame then
            action.set_now_action_frame(derive.jmp_frame)
        end
    end

    if core._action_id == derive.tar_action_id then
        derive.analog_input()
        derive.analog_derive_to_target()
    else
        derive.analog_jmp_frame()
    end
end

-- 更新函数（每帧调用）
function derive.update()
    derive_wrapper(derive.deriveTable)
    speed_change()
end

-- 延迟更新（用于清理）
function derive.late_update()
    wrappered_id_clear_data()
end

-- 动作改变回调
function derive.on_action_change()
    jmpFrame()
    hit_counter_info = {}
end

-- 获取派生攻击数据（用于钩子和调试）
---@return table 派生攻击数据
function derive.get_derive_atk_data()
    return derive_atk_data
end

-- 获取命中计数器信息
---@return table 命中计数器信息
function derive.get_hit_counter_info()
    return hit_counter_info
end

-- 获取需要命中的信息
---@return table 需要命中的信息
function derive.get_need_hit_info()
    return need_hit_info
end

-- 设置命中成功
---@param value any 值
function derive.set_hit_success(value)
    hit_success = value
end

-- 设置反击成功
---@param value boolean 值
function derive.set_counter_success(value)
    counter_success = value
end

-- 获取命中成功
---@return any 命中成功值
function derive.get_hit_success()
    return hit_success
end

-- 获取反击成功
---@return boolean 是否反击成功
function derive.get_counter_success()
    return counter_success
end

-- 设置派生开始帧
---@param value number 值
function derive.set_derive_start_frame(value)
    core._derive_start_frame = value
end

-- 获取当前派生命令
---@return number 派生命令
function derive.get_this_derive_cmd()
    return this_derive_cmd
end

-- 设置当前派生命令
---@param value number 值
function derive.set_this_derive_cmd(value)
    this_derive_cmd = value
end

-- 获取忽略的按键
---@return table 忽略的按键表
function derive.get_ignore_keys()
    return ignore_keys
end

-- 获取是否通过动作ID
---@return boolean 是否通过动作ID
function derive.get_this_is_by_action_id()
    return this_is_by_action_id
end

return derive
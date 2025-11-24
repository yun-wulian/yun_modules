-- yun_modules/derive.lua
-- Derive system for action transitions and combos

local derive = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local input = require("yunwulian.yun_modules.input")
local action = require("yunwulian.yun_modules.action")
local player = require("yunwulian.yun_modules.player")

-- Derive tables registry
derive.deriveTable = {}

-- Internal derive state
local need_clear = -1
local wrappered_id
local derive_atk_data = {}
local hit_counter_info = {}
local need_hit_info = {}
local hit_success = -1
local counter_success = false
local need_speed_change = {}
local jmp_frame_cache = 0
local jmp_frame_id = 0
local ignore_keys = {}
local this_derive_cmd = 0
local this_is_by_action_id = true
local input_cache = 0
local pressed_time = 0.0

-- Hook functions
derive.hook_evaluate_post = {}

-- Register derive table
function derive.push_derive_table(derive_table)
    if type(derive_table) == "table" then
        table.insert(derive.deriveTable, derive_table)
    end
end

-- Push evaluate post function
function derive.push_evaluate_post_functions(func)
    if type(func) == "function" then
        table.insert(derive.hook_evaluate_post, func)
    end
end

-- Jump to specific frame after derive
local function jmpFrame()
    if jmp_frame_cache ~= 0 and jmp_frame_id ~= 0 then
        if jmp_frame_id == core._pre_node_id or jmp_frame_id == core._pre_action_id then
            action.set_now_action_frame(jmp_frame_cache)
            jmp_frame_cache = 0
            jmp_frame_id = 0
        end
    end
end

-- Clear derive data when leaving action
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

-- Check if key is held for specific duration
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

-- Main derive wrapper function
local function derive_wrapper(derive_table)
    local derive_wrapper = {}
    if not core.master_player then return end

    local now_action_table

    -- Iterate through weapon tables
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

        -- Iterate through derive conditions
        for index, subtable in ipairs(now_action_table) do
            if subtable['specialCondition'] == false then goto continue end

            local _targetNode = subtable['targetNode']
            local _preFrame = subtable['preFrame'] or 10.0
            local _startFrame = subtable['startFrame'] or core._derive_start_frame
            local _targetCmd = subtable['targetCmd']
            local _isHolding = subtable['isHolding']
            local _tarLstickDir = subtable['tarLstickDir']
            local _isByPlayerDir = subtable['isByPlayerDir']
            local _turnRange = subtable['turnRange']
            local _jmpFrame = subtable['jmpFrame']
            local _preActionId = subtable['preActionId']
            local _preNodeId = subtable['preNodeId']
            local _useWire = subtable['useWire']
            local _actionSpeed = subtable['actionSpeed']
            local _holdingTime = subtable['holdingTime']

            -- Check pre-conditions
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

            -- Check if within input window
            if _startFrame - _preFrame < core._action_frame then
                -- Check stick direction
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

                -- Check input
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

            -- Do derive function
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

            -- Execute derive at start frame
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

            -- Counter attack derive
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

-- Speed change handler
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

-- Deprecated analog derive function (kept for compatibility)
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

-- Update function (called every frame)
function derive.update()
    derive_wrapper(derive.deriveTable)
    speed_change()
end

-- Late update (for cleanup)
function derive.late_update()
    wrappered_id_clear_data()
end

-- Action change callback
function derive.on_action_change()
    jmpFrame()
    hit_counter_info = {}
end

-- Get internal state (for hooks and debugging)
function derive.get_derive_atk_data()
    return derive_atk_data
end

function derive.get_hit_counter_info()
    return hit_counter_info
end

function derive.get_need_hit_info()
    return need_hit_info
end

function derive.set_hit_success(value)
    hit_success = value
end

function derive.set_counter_success(value)
    counter_success = value
end

function derive.get_hit_success()
    return hit_success
end

function derive.get_counter_success()
    return counter_success
end

function derive.set_derive_start_frame(value)
    core._derive_start_frame = value
end

function derive.get_this_derive_cmd()
    return this_derive_cmd
end

function derive.set_this_derive_cmd(value)
    this_derive_cmd = value
end

function derive.get_ignore_keys()
    return ignore_keys
end

function derive.get_this_is_by_action_id()
    return this_is_by_action_id
end

return derive

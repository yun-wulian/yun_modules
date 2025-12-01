-- yun_modules/player.lua
-- 玩家相关函数和属性

local player = {}
local core = require("yunwulian.yun_modules.core")

-- 武器切换回调（直接引用 core 中的回调数组）
player.weapon_change_callbacks = core.weapon_change_callbacks

-- 添加武器切换回调函数
---@param callback function 回调函数，接收参数 (new_weapon_type, old_weapon_type)
function player.on_weapon_change(callback)
    if type(callback) == "function" then
        table.insert(player.weapon_change_callbacks, callback)
    end
end

-- 时间函数
local get_UpTimeSecond = sdk.find_type_definition("via.Application"):get_method("get_UpTimeSecond")
local get_ElapsedSecond = sdk.find_type_definition("via.Application"):get_method("get_ElapsedSecond")

-- 获取游戏时间
---@return number 游戏时间
function player.get_time()
    return get_UpTimeSecond:call(nil)
end

-- 获取帧间隔时间
---@return number 帧间隔时间
function player.get_delta_time()
    return get_ElapsedSecond:call(nil)
end

-- 获取玩家速度/时间缩放
---@return number 玩家时间缩放
function player.get_player_timescale()
    if not core.master_player then return end
    if core.master_player:call("get_GameObject") == nil then return end
    return core.master_player:call("get_GameObject"):call("get_TimeScale")
end

-- 设置玩家速度/时间缩放
---@param value number 时间缩放值
function player.set_player_timescale(value)
    if not core.master_player then return end
    if core.master_player:call("get_GameObject") == nil then return end
    core.master_player:call("get_GameObject"):call("set_TimeScale", value + .0)
end

-- 检查master_player是否可用
---@return boolean 是否可用
local function is_master_player_valid()
    return core.master_player ~= nil and core.master_player:call("get_GameObject") ~= nil
end

-- 获取主玩家对象
---@return userdata? 主玩家对象
function player.get_master_player()
    return core.master_player
end

-- 获取主玩家索引
---@return number? 主玩家索引
function player.get_master_player_index()
    return core.master_player_index
end

-- 检查武器类型
---@param tar_type number 目标武器类型
---@return boolean 是否使用该武器类型
function player.check_using_weapon_type(tar_type)
    return core._wep_type == tar_type
end

-- 获取武器类型
---@return number? 武器类型
function player.get_weapon_type()
    if not is_master_player_valid() then return nil end
    return core._wep_type
end

-- 检查玩家是否拥有特定技能等级
---@param skill number 技能ID
---@return number 技能等级
function player.check_equip_skill_lv(skill)
    if not is_master_player_valid() then return 0 end
    local skill_list = core.master_player:call("get_PlayerSkillList")
    if not skill_list then return 0 end
    
    for i = 7, 1, -1 do
        if skill_list:call("hasSkill", skill, i) then
            return i
        end
    end
    return 0
end

-- 检查玩家是否拥有特定白龙技能
---@param skill number 技能ID
---@return boolean 是否拥有该技能
function player.check_has_hyakuryu_skill(skill)
    if not is_master_player_valid() then return false end
    local skill_list = core.master_player:call("get_PlayerSkillList")
    if not skill_list then return false end
    
    return skill_list:call("hasHyakuryuSkill(snow.data.DataDef.PlHyakuryuSkillId)", skill) == true
end

-- 攻击和会心率控制
---@param value number 攻击力值
function player.set_atk(value)
    core.atk_flag = true
    core.player_atk = value
end

---@param value number 会心率值
function player.set_affinity(value)
    core.affinity_flag = true
    core.player_affinity = value
end

-- 清除攻击力修改
function player.clear_atk()
    core.atk_flag = false
end

-- 清除会心率修改
function player.clear_affinity()
    core.affinity_flag = false
end

-- 获取攻击力
---@return number 攻击力
function player.get_atk()
    if not core.master_player then return 0 end
    return core._atk
end

-- 获取会心率
---@return number 会心率
function player.get_affinity()
    if not core.master_player then return 0 end
    return core._affinity
end

-- 无敌时间
---@return number 无敌时间
function player.get_muteki_time()
    if not core.master_player then return end
    return core._muteki_time
end

---@param value number 无敌时间值
function player.set_muteki_time(value)
    if not core.master_player then return end
    return core.master_player:set_field("_MutekiTime", value)
end

-- 霸体时间
---@return number 霸体时间
function player.get_hyper_armor_time()
    if not core.master_player then return end
    return core._hyper_armor_time
end

---@param value number 霸体时间值
function player.set_hyper_armor_time(value)
    if not core.master_player then return end
    return core.master_player:set_field("_HyperArmorTimer", value)
end

-- 替换攻击数据
---@return table 替换攻击数据表
function player.get_replace_attack_data()
    if not core.master_player then return end
    return core._replace_atk_data
end

-- 生命值
---@return number 当前生命值
function player.get_vital()
    return core.player_data:get__vital()
end

---@param new_vital number 新生命值
function player.set_vital(new_vital)
    return core.player_data:set__vital(new_vital)
end

---@return number 最大生命值
function player.get_r_vital()
    return core.player_data:get_field("_r_Vital")
end

---@param new_r_vital number 新最大生命值
function player.set_r_vital(new_r_vital)
    return core.player_data:set_field("_r_Vital", new_r_vital)
end

-- 替换技能函数
---@return number 当前选择的技能书
function player.get_selected_book()
    if not core.master_player then return nil end
    local ReplaceHolder = core.master_player:get_field("_ReplaceAtkMysetHolder")
    return ReplaceHolder:call("getSelectedIndex")
end

-- 获取切换技能
---@param book number 技能书
---@param index number 索引
---@return number 技能类型
function player.get_switch_skill(book, index)
    if not is_master_player_valid() then return 0 end

    local replace_holder = core.master_player:get_field("_ReplaceAtkMysetHolder")
    if not replace_holder then return 0 end

    local replace_data = replace_holder:get_field("_ReplaceAtkMysetData")
    if not replace_data or not replace_data[book] then return 0 end

    local atk_types = replace_data[book]:get_field("_ReplaceAtkTypes")
    if not atk_types then return 0 end

    -- 检查是否有有效的攻击类型
    local has_valid_atk_type = false
    for i = 0, 5 do
        if atk_types[i] and sdk.to_int64(atk_types[i]) ~= 0 then
            has_valid_atk_type = true
            break
        end
    end
    if not has_valid_atk_type then return 0 end

    -- 根据索引返回相应的技能类型
    if index == 4 and atk_types[4] then
        if atk_types[4]:get_field("value__") == 1 then
            return 3
        elseif atk_types[2] then
            return atk_types[2]:get_field("value__") + 1
        end
    elseif index == 5 and atk_types[5] then
        return atk_types[5]:get_field("value__") + 1
    end

    return 0
end

-- ============================================================================
-- 受伤碰撞箱缩放功能
-- ============================================================================

-- 碰撞箱内部状态
local _hurtbox_initialized = false
local _hurtbox_scale_rules = {}  -- { [weapon_type] = { [action_id] = scale } }
local _hurtbox_current_weapon_type = nil
local _player_hurtbox = nil
local _hurtbox_original_radius = nil
local _hurtbox_original_extent = nil

-- 获取组件的辅助函数
local function get_component(game_object, type_name)
    local t = sdk.typeof(type_name)
    if t == nil then return nil end
    return game_object:call("getComponent(System.Type)", t)
end

-- 获取玩家受伤碰撞箱
local function get_player_hurtbox()
    local playman = sdk.get_managed_singleton("snow.player.PlayerManager")
    if not playman then return nil end

    local master = playman:findMasterPlayer()
    if master then
        local game_object = master:get_GameObject()
        local rscc = get_component(game_object, 'snow.RSCController')
        if rscc then
            return rscc:getCollidable(0, 0, 0)
        end
    end
    return nil
end

-- 修改碰撞箱大小
local function modify_hurtbox_size(collidable, multiplier)
    if not collidable then return false end

    local shape = collidable:get_Shape()
    if not shape then return false end

    local shape_type = shape:get_ShapeType()

    -- 类型 1: Sphere, 类型 3: Capsule, 类型 5: Box
    if shape_type == 1 or shape_type == 3 then -- Sphere 或 Capsule
        local current_radius = shape:get_Radius()
        if not _hurtbox_original_radius then
            _hurtbox_original_radius = current_radius
        end
        shape:set_Radius(_hurtbox_original_radius * multiplier)
        return true

    elseif shape_type == 5 then -- Box
        if not _hurtbox_original_extent then
            _hurtbox_original_extent = shape:get_Extent()
        end
        local new_extent = Vector3f.new(
            _hurtbox_original_extent.x * multiplier,
            _hurtbox_original_extent.y * multiplier,
            _hurtbox_original_extent.z * multiplier
        )
        shape:set_Extent(new_extent)
        return true
    end

    return false
end

-- 每帧更新碰撞箱（内部函数，由主循环调用）
function player._update_hurtbox()
    if not _hurtbox_initialized then return end

    -- 检测武器切换，清理内部状态
    if core._wep_type ~= _hurtbox_current_weapon_type then
        _hurtbox_current_weapon_type = core._wep_type
        _player_hurtbox = nil
        _hurtbox_original_radius = nil
        _hurtbox_original_extent = nil
    end

    -- 获取当前武器的规则
    local current_rules = _hurtbox_scale_rules[_hurtbox_current_weapon_type]
    if not current_rules then return end

    -- 获取或更新碰撞箱引用
    if not _player_hurtbox then
        _player_hurtbox = get_player_hurtbox()
        if not _player_hurtbox then return end
    end

    -- 检查碰撞箱是否仍然有效
    if _player_hurtbox:get_reference_count() == 1 then
        _player_hurtbox = nil
        _hurtbox_original_radius = nil
        _hurtbox_original_extent = nil
        return
    end

    -- 根据当前动作ID查找规则并应用
    local current_action_id = core._action_id
    local rule = current_rules[current_action_id]

    -- 如果没有规则，恢复默认大小
    if not rule then
        modify_hurtbox_size(_player_hurtbox, 1.0)
        return
    end

    -- 获取缩放倍率和帧范围
    local scale = 1.0
    if type(rule) == "number" then
        -- 兼容旧版本：直接存储的是倍率
        scale = rule
    else
        -- 新版本：rule 是一个表
        scale = rule.scale or 1.0

        -- 检查帧数范围
        if rule.frame_range then
            local current_frame = core._action_frame
            local start_frame = rule.frame_range[1]
            local end_frame = rule.frame_range[2]

            -- 如果当前帧不在范围内，恢复默认大小
            if current_frame < start_frame or current_frame > end_frame then
                modify_hurtbox_size(_player_hurtbox, 1.0)
                return
            end
        end
    end

    modify_hurtbox_size(_player_hurtbox, scale)
end

-- 为特定动作设置碰撞箱缩放倍率
---@param action_id number 动作ID
---@param scale_multiplier number|nil 缩放倍率（nil或1.0表示移除规则）
---@param frame_range table|nil 帧数范围，格式为 {start_frame, end_frame}，例如 {40, 100}
function player.set_hurtbox_scale(action_id, scale_multiplier, frame_range)
    -- 标记已初始化
    _hurtbox_initialized = true

    -- 获取当前武器类型
    local wep_type = core._wep_type
    if not wep_type then return end

    -- 创建武器类型表
    if not _hurtbox_scale_rules[wep_type] then
        _hurtbox_scale_rules[wep_type] = {}
    end

    -- 设置或移除规则
    if scale_multiplier == nil or scale_multiplier == 1.0 then
        _hurtbox_scale_rules[wep_type][action_id] = nil
    else
        _hurtbox_scale_rules[wep_type][action_id] = {
            scale = scale_multiplier,
            frame_range = frame_range
        }
    end
end

return player

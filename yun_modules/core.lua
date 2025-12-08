-- yun_modules/core.lua
-- 核心变量和游戏数据管理

local core = {}
local constant = require("yunwulian.yun_modules.constant")

-- 引用常量模块的枚举
core.weapon_type = constant.weapon_type
core.direction = constant.direction

-- 核心游戏对象单例
core.GuiManager = nil           -- GUI管理器
core.TimeScaleManager = nil     -- 时间缩放管理器
core.CameraManager = nil        -- 相机管理器
core.GameCamera = nil           -- 游戏相机
core.Pad = nil                  -- 手柄输入
core.PlayerManager = nil        -- 玩家管理器

-- 玩家状态变量
core.master_player = nil        -- 主玩家对象
core.master_player_index = nil  -- 主玩家索引
core.player_data = nil          -- 玩家数据
core.mPlObj = nil               -- 玩家游戏对象
core.mPlBHVT = nil              -- 玩家行为树
core.PlayerMotionCtrl = nil     -- 玩家动作控制

-- 动作状态变量
core._action_bank_id = nil      -- 动作库ID
core._action_id = nil           -- 当前动作ID
core._pre_action_id = nil       -- 前一个动作ID
core._pre_node_id = nil         -- 前一个节点ID
core._action_frame = nil        -- 当前动作帧
core._current_node = nil        -- 当前行为树节点
core._wep_type = nil            -- 武器类型
core._pre_wep_type = nil        -- 上一个武器类型
core._derive_start_frame = 0    -- 派生开始帧

-- 玩家属性
core._muteki_time = nil         -- 无敌时间
core._hyper_armor_time = nil    -- 霸体时间
core._atk = nil                 -- 攻击力
core._affinity = nil            -- 会心率
core._replace_atk_data = {}     -- 替换攻击数据

-- 动作值追踪
core._motion_value = nil                   -- 动作值
core._slash_axe_motion_value = 0           -- 斩击斧动作值
core._motion_value_id = nil                -- 动作值ID
core._slash_axe_motion_value_id = nil      -- 斩击斧动作值ID

-- 战斗交互
core._last_attacker_enemy = nil            -- 上一次攻击玩家的怪物实例

-- 攻击/会心率覆盖
core.player_atk = nil           -- 玩家攻击力
core.player_affinity = nil      -- 玩家会心率
core.atk_flag = false           -- 攻击力修改标志
core.affinity_flag = false      -- 会心率修改标志

-- 游戏状态标志
core.is_in_quest = false        -- 是否在任务中
core.is_loading_visiable = false -- 是否显示加载界面
core._should_draw_ui = false    -- 是否绘制UI

-- 动作改变回调
core.action_change_callbacks = {}

-- 武器切换回调
core.weapon_change_callbacks = {}

-- 初始化单例
function core.init_singletons()
    core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    core.TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager')
    core.CameraManager = sdk.get_managed_singleton("snow.CameraManager")
    core.GameCamera = sdk.get_managed_singleton("snow.GameCamera")
    core.Pad = sdk.get_managed_singleton('snow.Pad')
    core.PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
end

-- 更新游戏数据（每帧调用）
function core.update_game_data()
    if not core.master_player then return end

    -- 使用局部变量缓存频繁访问的数据以提高性能
    local success, player_index = pcall(function() return core.master_player:get_field("_PlayerIndex") end)
    if success then core.master_player_index = player_index end

    local game_object = core.master_player:get_GameObject()
    if game_object then
        core.mPlObj = game_object
        local bhvt = game_object:getComponent(sdk.typeof("via.behaviortree.BehaviorTree"))
        if bhvt then
            core.mPlBHVT = bhvt
        end
    end

    local player_data = core.master_player:get_PlayerData()
    if player_data then
        core.player_data = player_data
        core._atk = player_data:get_field("_Attack")
        core._affinity = player_data:get_field("_CriticalRate")
    end

    local wep_type = core.master_player:get_field("_playerWeaponType")
    if wep_type then
        -- 检测武器切换
        if core._wep_type ~= wep_type then
            core._pre_wep_type = core._wep_type
            core._wep_type = wep_type
            -- 触发武器切换回调
            if core._pre_wep_type ~= nil then
                core.trigger_weapon_change_callbacks(wep_type, core._pre_wep_type)
            end
        end
    end

    -- 更新UI标志（需要状态模块函数）
    -- core._should_draw_ui = enabled() and not is_pausing() and should_hud_show()

    -- 安全更新行为树节点信息
    if core.mPlBHVT then
        local current_node_id = core.mPlBHVT:getCurrentNodeID(0)
        if current_node_id then
            if core._current_node ~= current_node_id then
                core._pre_node_id = core._current_node
                core._current_node = current_node_id
            end
        end
    end

    -- 注意：动作帧数现在在hook中实时更新，不再在这里更新以避免滞后性
    -- 详见 core.hook_pre_late_update() 中的实时帧数更新

    -- 安全获取玩家状态
    local muteki_time = core.master_player:get_field("_MutekiTime")
    if muteki_time then core._muteki_time = muteki_time end

    local hyper_armor_time = core.master_player:get_field("_HyperArmorTimer")
    if hyper_armor_time then core._hyper_armor_time = hyper_armor_time end

    -- 安全获取替换攻击数据（优化：复用表，避免每帧创建新表）
    if not core._replace_atk_data then
        core._replace_atk_data = {}
    end

    local replace_fields = {"_replaceAttackTypeA", "_replaceAttackTypeB", "_replaceAttackTypeC",
                           "_replaceAttackTypeD", "_replaceAttackTypeE", "_replaceAttackTypeF"}
    for i, field in ipairs(replace_fields) do
        local value = core.master_player:get_field(field)
        core._replace_atk_data[i] = value or 0
    end
end

-- 查找并设置主玩家
---@return boolean 是否成功找到主玩家
function core.find_master_player()
    if not core.PlayerManager then
        core.PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
    end
    if not core.PlayerManager then return false end

    core.master_player = core.PlayerManager:findMasterPlayer()
    if not core.master_player or not core.master_player:isMasterPlayer() then
        core.master_player = nil
        return false
    end
    return true
end

-- ============================================================================
-- 直接帧数获取函数
-- ============================================================================

-- 直接获取当前动作帧（无滞后性，类似火焰片手剑的方式）
---@return number 当前动作帧
function core.get_current_frame()
    if not core.master_player then
        return 0
    end

    local motion_layer = core.master_player:getMotionLayer(0)
    if motion_layer then
        local frame = motion_layer:get_Frame()
        if frame then
            return math.floor(frame)
        end
    end

    return 0
end

-- 触发动作改变回调
function core.trigger_action_change_callbacks()
    for _, callback in ipairs(core.action_change_callbacks) do
        if type(callback) == "function" then
            pcall(callback)
        end
    end
end

-- 触发武器切换回调
function core.trigger_weapon_change_callbacks(new_type, old_type)
    for _, callback in ipairs(core.weapon_change_callbacks) do
        if type(callback) == "function" then
            pcall(callback, new_type, old_type)
        end
    end
end

-- ============================================================================
-- 钩子处理函数 - 由hooks.lua调用
-- ============================================================================

-- 钩子：动作ID改变检测
---@param args table 钩子参数
function core.hook_pre_late_update(args)
    local this = sdk.to_managed_object(args[2])
    local PlayerBase = this:get_field("_RefPlayerBase")

    if PlayerBase:isMasterPlayer() then
        -- 实时更新动作帧数（无滞后性）
        local motion_layer = PlayerBase:getMotionLayer(0)
        if motion_layer then
            local frame = motion_layer:get_Frame()
            if frame then
                core._action_frame = math.floor(frame)
            end
        end

        if core._action_id ~= this:get_field("_OldMotionID") then
            core._pre_action_id = core._action_id
            core._action_id = this:get_field("_OldMotionID")

            -- 触发动作改变回调
            core.trigger_action_change_callbacks()
        end
        core._action_bank_id = this:get_field("_OldBankID")
    end
end

-- 钩子：会心率控制
---@param args table 钩子参数
function core.hook_pre_calc_total_affinity(args)
    local this = sdk.to_managed_object(args[2])
    if not this:isMasterPlayer() then
        return sdk.PreHookResult.CALL_ORIGINAL
    end
end

function core.hook_post_calc_total_affinity(retval)
    if not core.master_player then return retval end
    if core.affinity_flag then
        core.player_data:set_field("_CriticalRate", core.player_affinity)
    end
    return retval
end

-- 钩子：动作值追踪（通用）
---@param args table 钩子参数
function core.hook_pre_get_adjust_stun_attack(args)
    local this = sdk.to_managed_object(args[2])
    local hitData = sdk.to_managed_object(args[3])
    if this:isMasterPlayer() then
        core._motion_value = hitData:get_field("_BaseDamage")
        core._motion_value_id = hitData:get_field("<RequestSetID>k__BackingField")
    end
end

-- 钩子：动作值追踪（斩击斧特定）
---@param args table 钩子参数
function core.hook_pre_slash_axe_get_adjust_stun_attack(args)
    local this = sdk.to_managed_object(args[2])
    local hitData = sdk.to_managed_object(args[3])
    if this:isMasterPlayer() then
        core._slash_axe_motion_value = hitData:get_field("_BaseDamage")
        core._slash_axe_motion_value_id = hitData:get_field("<RequestSetID>k__BackingField")
    end
end

-- 钩子：命令评估（按键按下检测）- 前置处理
---@param args table 钩子参数
function core.hook_pre_fsm_command_evaluate(args)
    local storage = thread.get_hook_storage()
    storage["commandbase"] = sdk.to_managed_object(args[2])
    storage["commandarg"] = sdk.to_managed_object(args[3])
    storage["cmdplayer"] = sdk.to_managed_object(args[2]):getPlayerBase(sdk.to_managed_object(args[3]))
end

-- 钩子：反击检测 - 前置处理
---@param args table 钩子参数
function core.hook_pre_check_calc_damage(args)
    local storage = thread.get_hook_storage()
    local hitInfo = sdk.to_managed_object(args[3])

    storage["refPlayer"] = sdk.to_managed_object(args[2])

    local damageData = hitInfo:get_AttackData()
    storage["damageData"] = damageData

    -- 提取攻击者怪物实例（过滤掉 shell）
    local attackObject = hitInfo:get_AttackObject()
    if attackObject and damageData then
        local ownerType = damageData:get_OwnerType()

        if ownerType == 1 then  -- 1 = Enemy (真实怪物)
            local enemyCharacter = attackObject:getComponent(
                sdk.typeof("snow.enemy.EnemyCharacterBase"))
            if enemyCharacter then
                storage["attackerEnemy"] = enemyCharacter
                core._last_attacker_enemy = enemyCharacter
            end
        elseif ownerType == 2 then  -- 2 = EnemyShell (远程攻击)
            -- 清空攻击者，避免反击错误的怪物
            storage["attackerEnemy"] = nil
            core._last_attacker_enemy = nil
        end
    end
end

function core.hook_post_check_calc_damage(retval)
    if not thread.get_hook_storage()["refPlayer"]:isMasterPlayer() then
        return retval
    end
    return retval
end

-- ============================================================================
-- 战斗交互函数
-- ============================================================================

-- 获取上一次攻击玩家的怪物实例
---@return any|nil 怪物实例，如果没有则返回nil
function core.get_last_attacker_enemy()
    return core._last_attacker_enemy
end

-- 获取上一个武器类型
---@return number|nil 上一个武器类型
function core.get_pre_weapon_type()
    return core._pre_wep_type
end

return core

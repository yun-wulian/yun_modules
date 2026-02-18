-- yun_modules/hooks.lua
-- SDK钩子管理 - 优雅的分发器模式

local hooks = {}
local core = require("yunwulian.yun_modules.core")
local action = require("yunwulian.yun_modules.action")
local derive = require("yunwulian.yun_modules.derive")
local state = require("yunwulian.yun_modules.state")
local effects = require("yunwulian.yun_modules.effects")

local enabled = false

-- ============================================================================
-- 钩子前置处理函数声明
-- ============================================================================

local pre_hook_late_update = function(args)
    -- 调用core的hook函数来实时更新帧数和其他数据
    core.hook_pre_late_update(args)
end

local pre_hook_calc_total_affinity = function(args)
    local this = sdk.to_managed_object(args[2])
    local storage = thread.get_hook_storage()
    local is_master = this ~= nil and this:isMasterPlayer() == true
    storage["isMasterPlayer_calcTotalAffinity"] = is_master

    if not is_master then
        return sdk.PreHookResult.CALL_ORIGINAL
    end
end

local post_hook_calc_total_affinity = function(retval)
    if not thread.get_hook_storage()["isMasterPlayer_calcTotalAffinity"] then
        return retval
    end
    return core.hook_post_calc_total_affinity(retval)
end

local pre_hook_calc_total_attack = function(args)
    local this = sdk.to_managed_object(args[2])
    local storage = thread.get_hook_storage()
    storage["isMasterPlayer_calcTotalAttack"] = this ~= nil and this:isMasterPlayer() == true
end

local post_hook_calc_total_attack = function(retval)
    if not thread.get_hook_storage()["isMasterPlayer_calcTotalAttack"] then
        return retval
    end
    return derive.hook_post_calc_total_attack(retval)
end

local pre_hook_get_adjust_stun_attack = function(args)
    local this = sdk.to_managed_object(args[2])
    if not this:isMasterPlayer() then
        return sdk.PreHookResult.CALL_ORIGINAL
    end
    return core.hook_pre_get_adjust_stun_attack(args)
end

local pre_hook_slash_axe_get_adjust_stun_attack = function(args)
    local this = sdk.to_managed_object(args[2])
    if not this:isMasterPlayer() then
        return sdk.PreHookResult.CALL_ORIGINAL
    end
    return core.hook_pre_slash_axe_get_adjust_stun_attack(args)
end

local pre_hook_quest_status_change = function(args)
    return state.hook_pre_quest_status_change(args)
end

local post_hook_quest_status_change = function(retval)
    return retval
end

local pre_hook_loading_update = function(args)
    return state.hook_pre_loading_update(args)
end

local post_hook_loading_update = function(retval)
    return retval
end

local pre_hook_fsm_command_evaluate = function(args)
    local storage = thread.get_hook_storage()
    storage["commandbase"] = sdk.to_managed_object(args[2])
    storage["commandarg"] = sdk.to_managed_object(args[3])
    storage["cmdplayer"] = sdk.to_managed_object(args[2]):getPlayerBase(sdk.to_managed_object(args[3]))
    return core.hook_pre_fsm_command_evaluate(args)
end

local post_hook_fsm_command_evaluate = function(retval)
    local commandbase = thread.get_hook_storage()["commandbase"]
    local commandarg = thread.get_hook_storage()["commandarg"]
    local cmdplayer = thread.get_hook_storage()["cmdplayer"]

    if not cmdplayer:isMasterPlayer() then return retval end

    if sdk.to_int64(retval) == 1 then
        retval = derive.hook_evaluate_post_command(retval, commandbase, commandarg)
    end

    return retval
end

local pre_hook_check_calc_damage = function(args)
    local storage = thread.get_hook_storage()
    storage["Player"] = sdk.to_managed_object(args[2])
    return core.hook_pre_check_calc_damage(args)
end

local post_hook_check_calc_damage = function(retval)
    if not thread.get_hook_storage()["Player"]:isMasterPlayer() then
        return retval
    end
    return derive.hook_post_check_calc_damage(retval)
end

local pre_hook_after_calc_damage = function(args)
    if not sdk.to_managed_object(args[2]):isMasterPlayer() then return end
    local hitInfo = sdk.to_managed_object(args[4])
    derive.hook_pre_after_calc_damage(hitInfo)
end

local pre_hook_enemy_damage = function(args)
    local from = sdk.to_managed_object(args[4]):get_AttackObject()
    if from == nil or from:get_type_definition() ~= sdk.find_type_definition("snow.player.PlayerBase") or not from:isMasterPlayer() then return end
    effects.hook_pre_enemy_damage(args)
end

local pre_hook_radial_blur_enabled = function(args)
    effects.hook_pre_radial_blur_enabled(args)
end

local post_hook_radial_blur_enabled = function(retval)
    return retval
end

local pre_hook_radial_blur_apply = function()
    effects.hook_pre_radial_blur_apply()
end

local post_hook_radial_blur_apply = function(retval)
    return retval
end

local pre_hook_attack_work_activate = function(args)
    local this = sdk.to_managed_object(args[2])
    if core.master_player ~= nil and core.master_player:getRSCController() ~= this:get_RSCCtrl() then
        return
    end
    effects.hook_pre_attack_work_activate(args)
end

local pre_hook_attack_work_destroy = function(args)
    local this = sdk.to_managed_object(args[2])
    if core.master_player ~= nil and core.master_player:getRSCController() ~= this:get_RSCCtrl() then
        return
    end
    effects.hook_pre_attack_work_destroy(args)
end


-- ============================================================================
-- 钩子注册和启用/禁用
-- ============================================================================

function hooks.enable()
    if enabled then
        return
    end

    -- 钩子：动作ID改变检测
    sdk.hook(sdk.find_type_definition("snow.player.PlayerMotionControl"):get_method("lateUpdate"), pre_hook_late_update)

    -- 钩子：会心率控制
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAffinity"), pre_hook_calc_total_affinity, post_hook_calc_total_affinity)

    -- 钩子：攻击控制
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAttack"), pre_hook_calc_total_attack, post_hook_calc_total_attack)

    -- 钩子：元素伤害倍率
    sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("getElementSharpnessAdjust"), nil, function(retval) return derive.hook_post_element_sharpness_adjust(retval) end)

    -- 钩子：眩晕伤害倍率
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("getAdjustTotalStunAttack"), nil, function(retval) return derive.hook_post_adjust_total_stun_attack(retval) end)

    -- 钩子：耐力伤害倍率
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("getAdjustTotalStaminaAttack"), nil, function(retval) return derive.hook_post_adjust_total_stamina_attack(retval) end)

    -- 钩子：加载屏幕检测
    sdk.hook(sdk.find_type_definition("snow.NowLoading"):get_method("update"), pre_hook_loading_update, post_hook_loading_update)

    -- 钩子：任务状态改变
    sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("onChangedGameStatus"), pre_hook_quest_status_change, post_hook_quest_status_change)

    -- 钩子：动作值追踪（通用）
    sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("getAdjustStunAttack"), pre_hook_get_adjust_stun_attack)

    -- 钩子：动作值追踪（斩击斧特定）
    sdk.hook(sdk.find_type_definition("snow.player.SlashAxe"):get_method("getAdjustStunAttack"), pre_hook_slash_axe_get_adjust_stun_attack)

    -- 钩子：命令评估（按键按下检测）
    sdk.hook(sdk.find_type_definition("snow.player.fsm.PlayerFsm2CommandBase"):get_method("evaluate"), pre_hook_fsm_command_evaluate, post_hook_fsm_command_evaluate)

    -- 钩子：反击检测
    sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("checkCalcDamage_DamageSide"), pre_hook_check_calc_damage, post_hook_check_calc_damage)

    -- 钩子：命中检测
    sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("afterCalcDamage_AttackSide"), pre_hook_after_calc_damage)

    -- 钩子：命中特效（敌人受伤时触发）
    sdk.hook(sdk.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("afterCalcDamage_DamageSide"), pre_hook_enemy_damage)

    -- 钩子：径向模糊 - 记录原始启用状态
    sdk.hook(sdk.find_type_definition("snow.SnowPostEffectParam.SnowLDRPostProcess.SnowLDRRadialBlur"):get_method("set_Enabled"), pre_hook_radial_blur_enabled, post_hook_radial_blur_enabled)

    -- 钩子：径向模糊 - 应用参数
    sdk.hook(sdk.find_type_definition("snow.SnowPostEffectParam.SnowLDRPostProcess"):get_method("applyParameters"), pre_hook_radial_blur_apply, post_hook_radial_blur_apply)

    -- 钩子：攻击判定激活（攻击判定产生时触发，会持续调用）
    sdk.hook(sdk.find_type_definition("snow.hit.AttackWork"):get_method("activate"), pre_hook_attack_work_activate)

    -- 钩子：攻击判定销毁（攻击判定结束时触发）
    sdk.hook(sdk.find_type_definition("snow.hit.AttackWork"):get_method("destroy"), pre_hook_attack_work_destroy)

    enabled = true
end

-- 注意：REFramework 的 hook 是叠加制的，无法通过添加空钩子来禁用
-- yunwulian 的钩子设计为持续运行，不需要禁用
function hooks.disable()
    -- 保留接口但不执行任何操作
end

return hooks

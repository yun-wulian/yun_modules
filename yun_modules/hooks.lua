-- yun_modules/hooks.lua
-- SDK hooks management

local hooks = {}
local core = require("yunwulian.yun_modules.core")
local action = require("yunwulian.yun_modules.action")
local derive = require("yunwulian.yun_modules.derive")
local state = require("yunwulian.yun_modules.state")

-- Initialize all SDK hooks
function hooks.init()
    -- Hook for action ID change detection
    sdk.hook(sdk.find_type_definition("snow.player.PlayerMotionControl"):get_method("lateUpdate"),
        function(args)
            local this = sdk.to_managed_object(args[2])
            local PlayerBase = this:get_field("_RefPlayerBase")

            if PlayerBase:isMasterPlayer() then
                if core._action_id ~= this:get_field("_OldMotionID") then
                    core._pre_action_id = core._action_id
                    core._action_id = this:get_field("_OldMotionID")
                    for _, func in ipairs(action.action_change_functions) do
                        func()
                    end
                    derive.on_action_change()
                end
                core._action_bank_id = this:get_field("_OldBankID")
            end
        end)

    -- Hook for attack control
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAttack"),
        function(args) end,
        function(retval)
            if not core.master_player then return end
            if core.atk_flag then
                core.player_data:set_field("_Attack", core.player_atk)
            end
            local derive_atk_data = derive.get_derive_atk_data()
            if derive_atk_data["atkMult"] ~= nil then
                core.player_data:set_field("_Attack", core.player_data:get_field("_Attack") * derive_atk_data["atkMult"][1])
            end
        end)

    -- Hook for affinity control
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAffinity"),
        function(args) end,
        function(retval)
            if not core.master_player then return end
            if core.affinity_flag then
                core.player_data:set_field("_CriticalRate", core.player_affinity)
            end
        end)

    -- Hook for element damage multiplier
    sdk.hook(
        sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method(
        "getElementSharpnessAdjust(snow.hit.userdata.PlHitAttackRSData, snow.CharacterBase)"),
        function(args) end,
        function(retval)
            local derive_atk_data = derive.get_derive_atk_data()
            if derive_atk_data["eleMult"] ~= nil then
                local eleValue = sdk.to_float(retval)
                return sdk.float_to_ptr(eleValue * derive_atk_data["eleMult"][1])
            end
            return retval
        end)

    -- Hook for stun damage multiplier
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("getAdjustTotalStunAttack(System.Single)"),
        function(args) end,
        function(retval)
            local derive_atk_data = derive.get_derive_atk_data()
            if derive_atk_data["stunMult"] ~= nil then
                local stunMult = sdk.to_float(retval)
                return sdk.float_to_ptr(stunMult * derive_atk_data["stunMult"][1])
            end
            return retval
        end)

    -- Hook for stamina damage multiplier
    sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("getAdjustTotalStaminaAttack(System.Single)"),
        function(args) end,
        function(retval)
            local derive_atk_data = derive.get_derive_atk_data()
            if derive_atk_data["staMult"] ~= nil then
                local staMult = sdk.to_float(retval)
                return sdk.float_to_ptr(staMult * derive_atk_data["staMult"][1])
            end
            return retval
        end)

    -- Hook for loading screen detection
    sdk.hook(sdk.find_type_definition("snow.NowLoading"):get_method("update"), function(args)
            local this = sdk.to_managed_object(args[2])
            core.is_loading_visiable = this:call("getVisible")
        end,
        function(retval) return retval end)

    -- Hook for quest status change
    sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("onChangedGameStatus"),
        function(args)
            local new_quest_status = sdk.to_int64(args[3])
            if new_quest_status ~= nil then
                if new_quest_status == 2 then
                    core.is_in_quest = true
                else
                    core.is_in_quest = false
                end
            end
            for _, func in ipairs(state.quest_change_functions) do
                func()
            end
        end,
        function(retval) return retval end)

    -- Hook for motion value tracking (general)
    sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("getAdjustStunAttack"),
        function(args)
            local this = sdk.to_managed_object(args[2])
            local hitData = sdk.to_managed_object(args[3])
            if this:isMasterPlayer() then
                core._motion_value = hitData:get_field("_BaseDamage")
                core._motion_value_id = hitData:get_field("<RequestSetID>k__BackingField")
            end
        end)

    -- Hook for motion value tracking (SlashAxe specific)
    sdk.hook(sdk.find_type_definition("snow.player.SlashAxe"):get_method("getAdjustStunAttack"),
        function(args)
            local this = sdk.to_managed_object(args[2])
            local hitData = sdk.to_managed_object(args[3])
            if this:isMasterPlayer() then
                core._slash_axe_motion_value = hitData:get_field("_BaseDamage")
                core._slash_axe_motion_value_id = hitData:get_field("<RequestSetID>k__BackingField")
            end
        end)

    -- Hook for command evaluation (key press detection)
    sdk.hook(
        sdk.find_type_definition("snow.player.fsm.PlayerFsm2CommandBase"):get_method("evaluate"),
        function(args)
            local storage = thread.get_hook_storage()
            storage["commandbase"] = sdk.to_managed_object(args[2])
            storage["commandarg"] = sdk.to_managed_object(args[3])
            storage["cmdplayer"] = sdk.to_managed_object(args[2]):getPlayerBase(sdk.to_managed_object(args[3]))
        end,
        function(retval)
            local commandbase = thread.get_hook_storage()["commandbase"]
            local commandarg = thread.get_hook_storage()["commandarg"]
            local cmdplayer = thread.get_hook_storage()["cmdplayer"]
            if cmdplayer:isMasterPlayer() then
                if sdk.to_int64(retval) == 1 then
                    local cmd_type = commandbase:get_field("CmdType")
                    local transition = commandarg:get_TransitionID()
                    derive.set_this_derive_cmd(cmd_type)

                    local ignore_keys = derive.get_ignore_keys()
                    local this_is_by_action_id = derive.get_this_is_by_action_id()

                    if this_is_by_action_id and ignore_keys[core._action_id] ~= nil then
                        for _, value in ipairs(ignore_keys[core._action_id]) do
                            if cmd_type == value then
                                return sdk.to_ptr(0)
                            end
                        end
                    elseif not this_is_by_action_id and ignore_keys[core._current_node] ~= nil then
                        for _, value in ipairs(ignore_keys[core._current_node]) do
                            if cmd_type == value then
                                return sdk.to_ptr(0)
                            end
                        end
                    end
                    if commandbase:get_field("StartFrame") > 1 then
                        derive.set_derive_start_frame(commandbase:get_field("StartFrame"))
                    end
                    for _, func in ipairs(derive.hook_evaluate_post) do
                        retval = func(retval, commandbase, commandarg)
                    end
                end
            end
            return retval
        end)

    -- Hook for counter attack detection
    sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("checkCalcDamage_DamageSide"),
        function(args)
            local storage = thread.get_hook_storage()
            storage["refPlayer"] = sdk.to_managed_object(args[2])
            storage["damageData"] = sdk.to_managed_object(args[3]):get_AttackData()
        end,
        function(retval)
            if not thread.get_hook_storage()["refPlayer"]:isMasterPlayer() then
                return retval
            end
            local dmgOwnerType = thread.get_hook_storage()["damageData"]:get_OwnerType()
            if (dmgOwnerType == 1 or dmgOwnerType == 0) then
                local hit_counter_info = derive.get_hit_counter_info()
                if next(hit_counter_info) ~= nil then
                    local frameInfo = hit_counter_info[3]
                    if frameInfo and core._action_frame > frameInfo[1] and core._action_frame < frameInfo[2] then
                        if hit_counter_info[2] > 0 then
                            hit_counter_info[2] = hit_counter_info[2] - 1
                            if hit_counter_info[1] then
                                derive.set_counter_success(true)
                            end
                            return sdk.to_ptr(2)
                        end
                    end
                end
            end
            return retval
        end)

    -- Hook for hit detection
    sdk.hook(
        sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method(
        "afterCalcDamage_AttackSide(snow.hit.DamageFlowInfoBase, snow.DamageReceiver.HitInfo)"),
        function(args)
            local hitInfo = sdk.to_managed_object(args[4])
            local damageData = hitInfo:call("get_AttackData")
            local dmgOwnerType = damageData:call("get_OwnerType")
            if dmgOwnerType == 2 then
                local need_hit_info = derive.get_need_hit_info()
                if next(need_hit_info) ~= nil and need_hit_info ~= nil then
                    if need_hit_info[1] == core._action_id and need_hit_info[2] <= core._derive_start_frame then
                        derive.set_hit_success(core._action_frame)
                    end
                end
                local derive_atk_data = derive.get_derive_atk_data()
                if next(derive_atk_data) ~= nil then
                    for key, subtable in pairs(derive_atk_data) do
                        if subtable[2] > 1 then
                            subtable[2] = subtable[2] - 1
                        else
                            derive_atk_data[key] = nil
                        end
                    end
                end
            end
        end)
end

return hooks

local yun_modules = {}

local master_player
local master_player_index
local player_data
local _action_bank_id
local _action_id
local _pre_action_id
local _action_frame
local _current_node
local _muteki_time
local _hyper_armor_time
local _atk
local _affinity
local _replace_atk_data = {}
local _wep_type

local _should_draw_ui

local mPlObj
local mPlBHVT
local PlayerMotionCtrl

local _motion_value
local _slash_axe_motion_value = 0
local _motion_value_id
local _slash_axe_motion_value_id

local player_atk
local player_affinity
local atk_flag = false
local affinity_flag = false

local GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
local TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager')
local CameraManager = sdk.get_managed_singleton("snow.CameraManager")
local Pad = sdk.get_managed_singleton('snow.Pad')
local is_in_quest = false

yun_modules.weapon_type = {
    GreatSword = 0,
    SlashAxe = 1,
    LongSword = 2,
    LightBowGun = 3,
    HeavyBowGun = 4,
    Hammer = 5,
    GunLance = 6,
    Lance = 7,
    ShortSword = 8,
    DualBlade = 9,
    Horn = 10,
    ChargeAxe = 11,
    InsectGlaive = 12,
    Bow = 13
}

yun_modules.direction = {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
    RightUp = 4,
    RightDown = 5,
    LeftUp = 6,
    LeftDown = 7
}

local function on_action_change()
    PlayerMotionCtrl = master_player:get_field("_RefPlayerMotionCtrl")
    if _action_id ~= PlayerMotionCtrl:call("get_OldMotionID") then
        _pre_action_id = _action_id
        _action_id = PlayerMotionCtrl:call("get_OldMotionID")
        _action_bank_id = PlayerMotionCtrl:call("get_OldBankID")
        return _action_id
    end
end

local function get_game_data()
    master_player_index = master_player:get_field("_PlayerIndex")
    mPlObj = master_player:call("get_GameObject")
    mPlBHVT = mPlObj:call("getComponent(System.Type)", sdk.typeof("via.behaviortree.BehaviorTree"))
    player_data = master_player:call("get_PlayerData")
    _wep_type = master_player:get_field("_playerWeaponType")
    _should_draw_ui = yun_modules.enabled() and not yun_modules.is_pausing() and yun_modules.should_hud_show()
    _atk = player_data:get_field("_Attack")
    _current_node = mPlBHVT:call("getCurrentNodeID", 0)
    _action_frame = master_player:call("getMotionLayer", 0):call("get_Frame")
    _affinity = player_data:get_field("_CriticalRate")
    _muteki_time = master_player:get_field("_MutekiTime")
    _replace_atk_data = { master_player:get_field("_replaceAttackTypeA"), master_player:get_field("_replaceAttackTypeB"),
        master_player:get_field("_replaceAttackTypeC"), master_player:get_field("_replaceAttackTypeD"),
        master_player:get_field("_replaceAttackTypeE"), master_player:get_field("_replaceAttackTypeF") }
    _hyper_armor_time = master_player:get_field("_HyperArmorTimer")
    on_action_change()
end

function yun_modules.check_using_weapon_type(tar_type)
    if _wep_type == tar_type then return true end
    return false
end

function yun_modules.get_master_player()
    if master_player ~= nil then
        return master_player
    end
end

function yun_modules.get_master_player_index()
    if master_player_index ~= nil then
        return master_player_index
    end
end

function yun_modules.set_current_node(node_hash)
    if not master_player then return end
    mPlBHVT:call("setCurrentNode", node_hash, nil, nil)
end

function yun_modules.check_action_table(action_table, bank_id)
    if not bank_id then
        bank_id = 100
    end

    if _action_bank_id == bank_id then
        for i = 1, #action_table do
            if _action_id == action_table[i] then
                return true
            end
        end
        return false
    else
        return false
    end
end

function yun_modules.set_effect(contianer, efx)
    if not master_player then return end
    master_player:call("setItemEffect", contianer, efx)
end

function yun_modules.set_camera_vibration(index, priority)
    if not CameraManager then return end
    if not master_player then return end
    CameraManager:get_RefCameraVibration():RequestVibration_Player(master_player, index, priority)
end

function yun_modules.check_equip_skill_lv(skill)
    if not master_player then return end
    local skill_list = master_player:call("get_PlayerSkillList")
    for i = 7, 1, -1 do
        if skill_list:call("hasSkill", skill, i) then
            return i
        end
    end
    return 0
end

sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAttack"),
    function(args) end,
    function(retval)
        if not master_player then return end
        if atk_flag then
            player_data:set_field("_Attack", player_atk)
        end
    end)

sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAffinity"),
    function(args) end,
    function(retval)
        if not master_player then return end
        if affinity_flag then
            player_data:set_field("_CriticalRate", player_affinity)
        end
    end)
--在使用set atk函数之后会循环执行，因此一定要记得调用clear函数!
function yun_modules.set_atk(value)
    atk_flag = true
    player_atk = value
end

--在使用set affinity函数之后会循环执行，因此一定要记得调用clear函数!
function yun_modules.set_affinity(value)
    affinity_flag = true
    player_affinity = value
end

function yun_modules.clear_atk()
    atk_flag = false
end

function yun_modules.clear_affinity()
    affinity_flag = false
end

function yun_modules.get_atk()
    if not master_player then return 0 end
    return _atk
end

function yun_modules.get_affinity()
    if not master_player then return 0 end
    return _affinity
end

function yun_modules.get_motion_value()
    if not _motion_value or not _slash_axe_motion_value then return 0 end
    if yun_modules.check_using_weapon_type(yun_modules.weapon_type.SlashAxe) then
        return _slash_axe_motion_value
    end
    return _motion_value
end

function yun_modules.get_motion_value_id()
    if not _motion_value_id and not _slash_axe_motion_value_id then return 0 end
    if yun_modules.check_using_weapon_type(yun_modules.weapon_type.SlashAxe) then
        return _slash_axe_motion_value_id
    end
    return _motion_value_id
end

function yun_modules.get_action_id()
    if _action_id then
        return _action_id
    end
    return 0
end

function yun_modules.get_pre_action_id()
    if _pre_action_id then
        return _pre_action_id
    end
    return 0
end

function yun_modules.get_action_bank_id()
    if _action_bank_id then
        return _action_bank_id
    end
    return 0
end

function yun_modules.get_now_action_frame()
    if not master_player then return end
    return _action_frame
end

function yun_modules.set_now_action_frame(frame)
    if not master_player then return end
    return master_player:call("getMotionLayer", 0):call("set_Frame", frame)
end

function yun_modules.get_weapon_type()
    if not master_player then return end
    return _wep_type
end

function yun_modules.get_current_node()
    if _current_node then
        return _current_node
    else
        return 0
    end
end

function yun_modules.get_muteki_time()
    if not master_player then return end
    return _muteki_time
end

function yun_modules.set_muteki_time(value)
    if not master_player then return end
    return master_player:set_field("_MutekiTime", value)
end

function yun_modules.get_replace_attack_data()
    if not master_player then return end
    return _replace_atk_data
end

function yun_modules.get_hyper_armor_time()
    if not master_player then return end
    return _hyper_armor_time
end

function yun_modules.set_hyper_armor_time(value)
    if not master_player then return end
    return master_player:set_field("_HyperArmorTimer", value)
end

function yun_modules.is_push_lstick()
    local is_push_lstick = false
    for i = 0, 7 do
        is_push_lstick = master_player:call('get_RefPlayerInput'):call("checkAnaLever", i)
        if is_push_lstick then return true end
    end
    return false
end

function yun_modules.turn_to_lstick_dir(range)
    local is_push_lstick = false
    for i = 0, 7 do
        is_push_lstick = master_player:call('get_RefPlayerInput'):call("checkAnaLever", i)
        if is_push_lstick then break end
    end
    if not is_push_lstick then return end
    local input_angle = master_player:call('get_RefPlayerInput'):call("getHormdirLstick")
    local player_angle = master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")
    range = math.rad(range)

    if range >= 180.0 then
        master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", input_angle)
        return
    end

    local delta_angle_sin = math.sin(input_angle - player_angle)
    local delta_angle_cos = math.cos(input_angle - player_angle)

    if delta_angle_cos > math.cos(range) then
        master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", input_angle)
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
            master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", left_target)
        else
            master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", right_target)
        end
    end
end

function yun_modules.check_lstick_dir(direction)
    if not master_player then return false end
    if master_player:call('get_RefPlayerInput'):call("checkAnaLever", direction) then
        return true
    else
        return false
    end
end

function yun_modules.check_lstick_dir_for_player(direction)
    if not yun_modules.is_push_lstick() then return false end
    local player_angle = master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")
    local input_angle = master_player:call('get_RefPlayerInput'):call("getHormdirLstick")

    local delta_angle_sin = math.sin(input_angle - player_angle)
    local delta_angle_cos = math.cos(input_angle - player_angle)

    if direction == yun_modules.direction.Down then
        if delta_angle_sin > math.sin(math.rad(-22.5)) and delta_angle_sin < math.sin(math.rad(22.5)) and delta_angle_cos < 0 then return true end
    elseif direction == yun_modules.direction.Up then
        if delta_angle_sin > math.sin(math.rad(-22.5)) and delta_angle_sin < math.sin(math.rad(22.5)) and delta_angle_cos > 0 then return true end
    elseif direction == yun_modules.direction.Right then
        if delta_angle_cos > math.sin(math.rad(-22.5)) and delta_angle_cos < math.sin(math.rad(22.5)) and delta_angle_sin < 0 then return true end
    elseif direction == yun_modules.direction.Left then
        if delta_angle_cos > math.sin(math.rad(-22.5)) and delta_angle_cos < math.sin(math.rad(22.5)) and delta_angle_sin > 0 then return true end
    elseif direction == yun_modules.direction.LeftDown then
        if delta_angle_sin > math.sin(math.rad(22.5)) and delta_angle_sin < math.sin(math.rad(67.5)) and delta_angle_cos < 0 then return true end
    elseif direction == yun_modules.direction.LeftUp then
        if delta_angle_sin > math.sin(math.rad(22.5)) and delta_angle_sin < math.sin(math.rad(67.5)) and delta_angle_cos > 0 then return true end
    elseif direction == yun_modules.direction.RightDown then
        if delta_angle_sin > math.sin(math.rad(-67.5)) and delta_angle_sin < math.sin(math.rad(-22.5)) and delta_angle_cos < 0 then return true end
    elseif direction == yun_modules.direction.RightUp then
        if delta_angle_sin > math.sin(math.rad(-67.5)) and delta_angle_sin < math.sin(math.rad(-22.5)) and delta_angle_cos > 0 then return true end
    end

    return false
end

function yun_modules.check_lstick_dir_for_player_only_quad(direction)
    if not yun_modules.is_push_lstick() then return false end
    local player_angle = master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")
    local input_angle = master_player:call('get_RefPlayerInput'):call("getHormdirLstick")

    local delta_angle_sin = math.sin(input_angle - player_angle)
    local delta_angle_cos = math.cos(input_angle - player_angle)

    if direction == yun_modules.direction.Down then
        if delta_angle_sin > math.sin(math.rad(-45)) and delta_angle_sin < math.sin(math.rad(45)) and delta_angle_cos < 0 then return true end
    elseif direction == yun_modules.direction.Up then
        if delta_angle_sin > math.sin(math.rad(-45)) and delta_angle_sin < math.sin(math.rad(45)) and delta_angle_cos > 0 then return true end
    elseif direction == yun_modules.direction.Right then
        if delta_angle_cos > math.sin(math.rad(-45)) and delta_angle_cos < math.sin(math.rad(45)) and delta_angle_sin < 0 then return true end
    elseif direction == yun_modules.direction.Left then
        if delta_angle_cos > math.sin(math.rad(-45)) and delta_angle_cos < math.sin(math.rad(45)) and delta_angle_sin > 0 then return true end
    end

    return false
end

function yun_modules.move_to_lstick_dir(action_id, frame_range, no_move_frame, move_multipier, dir_limit)
    if _action_id == action_id then
        local motion = master_player:getMotion()
        local temp_vec3 = motion:get_RootMotionTranslation()
        local input_angle = master_player:call('get_RefPlayerInput'):call("getHormdirLstick")
        local move_distance = math.sqrt(temp_vec3.x ^ 2 + temp_vec3.z ^ 2)
        if move_multipier then
            move_distance = move_distance * move_multipier
        end
        if no_move_frame then
            if _action_frame < no_move_frame then
                temp_vec3.x = -temp_vec3.x
                temp_vec3.z = -temp_vec3.z
            end
        end
        if _action_frame < frame_range then
            if yun_modules.is_push_lstick() then
                if dir_limit ~= nil then
                    if not yun_modules.check_lstick_dir_for_player(dir_limit) then
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

function yun_modules.check_input_by_isOn(cmd)
    if not master_player then return false end
    return master_player:call('get_RefPlayerInput'):call("get_mNow"):call("isOn", cmd)
end

function yun_modules.check_input_by_isCmd(cmd)
    if not master_player then return false end
    return master_player:call('get_RefPlayerInput'):call("isCmd", sdk.to_ptr(cmd))
end

function yun_modules.analog_derive(tar_action_id, tar_action_bank_id, tar_cmd, is_by_isCmd, tar_lstick_dir,
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
        if _action_bank_id == derive.tar_action_bank_id and _action_id == derive.tar_action_id and yun_modules.get_now_action_frame() >= derive.pre_frame then
            if not derive.pre_input_flag then
                if derive.is_by_isCmd then
                    if not yun_modules.check_input_by_isCmd(tar_cmd) then
                        return
                    end
                else
                    if not yun_modules.check_input_by_isOn(tar_cmd) then
                        return
                    end
                end
                if derive.tar_lstick_dir then
                    if derive.is_by_player_dir then
                        if not yun_modules.check_lstick_dir_for_player_only_quad(derive.tar_lstick_dir) or derive.turn_range then
                            return
                        end
                    else
                        if not yun_modules.check_lstick_dir(derive.tar_lstick_dir) or derive.turn_range then
                            return
                        end
                    end
                end
                derive.pre_input_flag = true
                if derive.turn_range then
                    yun_modules.turn_to_lstick_dir(derive.turn_range)
                end
            end
        end
    end

    function derive.analog_derive_to_target()
        if derive.pre_input_flag and derive.tar_node_hash ~= 0 and yun_modules.get_now_action_frame() >= start_frame and _action_id == derive.tar_action_id then
            yun_modules.set_current_node(derive.tar_node_hash)
            derive.pre_input_flag = false
        end
    end

    function derive.analog_jmp_frame()
        if derive.tar_node_hash == yun_modules.get_current_node() and derive.jmp_frame ~= nil and pre_action_id == derive.tar_action_id and yun_modules.get_now_action_frame() > 0.0 and yun_modules.get_now_action_frame() < derive.jmp_frame then
            yun_modules.set_now_action_frame(derive.jmp_frame)
        end
    end

    if _action_id == derive.tar_action_id then
        derive.analog_input()
        derive.analog_derive_to_target()
    else
        derive.analog_jmp_frame()
    end
end

local is_loading_visiable = false
sdk.hook(sdk.find_type_definition("snow.NowLoading"):get_method("update"), function(args)
        local this = sdk.to_managed_object(args[2])
        is_loading_visiable = this:call("getVisible")
    end,
    function(retval) return retval end)

function yun_modules.should_hud_show()
    if not GuiManager then GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager') end
    if not GuiManager then return end
    return not GuiManager:call("IsStartMenuAndSubmenuOpen") and not GuiManager:get_field("InvisibleAllGUI") and
        GuiManager:call("isOpenHudSharpness")
end

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("onChangedGameStatus"),
    function(args)
        local new_quest_status = sdk.to_int64(args[3]);
        if new_quest_status ~= nil then
            if new_quest_status == 2 then
                is_in_quest = true
            else
                is_in_quest = false
            end
        end
    end
    , function(retval) return retval end)

function yun_modules.is_in_quest()
    if not GuiManager then GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager') end
    if not GuiManager then return end
    return is_in_quest or GuiManager:call("isOpenHudSharpness")
end

function yun_modules.is_pausing()
    if not TimeScaleManager then TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager') end
    return TimeScaleManager:call("get_Pausing")
end

function yun_modules.enabled()
    return yun_modules.is_in_quest() and not is_loading_visiable
end

function yun_modules.should_draw_ui()
    return _should_draw_ui
end

function yun_modules.set_pad_vibration(id, is_loop)
    if not is_loop then is_loop = false end
    if not Pad then return end
    Pad:requestVibration(id, is_loop)
end

sdk.hook(sdk.find_type_definition("snow.player.PlayerQuestBase"):get_method("getAdjustStunAttack"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        local hitData = sdk.to_managed_object(args[3])
        local cur_atk_owner_index = this:get_field("_PlayerIndex")
        if yun_modules.get_master_player_index() == cur_atk_owner_index then
            _motion_value = hitData:get_field("_BaseDamage")
            _motion_value_id = hitData:get_field("<RequestSetID>k__BackingField")
        end
    end
)

sdk.hook(sdk.find_type_definition("snow.player.SlashAxe"):get_method("getAdjustStunAttack"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        local hitData = sdk.to_managed_object(args[3])
        local cur_atk_owner_index = this:get_field("_PlayerIndex")
        if yun_modules.get_master_player_index() == cur_atk_owner_index then
            _slash_axe_motion_value = hitData:get_field("_BaseDamage")
            _slash_axe_motion_value_id = hitData:get_field("<RequestSetID>k__BackingField")
        end
    end
)

--任意ONframe函数应该改为在此调用
re.on_pre_application_entry("UpdateScene", function()
    if not PlayerManager then
        PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
    end
    if not PlayerManager then return end
    master_player = PlayerManager:call("findMasterPlayer")
    if not CameraManager then
        CameraManager = sdk.get_managed_singleton("snow.CameraManager")
    end
    if not CameraManager then return end
    if not master_player then return end
    get_game_data()
end)

local pad_vibration_id = 0
local pad_vibration_is_loop = false
re.on_draw_ui(function()
    if imgui.tree_node("YUN_DEBUGS") then
        if not master_player then return end
        if imgui.tree_node("BASE DATA") then
            --imgui.text("my timer",my_timer:get_Time())
            --imgui.text("LS gauge = "..master_player:get_LongSwordGauge()..", LS lv = "..master_player:get_LongSwordGaugeLv())
            --imgui.text("caxe bottle num = "..master_player:get_ChargedBottleNum()..", Caxe bottle type = "..master_player:getBottleType()..", Caxe ele type = "..master_player:getWeaponElementType()..", is shield buff = "..tostring(master_player:isShieldBuff()))
            -- local motion = master_player:getMotion()

            -- imgui.text("motion RootMotionTranslation() X = " .. motion:get_RootMotionTranslation().x)
            -- imgui.text("motion RootMotionTranslation() Y = " .. motion:get_RootMotionTranslation().y)
            -- imgui.text("motion RootMotionTranslation() Z = " .. motion:get_RootMotionTranslation().z)
            -- imgui.text("player direction = " .. master_player:call("get_RefAngleCtrl"):get_field("_targetAngle"))

            -- if imgui.button("set root apply") then
            --     local temp_vec3 = motion:get_RootMotionTranslation()
            --     temp_vec3.x = 1.0
            --     temp_vec3.y = 0.0
            --     temp_vec3.z = 0.0
            --     local temp_rota = motion:get_RootMotionRotation()
            --     motion:rootApply(temp_vec3, temp_rota)
            -- end

            imgui.drag_int("weapon_type", _wep_type)

            imgui.drag_int("action_id", _action_id)

            imgui.drag_float("frame", yun_modules.get_now_action_frame())

            imgui.drag_float("muteki frame", yun_modules.get_muteki_time())

            imgui.text("motion_value_id: " .. yun_modules.get_motion_value_id())

            imgui.same_line()

            imgui.text(", motion_value: " .. yun_modules.get_motion_value())

            imgui.drag_int("pre action_id", yun_modules.get_pre_action_id())

            imgui.drag_float("player speed", master_player:call("get_GameObject"):call("get_TimeScale"))

            -- if imgui.button("CALL STICK") then
            --     yun_modules.set_current_node(0x2502c40f)
            -- end

            imgui.text(string.format("current node: 0x%06X", yun_modules.get_current_node()))

            imgui.text("now book: " .. master_player:get_field("_ReplaceAtkMysetHolder"):call("getSelectedIndex"))
            imgui.same_line()
            imgui.text(",switch_skills: ")
            imgui.same_line()
            for i = 1, 6 do
                imgui.text(yun_modules.get_replace_attack_data()[i])
                if i ~= 6 then
                    imgui.same_line()
                end
            end

            imgui.tree_pop()
        end
        if imgui.tree_node("PAD VIBRATION DATA") then
            imgui.text("pad_vibration_id = " .. pad_vibration_id)
            changed, pad_vibration_id = imgui.input_text("pad_vibration_id", pad_vibration_id)

            changed, pad_vibration_is_loop = imgui.checkbox("pad_vibration_is_loop", pad_vibration_is_loop)

            if imgui.button("vibration ID ++") then
                pad_vibration_id = pad_vibration_id + 1
            end
            imgui.same_line()
            if imgui.button("call vibration") then
                yun_modules.set_pad_vibration(tonumber(pad_vibration_id), pad_vibration_is_loop)
            end
            imgui.same_line()

            if imgui.button("stop vibration") then
                Pad:stopAllPadVibration()
            end
            imgui.same_line()
            if imgui.button("vibration ID --") then
                pad_vibration_id = pad_vibration_id - 1
            end
            imgui.tree_pop()
        end
        -- imgui.drag_float("mHitStopTimer", master_player:get_field("mHitStopTimer"))

        -- imgui.drag_int("_HitStopType", hit_stop_type)

        -- imgui.checkbox("_HitStopSlowRun",master_player:get_field("_HitStopSlowRun"))

        -- if imgui.button("set player speed") then
        --     master_player:call("get_GameObject"):call("set_TimeScale",0.1)
        -- end
        -- if imgui.button("reset player speed") then
        --     master_player:call("get_GameObject"):call("set_TimeScale",1.0)
        -- end

        -- imgui.drag_int("atk",yun_modules.get_atk())

        -- imgui.drag_int("affinity",yun_modules.get_affinity())

        -- imgui.drag_float("相对世界坐标的左摇杆方向",master_player:call('get_RefPlayerInput'):call("getLstickDir"))

        -- imgui.drag_float("相对镜头坐标的左摇杆方向",master_player:call('get_RefPlayerInput'):call("getHormdirLstick"))

        -- imgui.drag_float("相对镜头坐标的角色朝向",master_player:call("get_RefAngleCtrl"):get_field("_targetAngle")

        imgui.tree_pop()
    end
end)

return yun_modules

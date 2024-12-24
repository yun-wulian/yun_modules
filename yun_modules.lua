local yun_modules = {}

local master_player
local master_player_index
local player_data
local _action_bank_id
local _action_id
local _pre_action_id
local _pre_node_id
local _action_frame
local _current_node
local _muteki_time
local _hyper_armor_time
local _atk
local _affinity
local _replace_atk_data = {}
local _wep_type

local _derive_start_frame = 0

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

local hit_counter_info = {}
local counter_success = false
local hit_success = false
local need_hit_info = {}
sdk.hook(sdk.find_type_definition("snow.player.PlayerMotionControl"):get_method("lateUpdate"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        local PlayerBase = this:get_field("_RefPlayerBase")

        if PlayerBase:isMasterPlayer() then
            if _action_id ~= this:get_field("_OldMotionID") then
                _pre_action_id = _action_id
                _action_id = this:get_field("_OldMotionID")
                hit_counter_info = {}
                need_hit_info = {}
                counter_success = false
                hit_success = false
            end
            _action_bank_id = this:get_field("_OldBankID")
        end
    end)

local function get_game_data()
    master_player_index = master_player:get_field("_PlayerIndex")
    mPlObj = master_player:call("get_GameObject")
    mPlBHVT = mPlObj:call("getComponent(System.Type)", sdk.typeof("via.behaviortree.BehaviorTree"))
    player_data = master_player:call("get_PlayerData")
    _wep_type = master_player:get_field("_playerWeaponType")
    _should_draw_ui = yun_modules.enabled() and not yun_modules.is_pausing() and yun_modules.should_hud_show()
    _atk = player_data:get_field("_Attack")
    if _current_node ~= mPlBHVT:call("getCurrentNodeID", 0) then
        _pre_node_id = _current_node
        _current_node = mPlBHVT:call("getCurrentNodeID", 0)
    end
    _action_frame = master_player:call("getMotionLayer", 0):call("get_Frame")
    _affinity = player_data:get_field("_CriticalRate")
    _muteki_time = master_player:get_field("_MutekiTime")
    _replace_atk_data = { master_player:get_field("_replaceAttackTypeA"), master_player:get_field("_replaceAttackTypeB"),
        master_player:get_field("_replaceAttackTypeC"), master_player:get_field("_replaceAttackTypeD"),
        master_player:get_field("_replaceAttackTypeE"), master_player:get_field("_replaceAttackTypeF") }
    _hyper_armor_time = master_player:get_field("_HyperArmorTimer")
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

--已弃用，性能太差，尽量避免使用。已有更好的方法
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
        if derive.tar_node_hash == yun_modules.get_current_node() and derive.jmp_frame ~= nil and _pre_action_id == derive.tar_action_id and yun_modules.get_now_action_frame() > 0.0 and yun_modules.get_now_action_frame() < derive.jmp_frame then
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

yun_modules.hook_evaluate_post = {}
function yun_modules.push_evaluate_post_functions(func)
    if type(func) == "function" then
        table.insert(yun_modules.hook_evaluate_post, func)
    end
end

local ignore_keys = {}
local this_derive_cmd = 0
local this_is_by_action_id = true
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
                this_derive_cmd = cmd_type
                if this_is_by_action_id and ignore_keys[_action_id] ~= nil then
                    for _, value in ipairs(ignore_keys[_action_id]) do
                        --re.msg(value)
                        if cmd_type == value then
                            return sdk.to_ptr(0)
                        end
                    end
                elseif not this_is_by_action_id and ignore_keys[_current_node] ~= nil then
                    for _, value in ipairs(ignore_keys[_current_node]) do
                        --re.msg(value)
                        if cmd_type == value then
                            return sdk.to_ptr(0)
                        end
                    end
                end
                if commandbase:get_field("StartFrame") > 1 then
                    _derive_start_frame = commandbase:get_field("StartFrame")
                end
                for _, func in ipairs(yun_modules.hook_evaluate_post) do
                    retval = func(retval, commandbase, commandarg)
                end
            end
        end
        return retval
    end
)

--新的派生工具案例
local dataTable_exam = {
    [yun_modules.weapon_type.LongSword] = {              --武器类型,LongSword = 太刀，其他武器名称请自行查看yun_modules.weapon_type的定义
        [101] = {                                        --动作ID，或者NodeID，需要进行模拟派生的动作标识
            ["targetNode"] = 0x66666666,                 --必要条件，派生目标的nodeID，只能通过nodeID来进行指定派生，想派生的动作请自己查询nodeID
            ["preFrame"] = 10.0,                         --非必要条件，默认值为10。派生提前接受输入的帧数，通俗来讲就是预输入.
            ["startFrame"] = 100.0,                      --非必要条件，默认为“当前动作最早可以派生的原始帧数”。派生开始进行的帧数，当进行输入之后，动作进行到这个帧数以后就会派生下一个动作。
            ["targetCmd"] = 5,                           --非必要条件，默认为nil。派生的按键判定，就是需要按下哪个键位，就进行派生.如果不指定键位，则会在帧数进行到可以派生的帧数之后自动派生。
            ["isHolding"] = false,                       --非必要条件，默认为false。注意！此选项会影响按键判定的方式，并且判定ID也会改变.按键判定是否接受按住，如果为true，则按键持续按住也会触发判定.
            ["tarLstickDir"] = yun_modules.direction.Up, --非必要条件，默认为nil。派生的摇杆判定，如果此选项有数值，推着摇杆朝对应的方向才进行派生。
            ["isByPlayerDir"] = true,                    --非必要选项，默认为true。和上一条联动的条件，推摇杆的方向基准是以角色朝向还是以屏幕朝向。
            ["turnRange"] = 30.0,                        --非必要选项，默认为nil。派生可以转向的幅度，单位为度，数值对应一侧。比如填30就是左右30度也就是面前60度可以转向。填180就是全方向。不填就不可以转向。
            ["jmpFrame"] = 30.0,                         --非必要选项，默认为nil。派生跳帧的数值，所谓跳帧就是派生到下一个动作之后，从多少帧开始播放动作。
            ["preActionId"] = 101,                       --非必要选项，默认为nil。增加需要上一个动作和当前动作符合才进行派生的条件。
            ["preNodeId"] = 0x66666666,                  --非必要选项，默认为nil。增加需要上一个动作node和当前动作符合才进行派生的条件。
            ["needIgnoreOriginalKey"] = false,           --非必要选项，默认为false。如果你的新派生是替换原有的按键的派生，请设置为true。这会忽略原有的同按键的派生。
            ["counterAtk"] = { true, 2, { 0, 20.0 } },   --非必要选项，默认为{false,0,{0,0}}。是否当身派生，第一项为派生开关，第二项为可以抵挡伤害的次数，第三项为当身判定的起始和结束帧。如果为true同时第二项大于0，则会在动作进行期间进行当身判定，受到伤害就会派生。如果第一项为false，第二项大于0，则只会抵挡伤害而不会派生。
            ["hit"] = true,                              --非必要选项，默认为nil。是否为攻击派生。如果为true，则会在攻击命中的时候派生。
            ["useWire"] = { 1, 300.0 },                  --非必要选项，默认为nil。翔虫的冷却，第一个是消耗的个数，第二个是冷却时间。
        },
    }
}

yun_modules.deriveTable = {}
function yun_modules.push_derive_table(derive_table)
    if type(derive_table) == "table" then
        table.insert(yun_modules.deriveTable, derive_table)
    end
end

local function deepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in next, orig, nil do
            copy[deepCopy(k)] = deepCopy(v)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- 不是表，直接复制
        copy = orig
    end
    return copy
end

local input_cache = 0
local jmp_frame_cache = 0
local jmp_frame_node = 0
--新的派生工具循环器
local function derive_wrapper(derive_table)
    if not master_player then return end
    --if _action_bank_id ~= 100 then return end
    local now_action_table
    local this_id
    for _, sub_derive_table in ipairs(derive_table) do
        if sub_derive_table[_wep_type] ~= nil then
            --re.msg("get weapon")
            now_action_table = sub_derive_table[_wep_type][_action_id]
            this_id = _action_id
            this_is_by_action_id = true
            if now_action_table == nil then
                now_action_table = sub_derive_table[_wep_type][_current_node]
                this_id = _current_node
                this_is_by_action_id = false
            end
        end
        if now_action_table == nil then
            goto continue2
        end
        for index, subtable in ipairs(now_action_table) do
            --re.msg(index)
            local _targetNode = subtable['targetNode']
            local _preFrame = subtable['preFrame'] or 10.0
            local _startFrame = subtable['startFrame'] or _derive_start_frame
            local _targetCmd = subtable['targetCmd']
            local _isHolding = subtable['isHolding']
            local _tarLstickDir = subtable['tarLstickDir']
            local _isByPlayerDir = subtable['isByPlayerDir']
            local _turnRange = subtable['turnRange']
            local _jmpFrame = subtable['jmpFrame']
            local _preActionId = subtable['preActionId']
            local _preNodeId = subtable['preNodeId']
            local _useWire = subtable['useWire']
            if _preActionId ~= nil and _pre_action_id ~= _preActionId then
                goto continue
            end
            if _preNodeId ~= nil and _pre_node_id ~= _preNodeId then
                goto continue
            end
            if subtable['counterAtk'] ~= nil and hit_counter_info[1] == nil then
                hit_counter_info = deepCopy(subtable['counterAtk'])
            end
            if subtable['hit'] ~= nil then
                need_hit_info = { _action_id, _startFrame }
            end
            if subtable['needIgnoreOriginalKey'] ~= nil then
                ignore_keys[this_id] = {}
                table.insert(ignore_keys[this_id], subtable['needIgnoreOriginalKey'])
                subtable['needIgnoreOriginalKey'] = nil
            end
            if _targetNode == nil then
                goto continue
            end
            if subtable['hit'] == nil and subtable['counterAtk'] == nil then
                if _startFrame - _preFrame < _action_frame then
                    if _tarLstickDir ~= nil then
                        if _useWire ~= nil then
                            if _useWire[1] > master_player:getUsableHunterWireNum() then
                                goto continue
                            end
                        end
                        if _isByPlayerDir == nil or _isByPlayerDir then
                            if not yun_modules.check_lstick_dir_for_player_only_quad(_tarLstickDir) then
                                goto continue
                            end
                        elseif not _isByPlayerDir then
                            if not yun_modules.check_lstick_dir(_tarLstickDir) then
                                goto continue
                            end
                        end
                    end
                    if input_cache == 0 then
                        if not _isHolding then
                            if yun_modules.check_input_by_isCmd(_targetCmd) then
                                input_cache = _targetNode
                            end
                        else
                            if yun_modules.check_input_by_isOn(_targetCmd) then
                                input_cache = _targetNode
                            end
                        end
                    end
                    if _targetCmd == nil then
                        input_cache = _targetNode
                    end
                end
                if _startFrame < _action_frame then
                    if input_cache ~= 0 then
                        if _useWire ~= nil then
                            master_player:useHunterWireGauge(_useWire[1], _useWire[2])
                        end
                        yun_modules.set_current_node(input_cache)
                        input_cache = 0
                        if _turnRange ~= nil then
                            yun_modules.turn_to_lstick_dir(_turnRange)
                        end
                        if _jmpFrame ~= nil then
                            jmp_frame_cache = _jmpFrame
                            jmp_frame_node = _targetNode
                        end
                        break
                    end
                end
            end
            if counter_success and subtable['counterAtk'] ~= nil then
                yun_modules.set_current_node(_targetNode)
                counter_success = false
                jmp_frame_cache = _jmpFrame
                jmp_frame_node = _targetNode
                break
            end
            if hit_success and subtable['hit'] ~= nil then
                yun_modules.set_current_node(_targetNode)
                hit_success = false
                jmp_frame_cache = _jmpFrame
                jmp_frame_node = _targetNode
                break
            end
            ::continue::
        end

        if jmp_frame_cache ~= 0 and jmp_frame_node ~= 0 then
            if jmp_frame_node == _current_node then
                yun_modules.set_now_action_frame(jmp_frame_cache)
                jmp_frame_cache = 0
                jmp_frame_node = 0
            end
        end
        ::continue2::
    end
end


if hit_counter_info ~= {} and hit_counter_info ~= nil then
    if hit_counter_info[3] ~= nil and hit_counter_info[3][1] < _action_frame and hit_counter_info[3][2] > _action_frame then
        if hit_counter_info[2] > 0 then
            hit_counter_info[2] = hit_counter_info[2] - 1
            if hit_counter_info[1] then
                counter_success = true
            end
            return sdk.to_ptr(2)
        end
    end
end

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
        if (dmgOwnerType == 1 or dmgOwnerType == 0) then --props and enemy
            if type(hit_counter_info) == "table" and next(hit_counter_info) then
                local frameInfo = hit_counter_info[3]
                -- 确认第三项存在且_action_frame在指定范围内
                if frameInfo and _action_frame > frameInfo[1] and _action_frame < frameInfo[2] then
                    if hit_counter_info[2] > 0 then
                        hit_counter_info[2] = hit_counter_info[2] - 1
                        if hit_counter_info[1] then
                            counter_success = true
                        end
                        return sdk.to_ptr(2)
                    end
                end
            end
        end
        return retval
    end
)
sdk.hook(
    sdk.find_type_definition("snow.enemy.EnemyCharacterBase"):get_method("afterCalcDamage_DamageSide"),
    function(args)
        if need_hit_info ~= {} and need_hit_info ~= nil then
            if need_hit_info[1] == _action_id
                and need_hit_info[2] <= _derive_start_frame then
                hit_success = true
            end
        end
    end
)

sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("update"),
    function(args)
        derive_wrapper(yun_modules.deriveTable)
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
    if not master_player or not master_player:isMasterPlayer() then
        master_player = nil
        return
    end
    get_game_data()
end)

local function tableToString(tbl, indent)
    local indent = indent or ""
    local result = {}
    if tbl == nil then return "nil" end
    for key, value in pairs(tbl) do
        table.insert(result, string.format("%s%s: ", indent, tostring(key)))
        if type(value) == "table" then
            table.insert(result, "\n" .. tableToString(value, indent .. "  "))
        else
            table.insert(result, tostring(value) .. "\n")
        end
    end

    return table.concat(result)
end

local function printTableWithImGui(tbl)
    local str = tableToString(tbl)
    for line in string.gmatch(str, "[^\r\n]+") do
        imgui.text(line)
    end
end

local pad_vibration_id = 0
local pad_vibration_is_loop = false
re.on_draw_ui(function()
    if imgui.tree_node("YUN_DEBUGS") then
        if not master_player then return end
        printTableWithImGui(ignore_keys)
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

            imgui.drag_int("action_bank_id", _action_bank_id)

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

        if imgui.tree_node("DERIVE DATA") then
            imgui.text("this_derive_cmd = " .. this_derive_cmd)
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

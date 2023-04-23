local yun_modules = {}

local master_player
local master_player_index
local action_bank_id
local action_id
local pre_action_id
local wep_type
local mPlObj
local mPlBHVT
local weapon_data

local motion_value

local player_atk
local player_affinity
local atk_flag = false
local affinity_flag = false

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

function yun_modules.check_using_weapon_type(tar_type)
    if wep_type == tar_type then return true end
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

function yun_modules.check_action_table(action_table,bank_id)
    if not bank_id then
        bank_id = 100
    end

    if action_bank_id == bank_id then
        for i = 1, #action_table do
            if action_id == action_table[i] then
                return true
            end
        end
        return false
    else
        return false
    end
end

function yun_modules.set_effect(contianer,efx)
    if not master_player then return end
    master_player:call("setItemEffect",contianer, efx)
end

function yun_modules.check_equip_skill_lv(skill)
    if not master_player then return end
    local skill_list = master_player:call("get_PlayerSkillList")
    for i = 7,1,-1 do
        if skill_list:call("hasSkill",skill,i) then
            return i
        end
    end
    return 0
end

sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAttack"),
    function(args) end,
    function(retval)
        if not master_player then return end
        local playerData = master_player:call("get_PlayerData")
        if atk_flag then
            playerData:set_field("_Attack", player_atk)
        end
    end)

sdk.hook(sdk.find_type_definition("snow.player.PlayerBase"):get_method("calcTotalAffinity"),
    function(args) end,
    function(retval)
        if not master_player then return end
        local playerData = master_player:call("get_PlayerData")
        if affinity_flag then
            playerData:set_field("_CriticalRate", player_affinity)
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
    return master_player:call("get_PlayerData"):get_field("_Attack")
end

function yun_modules.get_affinity()
    if not master_player then return 0 end
    return master_player:call("get_PlayerData"):get_field("_CriticalRate")
end

function yun_modules.get_motion_value()
    if not motion_value then return 0 end
    return motion_value
end

function yun_modules.get_action_id()
    if action_id then
        return action_id
    end
end

function yun_modules.get_pre_action_id()
    if pre_action_id then
        return pre_action_id
    end
end

function yun_modules.get_action_bank_id()
    if action_bank_id then
        return action_bank_id
    end
end

function yun_modules.get_now_action_frame()
    if not master_player then return end
    return master_player:call("getMotionLayer", 0):call("get_Frame")
end

function yun_modules.set_now_action_frame(frame)
    if not master_player then return end
    return master_player:call("getMotionLayer", 0):call("set_Frame",frame)
end

function yun_modules.get_weapon_type()
    if not master_player then return end
    return wep_type
end

function yun_modules.get_current_node()
    if mPlBHVT then
        return mPlBHVT:call("getCurrentNodeID", 0)
    end
end

function yun_modules.get_muteki_time()
    if not master_player then return end
    return master_player:get_field("_MutekiTime")
end

function yun_modules.set_muteki_time(value)
    if not master_player then return end
    return master_player:set_field("_MutekiTime",value)
end

function yun_modules.get_replace_attack_data()
    if not master_player then return end
    return {master_player:get_field("_replaceAttackTypeA"),master_player:get_field("_replaceAttackTypeB"),master_player:get_field("_replaceAttackTypeC"),master_player:get_field("_replaceAttackTypeD"),master_player:get_field("_replaceAttackTypeE"),master_player:get_field("_replaceAttackTypeF")}
end

function yun_modules.get_hyper_armor_time()
    if not master_player then return end
    return master_player:get_field("_HyperArmorTimer")
end

function yun_modules.set_hyper_armor_time(value)
    if not master_player then return end
    return master_player:set_field("_HyperArmorTimer",value)
end

function yun_modules.is_push_lstick()
    local is_push_lstick = false
    for i=0,7 do
        is_push_lstick = master_player:call('get_RefPlayerInput'):call("checkAnaLever",i)
        if is_push_lstick then return true end
    end
    return false
end

function yun_modules.turn_to_lstick_dir(range)
    local is_push_lstick = false
    for i=0,7 do
        is_push_lstick = master_player:call('get_RefPlayerInput'):call("checkAnaLever",i)
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
        local left_target,right_target
        left_target = player_angle + range
        right_target = player_angle - range
        if left_target > math.pi then
            left_target = left_target - 2*math.pi
        elseif right_target < -math.pi then
            right_target = 2*math.pi - right_target
        end
        if delta_angle_sin > 0 then
            master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", left_target)
        else
            master_player:call("get_RefAngleCtrl"):set_field("_targetAngle", right_target)
        end
    end
end


local pre_input_flag = false
local target_derive_node_hash = 0

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
        if delta_angle_sin > math.sin(math.rad(-67.5)) and delta_angle_sin < math.sin(math.rad(-22.5)) and delta_angle_cos < 0  then return true end
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

function yun_modules.check_input_by_isOn(cmd)
    if not master_player then return false end
    return master_player:call('get_RefPlayerInput'):call("get_mNow"):call("isOn", cmd)
end

function yun_modules.check_input_by_isCmd(cmd)
    if not master_player then return false end
    return master_player:call('get_RefPlayerInput'):call("isCmd", sdk.to_ptr(cmd))
end

local jmp_frame_flag = false
local tmp_action_id = 0
local tmp_jmp_frame = 0.0
local function analog_derive_to_target(lock_action_id,start_frame,jmp_frame)
    if pre_input_flag and target_derive_node_hash ~= 0 and yun_modules.get_now_action_frame() >= start_frame and action_id == lock_action_id then
        yun_modules.set_current_node(target_derive_node_hash)
        pre_input_flag = false
        if jmp_frame then
            jmp_frame_flag = true
            tmp_action_id = yun_modules.get_action_id()
            tmp_jmp_frame = jmp_frame
        end
        target_derive_node_hash = 0
    end
end

local function analog_jmp_frame()
    if yun_modules.get_action_id() ~= tmp_action_id and jmp_frame_flag and yun_modules.get_now_action_frame() > 0.0 then
        yun_modules.set_now_action_frame(tmp_jmp_frame)
        tmp_jmp_frame = 0.0
        jmp_frame_flag = false
    end
end

local function analog_input(tar_action_id, tar_action_bank_id, tar_cmd, is_by_isCmd, tar_lstick_dir,is_by_player_dir, tar_pre_frame, tar_node_hash,turn_range)
    if not tar_action_bank_id then tar_action_bank_id = 100 end
    if not is_by_isCmd then is_by_isCmd = true end
    if action_bank_id == tar_action_bank_id and action_id == tar_action_id and yun_modules.get_now_action_frame() >= tar_pre_frame then
        if not pre_input_flag then
            if is_by_isCmd then
                if not yun_modules.check_input_by_isCmd(tar_cmd) then
                    return
                end
            else
                if not yun_modules.check_input_by_isOn(tar_cmd) then
                    return
                end
            end
            if tar_lstick_dir then
                if is_by_player_dir then
                    if not yun_modules.check_lstick_dir_for_player_only_quad(tar_lstick_dir) or turn_range then
                        return
                    end
                else
                    if not yun_modules.check_lstick_dir(tar_lstick_dir) or turn_range then
                        return
                    end
                end
            end
            pre_input_flag = true
            target_derive_node_hash = tar_node_hash
            if turn_range then
                yun_modules.turn_to_lstick_dir(turn_range)
            end
        end
    else
        --pre_input_flag = false
    end
end

function yun_modules.analog_derive(tar_action_id, tar_action_bank_id, tar_cmd, is_by_isCmd, tar_lstick_dir,is_by_player_dir, pre_frame,start_frame,turn_range,tar_node_hash,jmp_frame)
    analog_input(tar_action_id, tar_action_bank_id, tar_cmd, is_by_isCmd, tar_lstick_dir,is_by_player_dir, pre_frame, tar_node_hash,turn_range)
    analog_derive_to_target(tar_action_id,start_frame,jmp_frame)
    analog_jmp_frame()
end

re.on_frame(function()
    if not PlayerManager then
        PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
    end
    if not PlayerManager then return end
    master_player = PlayerManager:call("findMasterPlayer")
    if not master_player then return end
    master_player_index = master_player:get_field("_PlayerIndex")
    mPlObj = master_player:call("get_GameObject")
    mPlBHVT = mPlObj:call("getComponent(System.Type)", sdk.typeof("via.behaviortree.BehaviorTree"))
    PlayerData = master_player:call("get_PlayerData")
    wep_type = master_player:get_field("_playerWeaponType")
end)

sdk.hook(sdk.find_type_definition("snow.player.PlayerMotionControl"):get_method("lateUpdate"),
    function(args)
        local motionControl = sdk.to_managed_object(args[2])
        local refPlayerBase = motionControl:get_field("_RefPlayerBase")
        local curPlayerIndex = refPlayerBase:get_field("_PlayerIndex")

        if curPlayerIndex == master_player_index then
            if action_id ~= motionControl:get_field("_OldMotionID") then
                pre_action_id = action_id
                action_id = motionControl:get_field("_OldMotionID")
            end
            action_bank_id = motionControl:get_field("_OldBankID")
        end
    end,
    function(retval)
    end
)

sdk.hook(sdk.find_type_definition("snow.player.ChargeAxe"):get_method("getAdjustActionAttack"),
    function(args)
    end,
    function(retval)
        motion_value = sdk.to_float(retval)
        return retval
    end
)

re.on_draw_ui(function ()
    if imgui.tree_node("YUN_DEBUGS") then
        if not master_player then return end
        imgui.drag_int("weapon_type",wep_type)

        imgui.drag_int("action_id",action_id)

        imgui.drag_float("frame",master_player:call("getMotionLayer",0):call("get_Frame"))

        imgui.text(string.format("current node: 0x%06X",mPlBHVT:call("getCurrentNodeID",0)))
        
        -- imgui.drag_int("tmp_node?",tmp_action_id)

        -- imgui.drag_int("atk",yun_modules.get_atk())

        -- imgui.drag_int("affinity",yun_modules.get_affinity())

        -- imgui.drag_float("相对世界坐标的左摇杆方向",master_player:call('get_RefPlayerInput'):call("getLstickDir"))

        -- imgui.drag_float("相对镜头坐标的左摇杆方向",master_player:call('get_RefPlayerInput'):call("getHormdirLstick"))

        -- imgui.drag_float("相对镜头坐标的角色朝向",master_player:call("get_RefAngleCtrl"):get_field("_targetAngle"))

        imgui.text("switch_skills: ")
        imgui.same_line()
        for i = 1,6 do
            imgui.text(yun_modules.get_replace_attack_data()[i])
            if i ~= 6 then
                imgui.same_line()
            end
        end

        imgui.tree_pop()
    end
end)

return yun_modules
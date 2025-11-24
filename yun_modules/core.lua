-- yun_modules/core.lua
-- Core variables and game data management

local core = {}

-- Weapon type enum
core.weapon_type = {
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

-- Direction enum
core.direction = {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
    RightUp = 4,
    RightDown = 5,
    LeftUp = 6,
    LeftDown = 7
}

-- Core game object singletons
core.GuiManager = nil
core.TimeScaleManager = nil
core.CameraManager = nil
core.Pad = nil
core.PlayerManager = nil

-- Player state variables
core.master_player = nil
core.master_player_index = nil
core.player_data = nil
core.mPlObj = nil
core.mPlBHVT = nil
core.PlayerMotionCtrl = nil

-- Action state variables
core._action_bank_id = nil
core._action_id = nil
core._pre_action_id = nil
core._pre_node_id = nil
core._action_frame = nil
core._current_node = nil
core._wep_type = nil
core._derive_start_frame = 0

-- Player stats
core._muteki_time = nil
core._hyper_armor_time = nil
core._atk = nil
core._affinity = nil
core._replace_atk_data = {}

-- Motion value tracking
core._motion_value = nil
core._slash_axe_motion_value = 0
core._motion_value_id = nil
core._slash_axe_motion_value_id = nil

-- Attack/affinity override
core.player_atk = nil
core.player_affinity = nil
core.atk_flag = false
core.affinity_flag = false

-- Game state flags
core.is_in_quest = false
core.is_loading_visiable = false
core._should_draw_ui = false

-- Initialize singletons
function core.init_singletons()
    core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    core.TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager')
    core.CameraManager = sdk.get_managed_singleton("snow.CameraManager")
    core.Pad = sdk.get_managed_singleton('snow.Pad')
    core.PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
end

-- Update game data (called every frame)
function core.update_game_data()
    if not core.master_player then return end

    core.master_player_index = core.master_player:get_field("_PlayerIndex")
    core.mPlObj = core.master_player:call("get_GameObject")
    core.mPlBHVT = core.mPlObj:call("getComponent(System.Type)", sdk.typeof("via.behaviortree.BehaviorTree"))
    core.player_data = core.master_player:call("get_PlayerData")
    core._wep_type = core.master_player:get_field("_playerWeaponType")

    -- Update UI flag (requires state module functions)
    -- core._should_draw_ui = enabled() and not is_pausing() and should_hud_show()

    core._atk = core.player_data:get_field("_Attack")

    if core._current_node ~= core.mPlBHVT:call("getCurrentNodeID", 0) then
        core._pre_node_id = core._current_node
        core._current_node = core.mPlBHVT:call("getCurrentNodeID", 0)
    end

    core._action_frame = core.master_player:call("getMotionLayer", 0):call("get_Frame")
    core._affinity = core.player_data:get_field("_CriticalRate")
    core._muteki_time = core.master_player:get_field("_MutekiTime")
    core._replace_atk_data = {
        core.master_player:get_field("_replaceAttackTypeA"),
        core.master_player:get_field("_replaceAttackTypeB"),
        core.master_player:get_field("_replaceAttackTypeC"),
        core.master_player:get_field("_replaceAttackTypeD"),
        core.master_player:get_field("_replaceAttackTypeE"),
        core.master_player:get_field("_replaceAttackTypeF")
    }
    core._hyper_armor_time = core.master_player:get_field("_HyperArmorTimer")
end

-- Find and set master player
function core.find_master_player()
    if not core.PlayerManager then
        core.PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
    end
    if not core.PlayerManager then return false end

    core.master_player = core.PlayerManager:call("findMasterPlayer")
    if not core.master_player or not core.master_player:isMasterPlayer() then
        core.master_player = nil
        return false
    end
    return true
end

return core

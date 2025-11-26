-- yun_modules.lua
-- 主入口文件 - 聚合所有子模块并导出统一的 API
-- 确保与现有 MOD 的向后兼容性

local yun_modules = {}

-- 导入子模块
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local player = require("yunwulian.yun_modules.player")
local action = require("yunwulian.yun_modules.action")
local input = require("yunwulian.yun_modules.input")
local state = require("yunwulian.yun_modules.state")
local effects = require("yunwulian.yun_modules.effects")
local derive = require("yunwulian.yun_modules.derive")
local hooks = require("yunwulian.yun_modules.hooks")
local ui = require("yunwulian.yun_modules.ui")

-- 导出枚举类型
yun_modules.weapon_type = core.weapon_type
yun_modules.direction = core.direction

-- 导出时间函数
yun_modules.get_time = player.get_time
yun_modules.get_delta_time = player.get_delta_time

-- 导出玩家相关函数
yun_modules.get_master_player = player.get_master_player
yun_modules.get_master_player_index = player.get_master_player_index
yun_modules.check_using_weapon_type = player.check_using_weapon_type
yun_modules.get_weapon_type = player.get_weapon_type
yun_modules.check_equip_skill_lv = player.check_equip_skill_lv
yun_modules.get_player_timescale = player.get_player_timescale
yun_modules.set_player_timescale = player.set_player_timescale
yun_modules.set_atk = player.set_atk
yun_modules.set_affinity = player.set_affinity
yun_modules.clear_atk = player.clear_atk
yun_modules.clear_affinity = player.clear_affinity
yun_modules.get_atk = player.get_atk
yun_modules.get_affinity = player.get_affinity
yun_modules.get_muteki_time = player.get_muteki_time
yun_modules.set_muteki_time = player.set_muteki_time
yun_modules.get_hyper_armor_time = player.get_hyper_armor_time
yun_modules.set_hyper_armor_time = player.set_hyper_armor_time
yun_modules.get_replace_attack_data = player.get_replace_attack_data
yun_modules.get_vital = player.get_vital
yun_modules.set_vital = player.set_vital
yun_modules.get_r_vital = player.get_r_vital
yun_modules.set_r_vital = player.set_r_vital
yun_modules.get_selected_book = player.get_selected_book
yun_modules.get_switch_skill = player.get_switch_skill

-- 导出动作函数
yun_modules.action_change_functions = action.action_change_functions
yun_modules.on_action_change = action.on_action_change
yun_modules.get_action_id = action.get_action_id
yun_modules.get_pre_action_id = action.get_pre_action_id
yun_modules.get_action_bank_id = action.get_action_bank_id
yun_modules.get_now_action_frame = action.get_now_action_frame
yun_modules.set_now_action_frame = action.set_now_action_frame
yun_modules.get_current_node = action.get_current_node
yun_modules.set_current_node = action.set_current_node
yun_modules.check_action_table = action.check_action_table
yun_modules.get_motion_value = action.get_motion_value
yun_modules.get_motion_value_id = action.get_motion_value_id
yun_modules.move_to_lstick_dir = action.move_to_lstick_dir

-- 导出输入函数
yun_modules.is_push_lstick = input.is_push_lstick
yun_modules.turn_to_lstick_dir = input.turn_to_lstick_dir
yun_modules.check_lstick_dir = input.check_lstick_dir
yun_modules.check_lstick_dir_for_player = input.check_lstick_dir_for_player
yun_modules.check_lstick_dir_for_player_only_quad = input.check_lstick_dir_for_player_only_quad
yun_modules.check_input_by_isOn = input.check_input_by_isOn
yun_modules.check_input_by_isCmd = input.check_input_by_isCmd

-- 导出状态相关函数
yun_modules.quest_change_functions = state.quest_change_functions
yun_modules.on_quest_change = state.on_quest_change
yun_modules.should_hud_show = state.should_hud_show
yun_modules.is_in_quest = state.is_in_quest
yun_modules.is_pausing = state.is_pausing
yun_modules.enabled = state.enabled
yun_modules.should_draw_ui = state.should_draw_ui

-- 导出特效相关函数
yun_modules.set_effect = effects.set_effect
yun_modules.set_camera_vibration = effects.set_camera_vibration
yun_modules.set_pad_vibration = effects.set_pad_vibration

-- 导出派生相关函数
yun_modules.deriveTable = derive.deriveTable
yun_modules.push_derive_table = derive.push_derive_table
yun_modules.hook_evaluate_post = derive.hook_evaluate_post
yun_modules.push_evaluate_post_functions = derive.push_evaluate_post_functions
yun_modules.analog_derive = derive.analog_derive

-- 初始化单例
core.init_singletons()

-- 初始化钩子
hooks.init()

-- 主循环
re.on_pre_application_entry("UpdateScene", function()
    -- Find master player
    if not core.find_master_player() then
        return
    end

    -- Update core camera manager
    if not core.CameraManager then
        core.CameraManager = sdk.get_managed_singleton("snow.CameraManager")
    end
    if not core.CameraManager then return end

    -- Update game data
    core.update_game_data()

    -- Update should_draw_ui flag
    state.update_should_draw_ui()

    -- Update derive system
    derive.update()
end)

-- Late update loop (for cleanup)
re.on_application_entry("LateUpdateBehavior", function()
    derive.late_update()
end)

-- UI rendering
re.on_draw_ui(function()
    ui.draw_debug_ui()
end)

return yun_modules

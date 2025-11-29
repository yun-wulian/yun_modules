-- yun_modules/ui.lua
-- 调试UI和可视化

local ui = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local player = require("yunwulian.yun_modules.player")
local action = require("yunwulian.yun_modules.action")
local effects = require("yunwulian.yun_modules.effects")
local derive = require("yunwulian.yun_modules.derive")

-- UI状态变量
local pad_vibration_id = 0              -- 手柄震动ID
local pad_vibration_is_loop = false     -- 手柄震动是否循环
local camera_vibration_id = 0           -- 相机震动ID
local camera_vibration_property = 0     -- 相机震动属性
local called_keys = 0                   -- 调用的按键

-- 相机效果测试参数
local test_fov_offset = 36              -- 测试FOV偏移
local test_distance_offset = 2.6        -- 测试距离偏移
local test_radial_blur = 5.0            -- 测试径向模糊
local test_duration = 0.5               -- 测试持续时间
local test_reverse_duration = 0.9       -- 测试恢复时间
local test_use_reverse = true           -- 是否使用reverse阶段

-- 测试日志缓冲区
local test_log_buffer = {}
local test_log_max_lines = 10

-- 添加测试日志
local function add_test_log(message, is_error)
    table.insert(test_log_buffer, {
        msg = message,
        is_error = is_error or false,
        time = os.clock()
    })
    -- 限制日志数量
    if #test_log_buffer > test_log_max_lines then
        table.remove(test_log_buffer, 1)
    end
end

-- 绘制调试UI
function ui.draw_debug_ui()
    if imgui.tree_node("YUN_DEBUGS") then
        if not core.master_player then
            imgui.tree_pop()
            return
        end

        -- 速度改变调试
        local need_speed_change = {}  -- 如果需要，应该从derive模块暴露

        -- 基础数据
        if imgui.tree_node("基础数据") then
            imgui.drag_int("武器类型", core._wep_type)
            imgui.drag_int("动作库ID", core._action_bank_id)
            imgui.drag_int("动作ID", core._action_id)
            imgui.drag_float("帧数", action.get_now_action_frame())
            imgui.drag_float("无敌帧", player.get_muteki_time())
            imgui.text("动作值ID: " .. action.get_motion_value_id())
            imgui.same_line()
            imgui.text(", 动作值: " .. action.get_motion_value())
            imgui.drag_int("前一个动作ID", action.get_pre_action_id())
            imgui.drag_float("玩家速度", player.get_player_timescale())
            imgui.text(string.format("当前节点: 0x%06X", action.get_current_node()))
            imgui.text("当前技能书: " .. core.master_player:get_field("_ReplaceAtkMysetHolder"):call("getSelectedIndex"))
            imgui.same_line()
            imgui.text(", 替换技能: ")
            imgui.same_line()
            for i = 1, 6 do
                imgui.text(player.get_replace_attack_data()[i])
                if i ~= 6 then
                    imgui.same_line()
                end
            end
            imgui.tree_pop()
        end

        -- 震动数据
        if imgui.tree_node("震动数据") then
            imgui.text("手柄震动ID = " .. pad_vibration_id)
            local changed
            changed, pad_vibration_id = imgui.input_text("手柄震动ID", pad_vibration_id)
            changed, pad_vibration_is_loop = imgui.checkbox("手柄震动是否循环", pad_vibration_is_loop)

            if imgui.button("震动ID ++") then
                pad_vibration_id = pad_vibration_id + 1
            end
            imgui.same_line()
            if imgui.button("调用震动") then
                effects.set_pad_vibration(tonumber(pad_vibration_id), pad_vibration_is_loop)
            end
            imgui.same_line()
            if imgui.button("停止震动") then
                core.Pad:stopAllPadVibration()
            end
            imgui.same_line()
            if imgui.button("震动ID --") then
                pad_vibration_id = pad_vibration_id - 1
            end
            imgui.tree_pop()
        end

        -- 相机震动数据
        if imgui.tree_node("相机震动数据") then
            imgui.text("相机震动ID = " .. camera_vibration_id)
            local changed
            changed, camera_vibration_id = imgui.input_text("相机震动ID", camera_vibration_id)
            imgui.text("相机震动属性 = " .. camera_vibration_property)
            changed, camera_vibration_property = imgui.input_text("相机震动属性", camera_vibration_property)

            if imgui.button("震动ID ++") then
                camera_vibration_id = camera_vibration_id + 1
            end
            imgui.same_line()
            if imgui.button("调用震动") then
                effects.set_camera_vibration(tonumber(camera_vibration_id), tonumber(camera_vibration_property))
            end
            imgui.same_line()
            if imgui.button("震动ID --") then
                camera_vibration_id = camera_vibration_id - 1
            end
            imgui.tree_pop()
        end

        -- 相机效果测试
        if imgui.tree_node("相机效果测试") then
            imgui.text_colored("手动测试相机特效系统", 0xFFFFFF00)
            imgui.spacing()

            local changed
            changed, test_fov_offset = imgui.slider_float("FOV偏移", test_fov_offset, -50, 50)
            changed, test_distance_offset = imgui.slider_float("距离偏移", test_distance_offset, 0, 10)
            changed, test_radial_blur = imgui.slider_float("径向模糊", test_radial_blur, 0, 15)
            changed, test_duration = imgui.slider_float("Forward持续时间", test_duration, 0.1, 2)
            changed, test_reverse_duration = imgui.slider_float("Reverse持续时间", test_reverse_duration, 0.1, 2)
            changed, test_use_reverse = imgui.checkbox("启用Reverse阶段", test_use_reverse)

            imgui.spacing()

            -- 测试按钮 - 立即触发
            if imgui.button("立即触发相机效果") then
                local test_config = {
                    fov_offset = test_fov_offset,
                    distance_offset = test_distance_offset,
                    radial_blur = test_radial_blur,
                    duration = test_duration,
                    easing = "ease_out",
                    reverse = test_use_reverse,
                    reverse_duration = test_reverse_duration,
                    reverse_easing = "ease_in",
                }
                local success = effects.trigger_camera_effect(test_config)
            end

            imgui.same_line()
            if imgui.button("清除所有效果") then
                local success = effects.clear_all_camera_effects()
            end

            imgui.spacing()
            imgui.separator()
            imgui.spacing()

            -- 显示当前状态
            imgui.text_colored("当前状态:", 0xFF00FFFF)
            imgui.text("活跃相机效果数: " .. tostring(effects.get_active_camera_effects_count()))
            imgui.text("武器类型: " .. tostring(core._wep_type))
            imgui.text("动作ID: " .. tostring(core._action_id))
            imgui.text("动作帧: " .. tostring(math.floor(core._action_frame or 0)))
            imgui.text("节点ID: " .. string.format("0x%X", action.get_current_node()))

            imgui.tree_pop()
        end

        -- 派生数据
        if imgui.tree_node("派生数据") then
            imgui.text("当前派生命令 = " .. derive.get_this_derive_cmd())
            imgui.text("命中成功 = " .. derive.get_hit_success())
            imgui.checkbox("反击成功", derive.get_counter_success())
            imgui.text("调用的按键 = " .. called_keys)
            local changed
            changed, called_keys = imgui.input_text("调用的按键", called_keys)
            imgui.same_line()
            if imgui.button("调用派生") then
                -- call_derive_in_table 需要被暴露
            end
            imgui.tree_pop()
        end

        derive.draw_errors()

        imgui.tree_pop()
    end
end

return ui
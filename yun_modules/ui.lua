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

        imgui.tree_pop()
    end
end

return ui
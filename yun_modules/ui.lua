-- yun_modules/ui.lua
-- Debug UI and visualization

local ui = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local player = require("yunwulian.yun_modules.player")
local action = require("yunwulian.yun_modules.action")
local effects = require("yunwulian.yun_modules.effects")
local derive = require("yunwulian.yun_modules.derive")

-- UI state variables
local pad_vibration_id = 0
local pad_vibration_is_loop = false
local camera_vibration_id = 0
local camera_vibration_property = 0
local called_keys = 0

-- Draw debug UI
function ui.draw_debug_ui()
    if imgui.tree_node("YUN_DEBUGS") then
        if not core.master_player then
            imgui.tree_pop()
            return
        end

        -- Speed change debug
        local need_speed_change = {}  -- Should be exposed from derive module if needed
        utils.printTableWithImGui(need_speed_change)

        -- Base data
        if imgui.tree_node("BASE DATA") then
            imgui.drag_int("weapon_type", core._wep_type)
            imgui.drag_int("action_bank_id", core._action_bank_id)
            imgui.drag_int("action_id", core._action_id)
            imgui.drag_float("frame", action.get_now_action_frame())
            imgui.drag_float("muteki frame", player.get_muteki_time())
            imgui.text("motion_value_id: " .. action.get_motion_value_id())
            imgui.same_line()
            imgui.text(", motion_value: " .. action.get_motion_value())
            imgui.drag_int("pre action_id", action.get_pre_action_id())
            imgui.drag_float("player speed", player.get_player_timescale())
            imgui.text(string.format("current node: 0x%06X", action.get_current_node()))
            imgui.text("now book: " .. core.master_player:get_field("_ReplaceAtkMysetHolder"):call("getSelectedIndex"))
            imgui.same_line()
            imgui.text(",switch_skills: ")
            imgui.same_line()
            for i = 1, 6 do
                imgui.text(player.get_replace_attack_data()[i])
                if i ~= 6 then
                    imgui.same_line()
                end
            end
            imgui.tree_pop()
        end

        -- Vibration data
        if imgui.tree_node("VIBRATION DATA") then
            imgui.text("pad_vibration_id = " .. pad_vibration_id)
            local changed
            changed, pad_vibration_id = imgui.input_text("pad_vibration_id", pad_vibration_id)
            changed, pad_vibration_is_loop = imgui.checkbox("pad_vibration_is_loop", pad_vibration_is_loop)

            if imgui.button("vibration ID ++") then
                pad_vibration_id = pad_vibration_id + 1
            end
            imgui.same_line()
            if imgui.button("call vibration") then
                effects.set_pad_vibration(tonumber(pad_vibration_id), pad_vibration_is_loop)
            end
            imgui.same_line()
            if imgui.button("stop vibration") then
                core.Pad:stopAllPadVibration()
            end
            imgui.same_line()
            if imgui.button("vibration ID --") then
                pad_vibration_id = pad_vibration_id - 1
            end
            imgui.tree_pop()
        end

        -- Camera vibration data
        if imgui.tree_node("CAMERA VIBRATION DATA") then
            imgui.text("camera_vibration_id = " .. camera_vibration_id)
            local changed
            changed, camera_vibration_id = imgui.input_text("camera_vibration_id", camera_vibration_id)
            imgui.text("camera_vibration_property = " .. camera_vibration_property)
            changed, camera_vibration_property = imgui.input_text("camera_vibration_property", camera_vibration_property)

            if imgui.button("vibration ID ++") then
                camera_vibration_id = camera_vibration_id + 1
            end
            imgui.same_line()
            if imgui.button("call vibration") then
                effects.set_camera_vibration(tonumber(camera_vibration_id), tonumber(camera_vibration_property))
            end
            imgui.same_line()
            if imgui.button("vibration ID --") then
                camera_vibration_id = camera_vibration_id - 1
            end
            imgui.tree_pop()
        end

        -- Derive data
        if imgui.tree_node("DERIVE DATA") then
            imgui.text("this_derive_cmd = " .. derive.get_this_derive_cmd())
            imgui.text("hit_success = " .. derive.get_hit_success())
            imgui.checkbox("counter_success", derive.get_counter_success())
            imgui.text("called_keys = " .. called_keys)
            local changed
            changed, called_keys = imgui.input_text("called_keys", called_keys)
            imgui.same_line()
            if imgui.button("call derive") then
                -- call_derive_in_table would need to be exposed
            end
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end

return ui

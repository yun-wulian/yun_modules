-- yun_modules/state.lua
-- Game state detection functions

local state = {}
local core = require("yunwulian.yun_modules.core")

-- Quest change callbacks
state.quest_change_functions = {}

function state.on_quest_change(change_functions)
    if type(change_functions) == "function" then
        table.insert(state.quest_change_functions, change_functions)
    end
end

-- Check if HUD should be shown
function state.should_hud_show()
    if not core.GuiManager then
        core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    end
    if not core.GuiManager then return end
    return not core.GuiManager:call("IsStartMenuAndSubmenuOpen") and
           not core.GuiManager:get_field("InvisibleAllGUI") and
           core.GuiManager:call("isOpenHudSharpness")
end

-- Check if player is in quest
function state.is_in_quest()
    if not core.GuiManager then
        core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    end
    if not core.GuiManager then return end
    return core.is_in_quest or core.GuiManager:call("isOpenHudSharpness")
end

-- Check if game is paused
function state.is_pausing()
    if not core.TimeScaleManager then
        core.TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager')
    end
    return core.TimeScaleManager:call("get_Pausing")
end

-- Check if combat features should be enabled
function state.enabled()
    return state.is_in_quest() and not core.is_loading_visiable
end

-- Check if UI should be drawn
function state.should_draw_ui()
    return core._should_draw_ui
end

-- Update the should_draw_ui flag (called internally)
function state.update_should_draw_ui()
    core._should_draw_ui = state.enabled() and not state.is_pausing() and state.should_hud_show()
end

return state

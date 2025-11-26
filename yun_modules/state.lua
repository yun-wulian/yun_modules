-- yun_modules/state.lua
-- 游戏状态检测函数

local state = {}
local core = require("yunwulian.yun_modules.core")

-- 任务改变回调
state.quest_change_functions = {}

-- 添加任务改变回调函数
---@param change_functions function 回调函数
function state.on_quest_change(change_functions)
    if type(change_functions) == "function" then
        table.insert(state.quest_change_functions, change_functions)
    end
end

-- 检查HUD是否应该显示
---@return boolean 是否显示HUD
function state.should_hud_show()
    if not core.GuiManager then
        core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    end
    if not core.GuiManager then return end
    return not core.GuiManager:call("IsStartMenuAndSubmenuOpen") and
           not core.GuiManager:get_field("InvisibleAllGUI") and
           core.GuiManager:call("isOpenHudSharpness")
end

-- 检查玩家是否在任务中
---@return boolean 是否在任务中
function state.is_in_quest()
    if not core.GuiManager then
        core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    end
    if not core.GuiManager then return end
    return core.is_in_quest or core.GuiManager:call("isOpenHudSharpness")
end

-- 检查游戏是否暂停
---@return boolean 是否暂停
function state.is_pausing()
    if not core.TimeScaleManager then
        core.TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager')
    end
    return core.TimeScaleManager:call("get_Pausing")
end

-- 检查战斗功能是否应该启用
---@return boolean 是否启用
function state.enabled()
    return state.is_in_quest() and not core.is_loading_visiable
end

-- 检查是否应该绘制UI
---@return boolean 是否绘制UI
function state.should_draw_ui()
    return core._should_draw_ui
end

-- 更新should_draw_ui标志（内部调用）
function state.update_should_draw_ui()
    core._should_draw_ui = state.enabled() and not state.is_pausing() and state.should_hud_show()
end

return state
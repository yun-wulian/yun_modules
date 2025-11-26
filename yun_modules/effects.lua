-- yun_modules/effects.lua
-- 视觉和触觉特效函数

local effects = {}
local core = require("yunwulian.yun_modules.core")

-- 在玩家位置生成特效
---@param contianer any 容器
---@param efx any 特效
function effects.set_effect(contianer, efx)
    if not core.master_player then return end
    core.master_player:call("setItemEffect", contianer, efx)
end

-- 触发相机震动
---@param index number 震动索引
---@param priority number 优先级
function effects.set_camera_vibration(index, priority)
    if not core.CameraManager then return end
    if not core.master_player then return end
    core.CameraManager:get_RefCameraVibration():RequestVibration_Player(core.master_player, index, priority)
end

-- 触发手柄震动
---@param id number 震动ID
---@param is_loop boolean 是否循环
function effects.set_pad_vibration(id, is_loop)
    if not is_loop then is_loop = false end
    if not core.Pad then return end
    core.Pad:requestVibration(id, is_loop)
end

return effects
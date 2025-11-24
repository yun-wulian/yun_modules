-- yun_modules/effects.lua
-- Visual and haptic effects functions

local effects = {}
local core = require("yunwulian.yun_modules.core")

-- Spawn effect at player position
function effects.set_effect(contianer, efx)
    if not core.master_player then return end
    core.master_player:call("setItemEffect", contianer, efx)
end

-- Trigger camera vibration
function effects.set_camera_vibration(index, priority)
    if not core.CameraManager then return end
    if not core.master_player then return end
    core.CameraManager:get_RefCameraVibration():RequestVibration_Player(core.master_player, index, priority)
end

-- Trigger controller/pad vibration
function effects.set_pad_vibration(id, is_loop)
    if not is_loop then is_loop = false end
    if not core.Pad then return end
    core.Pad:requestVibration(id, is_loop)
end

return effects

-- 通用慢镜头：命名配置、单一时间缩放控制器、按请求优先级仲裁。
local slowmo = {}
local core = require("yunwulian.yun_modules.core")
local player = require("yunwulian.yun_modules.player")
local state = require("yunwulian.yun_modules.state")
local scene_manager_type = sdk.find_type_definition("via.SceneManager")
local profiles = {}
local active = nil

local function nonnegative(value, name)
    assert(type(value) == "number" and value == value and value >= 0 and value < math.huge, name .. " must be finite and nonnegative")
    return value
end

-- duration/recover_time 控制世界；player_duration/player_recover_time 可让玩家提前恢复。
-- total_duration 为包含渐入在内的总时长上限；on_stop(reason) 只在结束或取消时调用。
function slowmo.register(key, config)
    assert(type(key) == "string" and key ~= "", "slowmo key must be a nonempty string")
    assert(type(config) == "table", "slowmo config must be a table")
    local speed = nonnegative(config.speed, "speed")
    assert(speed > 0 and speed <= 1, "speed must be in (0, 1]")
    local duration = nonnegative(config.duration, "duration")
    local recovery = nonnegative(config.recover_time, "recover_time")
    if config.on_stop ~= nil then assert(type(config.on_stop) == "function", "on_stop must be a function") end
    profiles[key] = {
        speed = speed, duration = duration, recover_time = recovery,
        player_duration = nonnegative(config.player_duration or duration, "player_duration"),
        player_recover_time = nonnegative(config.player_recover_time or recovery, "player_recover_time"),
        separate_player = config.player_duration ~= nil or config.player_recover_time ~= nil,
        total_duration = config.total_duration and nonnegative(config.total_duration, "total_duration"),
        priority = nonnegative(config.priority or 0, "priority"),
        allow_online = config.allow_online == true,
        on_stop = config.on_stop,
    }
end

local function is_online()
    local lobby = sdk.get_managed_singleton("snow.LobbyManager")
    return lobby and lobby:IsQuestOnline() == true
end

local function get_targets()
    local manager = sdk.get_native_singleton("via.SceneManager")
    local scene = manager and sdk.call_native_func(manager, scene_manager_type, "get_CurrentScene")
    local mp = core.master_player
    local player_object = mp and mp:get_GameObject()
    local time_manager = sdk.get_managed_singleton("snow.TimeScaleManager")
    local camera = sdk.get_managed_singleton("snow.CameraManager")
    local keyboard = sdk.get_managed_singleton("snow.GameKeyboard")
    return {
        scene = scene, time_manager = time_manager, player = player_object,
        camera = camera and camera:get_GameObject(),
        keyboard = keyboard and keyboard:get_GameObject(),
    }
end

local function capture_scales(targets)
    local saved = {}
    for name, object in pairs(targets) do
        saved[name] = { object = object, scale = object:get_TimeScale() }
    end
    return saved
end

local function same_targets(previous, current)
    for name, object in pairs(previous) do
        if current[name] ~= object then return false end
    end
    return true
end

local function restore_scales(saved)
    local targets = get_targets()
    for name, entry in pairs(saved) do
        if targets[name] == entry.object then entry.object:set_TimeScale(entry.scale) end
    end
end

function slowmo.is_active(key)
    return active ~= nil and (key == nil or active.key == key)
end

function slowmo.stop(key, reason)
    if not slowmo.is_active(key) then return false end
    local request = active
    active = nil
    restore_scales(request.saved)
    if request.config.on_stop then request.config.on_stop(reason or "cancelled") end
    return true
end

local function apply_scales(request, world_scale, player_scale)
    local targets = request.targets
    targets.scene:set_TimeScale(world_scale)
    targets.time_manager:set_TimeScale(world_scale)
    targets.player:set_TimeScale(player_scale)
    if targets.camera then targets.camera:set_TimeScale(1.0) end
    if targets.keyboard then targets.keyboard:set_TimeScale(1.0) end
end

-- enter_time 是从当前速度渐入的时长；成功事件传 0 可立即减速。
-- 低优先级请求不重启或延长正在播放的高优先级慢镜头。
function slowmo.trigger(key, enter_time)
    local config = assert(profiles[key], "unregistered slowmo: " .. tostring(key))
    enter_time = nonnegative(enter_time or 0, "enter_time")
    if not state.enabled() or state.is_pausing() or (not config.allow_online and is_online()) then return false end
    local targets = get_targets()
    if not targets.scene or not targets.player or not targets.time_manager then return false end
    if active and not same_targets(active.targets, targets) then
        slowmo.stop(nil, "context_changed")
    end
    if active and config.priority < active.config.priority then return false end

    local previous = active
    local saved = previous and previous.saved or capture_scales(targets)
    local now = player.get_time()
    active = {
        key = key, config = config, saved = saved, targets = targets,
        requested_at = now, trigger_at = now + enter_time, last_update = now,
        phase = enter_time > 0 and "enter" or "hold",
        hold_started_at = enter_time == 0 and now or 0,
        recover_started_at = 0,
        speed = math.min(config.speed, saved.scene.scale),
    }
    if previous and previous.key ~= key and previous.config.on_stop then previous.config.on_stop("replaced") end
    if enter_time == 0 then apply_scales(active, active.speed, active.speed) end
    return true
end

local function step_scale(current, target, duration, dt, distance)
    if duration == 0 then return target end
    local step = distance / duration * dt
    if current > target then return math.max(target, current - step) end
    return math.min(target, current + step)
end

function slowmo.update()
    local request = active
    if not request then return end
    local targets = get_targets()
    if not same_targets(request.targets, targets) then
        slowmo.stop(nil, "context_changed")
        return
    end
    if not state.enabled() or (not request.config.allow_online and is_online()) then
        slowmo.stop(nil, "disabled")
        return
    end
    if core._action_bank_id == 1 or core._action_bank_id == 5 then
        slowmo.stop(nil, "action_interrupted")
        return
    end

    local now = player.get_time()
    local dt = now - request.last_update
    request.last_update = now
    if state.is_pausing() then
        request.requested_at = request.requested_at + dt
        request.trigger_at = request.trigger_at + dt
        request.hold_started_at = request.hold_started_at + dt
        request.recover_started_at = request.recover_started_at + dt
        return
    end

    local config = request.config
    local elapsed = now - request.requested_at
    if config.total_duration and elapsed >= config.total_duration then
        slowmo.stop(nil, "complete")
        return
    end
    local world_target = request.saved.scene.scale
    local player_target = request.saved.player.scale
    if player_target < 0 then player_target = world_target end -- -1 表示继承场景速度。
    local speed = request.speed
    local world_distance = math.abs(world_target - speed)
    local world_scale = targets.scene:get_TimeScale()

    if request.phase == "enter" then
        local duration = request.trigger_at - request.requested_at
        local next_scale = step_scale(world_scale, speed, duration, dt, world_distance)
        if now >= request.trigger_at then
            request.phase = "hold"
            request.hold_started_at = now
            next_scale = speed
        end
        apply_scales(request, next_scale, next_scale)
        return
    end

    if request.phase == "hold" then
        local held = now - request.hold_started_at
        local player_scale = speed
        if config.separate_player and held >= config.player_duration then
            player_scale = step_scale(targets.player:get_TimeScale(), player_target,
                config.player_recover_time, dt, math.abs(player_target - speed))
        end
        apply_scales(request, speed, player_scale)
        local hold_finished = held >= config.duration
        if config.total_duration then
            local remaining = config.total_duration - elapsed
            local hold_limit = config.total_duration - math.min(config.recover_time, remaining)
            hold_finished = hold_finished or elapsed >= hold_limit
        end
        if hold_finished then
            request.phase = "recover"
            request.recover_started_at = now
        end
        return
    end

    local recovery = config.recover_time
    if config.total_duration then
        recovery = math.min(recovery, config.total_duration - (request.recover_started_at - request.requested_at))
    end
    local next_scale = step_scale(world_scale, world_target, recovery, dt, world_distance)
    local player_scale = step_scale(targets.player:get_TimeScale(), player_target,
        config.separate_player and config.player_recover_time or recovery, dt, math.abs(player_target - speed))
    apply_scales(request, next_scale, player_scale)
    if next_scale == world_target then slowmo.stop(nil, "complete") end
end

return slowmo

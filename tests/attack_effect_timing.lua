-- Run from yunwulian: lua tests/attack_effect_timing.lua
-- Exercises Lua scheduling through its hook entrypoints; does not emulate game playback.
local core = { _wep_type = 1, _action_id = 117, _pre_action_id = 116, _current_node = 7 }
local storage, registered = {}, {}
sdk = {
    to_managed_object = function(value) return value end,
    find_type_definition = function(name)
        return { get_method = function(_, signature) return name .. ":" .. signature end }
    end,
    hook = function(method, pre, post) registered[method] = { pre, post } end,
}
thread = { get_hook_storage = function() return storage end }
re = { on_pre_application_entry = function() end }
Quaternion = { identity = function() return {} end }
Vector3f = { new = function(x, y, z) return {x = x, y = y, z = z} end }
for _, name in ipairs({ "action", "derive", "state", "utils" }) do
    package.loaded["yunwulian.yun_modules." .. name] = {}
end
package.loaded["yunwulian.yun_modules.core"] = core
package.loaded["yunwulian.yun_modules.constant"] = { on_action_status = { AttackActive = -1 } }
local effects = dofile("yun_modules/effects.lua")
package.loaded["yunwulian.yun_modules.effects"] = effects
dofile("yun_modules/hooks.lua").enable()
assert(registered["snow.hit.AttackWork:initialize(System.Single, System.Single, System.UInt32, System.UInt32, System.Int32, snow.hit.userdata.BaseHitAttackRSData)"])
assert(registered["snow.RSCController:updateAttackWorks()"])

local layer, secondary, motion, rsc, player, calls
local function eq(actual, expected, message)
    assert(actual == expected, (message or "unexpected value") .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end
local function make_layer()
    return {
        frame = 0, id = 117, bank = 100,
        get_Frame = function(self) return self.frame end,
        get_MotionID = function(self) return self.id end,
        get_MotionBankID = function(self) return self.bank end,
        get_PrevMotionID = function() return 116 end,
    }
end
local function fixture(rules)
    effects.clear_attack_effects()
    for id in pairs(effects.effectTable) do effects.pop_effect_table(id) end
    layer, secondary = make_layer(), make_layer()
    motion = {
        state = 0, speed = 1, secondary_speed = 1,
        get_PlayState = function(self) return self.state end,
        get_PlaySpeed = function(self) return self.speed end,
        get_SecondaryPlaySpeed = function(self) return self.secondary_speed end,
    }
    rsc = { get_Motion = function() return motion end, get_DeltaTime = function() return 1 end }
    player = {
        getRSCController = function() return rsc end,
        getMotionLayer = function(_, index) return index == 0 and layer or secondary end,
    }
    core.master_player = player
    core._wep_type, core._action_id, core._pre_action_id, core._current_node = 1, 117, 116, 7
    core.is_loading_visiable = false
    core.mPlBHVT = { getCurrentNodeID = function() return 7 end }
    calls = { spawned = {}, released = 0, one_shot = 0, camera = 0, pad = 0 }
    effects.set_effect_with_instance = function(container, effect)
        local handle = { effect = effect, finished = false, released = false }
        function handle:finishAll() assert(not self.finished); self.finished = true end
        function handle:force_release()
            assert(self.finished and not self.released)
            self.released = true
            calls.released = calls.released + 1
        end
        calls.spawned[#calls.spawned + 1] = handle
        return handle
    end
    effects.set_effect = function() calls.one_shot = calls.one_shot + 1 end
    effects.set_camera_vibration = function() calls.camera = calls.camera + 1 end
    effects.set_pad_vibration = function() calls.pad = calls.pad + 1 end
    local id = effects.push_effect_table({ [1] = { [-1] = rules } })
    effects.update_attack_effect_lifecycle()
    return id
end
local function work(id, start_frame, end_frame, ref_layer, attr)
    local data = { get_HitAttr = function() return attr or 0 end }
    return {
        timer = 0, start_frame = start_frame or 20, end_frame = end_frame or 30,
        get_address = function() return id or 1 end,
        get_RSCCtrl = function() return rsc end,
        get_StartDelay = function(self) return self.start_frame end,
        get_TotalFrame = function(self) return self.end_frame end,
        get_Timer = function(self) return self.timer end,
        get_RefMotionLayerIndex = function() return ref_layer or 0 end,
        get_HitData = function() return data end,
    }
end
local function initialize(w)
    effects.hook_pre_attack_work_initialize({ [2] = w })
    eq(effects.hook_post_attack_work_initialize(123), 123)
end
local function activate(w) effects.hook_pre_attack_work_activate({ [2] = w }) end
local function destroy(w) effects.hook_pre_attack_work_destroy({ [2] = w }) end
local function step(w, timer, native, primary_frame, secondary_frame)
    layer.frame = primary_frame or timer
    secondary.frame = secondary_frame or timer
    core._action_frame = math.floor(layer.frame)
    effects.hook_pre_update_attack_works({ [2] = rsc })
    if w then w.timer = timer end
    if native then native() end
    eq(effects.hook_post_update_attack_works(456), 456)
end

-- Default rules still sample conditions once at activate, and destroy releases once.
fixture({ { vfx = {150, 1}, frame = 20 }, { vfx = {150, 2}, force_release = false,
    camera_vibration = {1}, pad_vibration = {1} } })
local w = work()
initialize(w)
step(w, 19); eq(#calls.spawned, 0)
step(w, 20, function() activate(w); activate(w) end)
eq(#calls.spawned, 1); eq(calls.one_shot, 1); eq(calls.camera, 1); eq(calls.pad, 1)
destroy(w); destroy(w); eq(calls.released, 1)
fixture({ { vfx = {150, 1}, frame = 21, startOffset = 0, endOffset = 0 } })
w = work(); initialize(w)
step(w, 20, function() activate(w) end)
step(w, 22, function() activate(w) end); eq(#calls.spawned, 0)

-- Fractional advance + delayed release, including a pause and accelerated animation.
fixture({ { vfx = {150, 1}, startOffset = -2.5, endOffset = 5 } })
w = work(); initialize(w)
step(w, 17.4); eq(#calls.spawned, 0)
step(w, 17.5); eq(#calls.spawned, 1)
step(w, 20, function() activate(w) end); eq(#calls.spawned, 1)
step(w, 30, function() destroy(w) end); eq(calls.released, 0)
step(nil, 30); eq(calls.released, 0)
step(nil, 34.5); eq(calls.released, 0)
step(nil, 35); eq(calls.released, 1)

-- A shifted start can fall after native destroy if the extended window still exists.
fixture({ { vfx = {150, 1}, startOffset = 12, endOffset = 5 } })
w = work(); initialize(w)
step(w, 30, function() activate(w); destroy(w) end); eq(#calls.spawned, 0)
step(nil, 32); eq(#calls.spawned, 1)
step(nil, 35); eq(calls.released, 1)

-- Transition during the detached tail cancels it immediately.
fixture({ { vfx = {150, 1}, startOffset = -3, endOffset = 5 } })
w = work(); initialize(w); step(w, 17)
step(w, 30, function() destroy(w) end)
layer.id = 118; step(nil, 31); eq(calls.released, 1)

-- Native initialization has the new motion ID but can still expose the previous
-- animation frame. Only settled updates establish the frame-rewind baseline.
for _, transition in ipairs({
    { old_frame = 144.3, first_frame = 1, start_frame = 22, end_frame = 30, offset = 3 },
    { old_frame = 150.5, first_frame = 1.3, start_frame = 45, end_frame = 73, offset = 5 },
    { old_frame = 48, first_frame = 42, start_frame = 42, end_frame = 60, offset = 5 },
}) do
    fixture({ { vfx = {150, 1}, startOffset = -transition.offset, endOffset = transition.offset } })
    layer.frame = transition.old_frame
    w = work(1, transition.start_frame, transition.end_frame)
    initialize(w)
    step(w, transition.first_frame)
    local trigger = math.max(transition.first_frame, transition.start_frame - transition.offset)
    step(w, trigger); eq(#calls.spawned, 1, "initial animation frame reset must keep the scheduled effect")
    step(w, transition.end_frame, function() destroy(w) end); eq(calls.released, 0)
    step(nil, transition.end_frame + transition.offset); eq(calls.released, 1)
end

-- Delayed start + early release; no flash for an empty or skipped window.
fixture({ { vfx = {150, 1}, startOffset = 2, endOffset = -3 } })
w = work(); initialize(w)
step(w, 20, function() activate(w) end); eq(#calls.spawned, 0)
step(w, 22); eq(#calls.spawned, 1)
step(w, 27); eq(calls.released, 1)
destroy(w); eq(calls.released, 1)
fixture({ { vfx = {150, 1}, startOffset = 9, endOffset = -3 } })
w = work(); initialize(w); step(w, 30, function() activate(w); destroy(w) end)
eq(#calls.spawned, 0)

-- End-only offsets still wait for native activate. Interruption cancels any tail.
fixture({ { vfx = {150, 1}, endOffset = 5 } })
w = work(); initialize(w); step(w, 20); eq(#calls.spawned, 0)
activate(w); eq(#calls.spawned, 1)
step(w, 23, function() destroy(w) end); eq(calls.released, 1)
step(nil, 35); eq(#calls.spawned, 1)

-- Old tail and a newly initialized attack can share an address without sharing lifetime.
fixture({ { vfx = {150, 1}, startOffset = -3, endOffset = 5 } })
w = work(); initialize(w); step(w, 17)
step(w, 30, function() destroy(w) end)
w.start_frame, w.end_frame = 33, 40
initialize(w); step(w, 31); eq(#calls.spawned, 2)
step(w, 35); eq(calls.released, 1); assert(not calls.spawned[2].released)
step(w, 40, function() destroy(w) end)
step(nil, 45); eq(calls.released, 2)

-- Conditions are evaluated at shifted trigger time using the live motion context.
local ready = false
fixture({ { vfx = {150, 1}, startOffset = -3, actionId = 117, preActionId = 116,
    currentNodeId = 7, frame = {17, 18}, specialCondition = function() return ready end } })
w = work(); initialize(w); core._action_id, core._pre_action_id = 999, 998
step(w, 16); ready = true; step(w, 17); eq(#calls.spawned, 1)

-- Removed tables, action transitions, frame rewinds and owner loss clear scheduled effects.
for _, change in ipairs({
    function(id) effects.pop_effect_table(id) end,
    function() layer.id = 118 end,
    function() layer.bank = 101 end,
    function() core._wep_type = 2 end,
}) do
    local id = fixture({ { vfx = {150, 1}, startOffset = -3 } })
    w = work(); initialize(w); step(w, 17); change(id); step(w, 18)
    eq(calls.released, 1)
end
fixture({ { vfx = {150, 1}, startOffset = -3 } })
w = work(); initialize(w); step(w, 17); step(w, 18, nil, 0); eq(calls.released, 1)
fixture({ { vfx = {150, 1}, startOffset = -3 } })
w = work(); initialize(w); step(w, 17)
core.master_player = nil; effects.update_attack_effect_lifecycle(); eq(calls.released, 1)

-- Unknown end cannot be advanced, but can be delayed from actual destroy.
for _, attr in ipairs({0, 256}) do
    fixture({ { vfx = {150, 1}, startOffset = -3, endOffset = -5 },
        { vfx = {150, 2}, startOffset = -3, endOffset = 3 } })
    w = work(1, 20, attr == 0 and -1 or 30, 0, attr)
    initialize(w); step(w, 17); eq(#calls.spawned, 2)
    step(w, 50); eq(calls.released, 0)
    step(w, 60, function() destroy(w) end); eq(calls.released, 1)
    step(nil, 63); eq(calls.released, 2)
end

-- Tail follows the referenced animation layer rather than primary-layer frame count.
fixture({ { vfx = {150, 1}, startOffset = -3, endOffset = 3 } })
w = work(1, 20, 30, 1); initialize(w); step(w, 17, nil, 4, 17)
step(w, 30, function() destroy(w) end, 5, 30)
step(nil, 0, nil, 10, 32); eq(calls.released, 0)
step(nil, 0, nil, 11, 33); eq(calls.released, 1)

-- A timer without a referenced layer follows the RSC/Motion clock after destroy.
fixture({ { vfx = {150, 1}, startOffset = -3, endOffset = 3 } })
w = work(1, 20, 30, -1); initialize(w); step(w, 17)
step(w, 30, function() destroy(w) end); eq(calls.released, 0)
motion.state = 1; step(nil, 30); eq(calls.released, 0)
motion.state, motion.speed, motion.secondary_speed = 0, 2, 0.5
step(nil, 30); step(nil, 30); eq(calls.released, 0)
step(nil, 30); eq(calls.released, 1)

-- Foreign attack hooks and invalid offset inputs must not silently produce effects.
fixture({ { vfx = {150, 1}, startOffset = -3 } })
w = work(); w.get_RSCCtrl = function() return {} end
initialize(w); step(w, 20, function() activate(w); destroy(w) end); eq(#calls.spawned, 0)
fixture({ { vfx = {150, 1}, startOffset = "3" } })
w = work(); local ok, err = pcall(initialize, w)
assert(not ok and err:find("startOffset must be a finite number", 1, true))
effects.clear_attack_effects()
print("Attack effect scheduling checks passed")

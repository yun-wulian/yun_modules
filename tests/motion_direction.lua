-- Run from yunwulian: lua tests/motion_direction.lua
-- Checks the Lua hooks against native root-motion ordering; not an in-game test.
local root = arg[1] or "."
local constant = dofile(root .. '/yun_modules/constant.lua')
package.loaded['yunwulian.yun_modules.constant'] = constant
local core = { action_change_callbacks = {}, direction = constant.direction }
local stick, allowed, angle = true, true, 0
local input = {
    is_push_lstick = function() return stick end,
    check_lstick_dir_for_player = function() return allowed end,
}
package.loaded['yunwulian.yun_modules.core'] = core
package.loaded['yunwulian.yun_modules.input'] = input
local real_input = dofile(root .. '/yun_modules/input.lua')
local quad_calls = 0
input.check_lstick_dir_for_player_only_quad = function(...)
    quad_calls = quad_calls + 1
    return real_input.check_lstick_dir_for_player_only_quad(...)
end

local storage = {}
thread = { get_hook_storage = function() return storage end }
local methods = {
    getMotionID_Layer = function(p) return p.id end,
    getMotionBankID_Layer = function(p) return p.bank end,
    getMotionNowFrame_Layer = function(p) return p.frame end,
    getMotionPrevFrame_Layer = function(p) return p.previous end,
    get_IsMotTransScale = function(p) return p.enabled end,
    set_IsMotTransScale = function(p, enabled) p.enabled = enabled end,
    get_Pos = function(p) return { x = p.x, y = p.y, z = p.z } end,
    set_Pos = function(p, pos) p.x, p.y, p.z = pos.x, pos.y, pos.z end,
    getRadian = function(p) return { x = 0, y = p.yaw, z = 0 } end,
}
sdk = {
    find_type_definition = function(name)
        return {
            get_method = function(_, method)
                local fn = assert(methods[method], method)
                return { call = function(_, ...) return fn(...) end }
            end,
            get_field = function(_, field)
                assert(field == '_commonParam')
                return { get_data = function(_, p) return p.param end }
            end,
        }
    end,
    to_managed_object = function(p) return p end,
}
local action = dofile(root .. '/yun_modules/action.lua')
local player
local function reset()
    player = {
        id = 156, bank = 100, frame = 0, previous = 0,
        param = { enabled = false, scale = 1 },
        x = 0, y = 0, z = 0, rotations = 0,
        yaw = 0, target_angle = 0,
        get_RefPlayerInput = function()
            return {
                getHormdirLstick = function() return angle end,
                checkAnaLever = function() return stick end,
            }
        end,
        get_RefAngleCtrl = function(p)
            return { get_field = function() return p.target_angle end }
        end,
    }
    core.master_player = player
    stick, allowed, angle = true, true, 0
end
local function close(actual, expected, message)
    assert(math.abs(actual - expected) < 1e-8,
        (message or 'value') .. ': ' .. tostring(actual) .. ' ~= ' .. tostring(expected))
end
local function begin(p)
    storage = {}
    action.hook_pre_motion_begin({ nil, p })
    p.callback = p.param.enabled or p.param.slope or p.param.disabled
    assert(action.hook_post_motion_begin('begin-result') == 'begin-result')
end
local function apply(p, delta)
    local x, y, z = delta.x, delta.y, delta.z
    storage = {}
    if p.callback then action.hook_pre_root_apply({ nil, p, delta, 'rotation' }) end
    local scale = p.param.enabled and p.param.scale or 1
    local sx, sy, sz = scale, scale, scale
    if type(scale) == 'table' then sx, sy, sz = scale.x, scale.y, scale.z end
    if p.param.disabled then sx, sy, sz = 0, 0, 0 end
    local c, s = math.cos(p.yaw), math.sin(p.yaw)
    local lx, lz = (delta.x * c - delta.z * s) * sx, (delta.x * s + delta.z * c) * sz
    p.x, p.y, p.z = p.x + lx * c + lz * s, p.y + delta.y * sy, p.z - lx * s + lz * c
    p.rotations = p.rotations + 1
    if p.callback then
        assert(action.hook_post_root_apply('root-result') == 'root-result')
    end
    close(delta.x, x, 'input x restored')
    close(delta.y, y, 'input y preserved')
    close(delta.z, z, 'input z restored')
end
local function request(end_frame, start_frame, multiplier, direction, mode)
    action.move_to_lstick_dir(156, end_frame or 40, start_frame, multiplier, direction, mode)
end

-- Rotation of the requested direction must not change horizontal distance.
for _, direction in ipairs({ 0, math.pi / 2, math.pi, -math.pi / 2, .37 }) do
    reset()
    angle = direction
    request(40, 0, 2)
    begin(player)
    assert(player.callback and not player.param.enabled)
    player.previous, player.frame = 0, 1
    apply(player, { x = 3, y = 2, z = 4 })
    close(math.sqrt(player.x^2 + player.z^2), 10, 'direction-independent distance')
    close(player.x, 10 * math.sin(direction))
    close(player.z, 10 * math.cos(direction))
    close(player.y, 2)
    assert(player.rotations == 1)
end

-- Native scaling is left enabled and applied exactly once.
reset()
player.param.enabled, player.param.scale = true, 2
request(40, 0, 1.5)
begin(player)
assert(player.param.enabled and player.param.scale == 2)
player.frame = 1
apply(player, { x = 3, y = 2, z = 4 })
close(player.z, 15)
close(player.y, 4)

-- An inactive native multiplier is not accidentally activated by registration.
reset()
player.param.scale = 7
request(40, 0, 1)
begin(player)
assert(not player.param.enabled and player.param.scale == 7)
player.frame = 1
apply(player, { x = 3, y = 0, z = 4 })
close(player.z, 5)

-- Crossing either boundary is clipped to the portion of the animation step.
-- Same linear source trajectory, sampled at different and irregular frame rates.
for _, step in ipairs({ .25, .5, 1, 2, 3.7, 8 }) do
    reset()
    local now = 0
    while now < 60 do
        request(40, 10, 2)
        begin(player)
        local next_frame = math.min(60, now + step)
        player.previous, player.frame = now, next_frame
        apply(player, { x = 0, y = 0, z = next_frame - now })
        now = next_frame
    end
    close(player.z, 80, 'frame-rate-independent window')
end

-- Released/rejected stick leaves native motion intact outside the blocked prefix.
for _, reason in ipairs({ 'released', 'direction' }) do
    reset()
    if reason == 'released' then stick = false else allowed = false end
    request(40, 10, 2, 0)
    begin(player)
    player.previous, player.frame = 9, 11
    apply(player, { x = 6, y = 4, z = 8 })
    close(player.x, 3)
    close(player.z, 4)
    close(player.y, 4)
end

-- A request is consumed once; duplicate submissions do not stack extra movement.
reset()
request(40, 0, 2)
request(40, 0, 2)
begin(player)
player.frame = 1
apply(player, { x = 0, y = 0, z = 1 })
begin(player)
assert(not player.callback)
player.previous, player.frame = 1, 2
apply(player, { x = 0, y = 0, z = 1 })
close(player.z, 3)
assert(player.rotations == 2)

-- Motion/bank/player switches invalidate requests without mutating native flags.
for _, change in ipairs({ 'id', 'bank', 'player' }) do
    reset()
    request(40, 0, 2)
    if change == 'player' then
        local old = player
        reset()
        begin(old)
        assert(not old.callback)
    else
        player[change] = player[change] + 1
    end
    begin(player)
    assert(not player.callback and not player.param.enabled)
    player.frame = 1
    apply(player, { x = 3, y = 0, z = 4 })
    close(player.x, 3)
    close(player.z, 4)
end

-- Motion can also transition during evaluation, after MotionBegin.
reset()
request(40, 0, 2)
begin(player)
player.id = 157
player.frame = 1
apply(player, { x = 3, y = 0, z = 4 })
close(player.x, 3)
close(player.z, 4)

-- Native suppression still wins; a held animation frame cannot generate movement.
reset()
player.param.disabled = true
request(40, 0, 2)
begin(player)
player.frame = 1
apply(player, { x = 3, y = 0, z = 4 })
close(player.z, 0)
reset()
player.frame, player.previous = 12, 12
request(40, 0, 2)
begin(player)
apply(player, { x = 0, y = 0, z = 0 })
close(player.z, 0)

-- Zero is a real multiplier.
for _, multiplier in ipairs({ 0, 1 }) do
    reset()
    request(40, 0, multiplier)
    begin(player)
    player.frame = 1
    apply(player, { x = 3, y = 0, z = 4 })
    close(player.z, 5 * multiplier)
end
reset()
request(40)
begin(player)
player.frame = 1
apply(player, { x = 3, y = 0, z = 4 })
close(player.z, 5, 'default multiplier')

-- Four-way movement uses the existing resolver and actual facing, without turning.
local cases = {
    { .2, constant.direction.Up, 0 },
    { 1.0, constant.direction.Left, math.pi / 2 },
    { -1.0, constant.direction.Right, -math.pi / 2 },
    { math.pi - .2, constant.direction.Down, math.pi },
}
for _, yaw in ipairs({ 0, 1.1, math.pi - .1, -math.pi + .1 }) do
    for _, case in ipairs(cases) do
        reset()
        player.yaw, player.target_angle = yaw, yaw + 1
        player.x, player.z = 150, -300
        angle = yaw + case[1]
        local before = quad_calls
        request(40, 0, 1, nil, constant.move_direction_mode.FourWay)
        begin(player)
        player.frame = 1
        apply(player, { x = 3, y = 2, z = 4 })
        assert(quad_calls > before, 'existing quadrant resolver must be used')
        close(player.x - 150, 5 * math.sin(yaw + case[3]))
        close(player.z + 300, 5 * math.cos(yaw + case[3]))
        close(player.yaw, yaw, 'facing unchanged')
        close(player.target_angle, yaw + 1, 'target facing unchanged')
        close(player.y, 2)
    end
end

-- Diagonals have exactly one quadrant, with no gaps or overlap across angle wrap.
reset()
for degrees = -720, 720, .5 do
    angle = math.rad(degrees)
    local matches = 0
    for direction = 0, 3 do
        if real_input.check_lstick_dir_for_player_only_quad(direction, 0) then matches = matches + 1 end
    end
    assert(matches == 1, 'quadrant partition at ' .. degrees)
end
player.target_angle = 1.3
angle = 1.3
assert(real_input.check_lstick_dir_for_player_only_quad(constant.direction.Up))

-- Snap length is measured after native anisotropic scaling, independently of facing.
for _, yaw in ipairs({ 0, .8 }) do
    for _, case in ipairs(cases) do
        reset()
        player.yaw = yaw
        player.param.enabled, player.param.scale = true, { x = 2, y = 3, z = .5 }
        angle = yaw + case[1]
        request(40, 0, 1, nil, constant.move_direction_mode.FourWay)
        begin(player)
        player.frame = 1
        apply(player, { x = 3, y = 2, z = 4 })
        local lx = (3 * math.cos(yaw) - 4 * math.sin(yaw)) * 2
        local lz = (3 * math.sin(yaw) + 4 * math.cos(yaw)) * .5
        close(math.sqrt(player.x^2 + player.z^2), math.sqrt(lx^2 + lz^2))
        close(player.y, 6)
    end
end

-- Crossing the end frame must neither shrink the increment nor leave the snapped axis.
for _, mode in pairs(constant.move_direction_mode) do
    for _, stick_angle in ipairs({ math.pi / 2, math.pi, -.9 }) do
        reset()
        angle = stick_angle
        player.previous, player.frame = 38, 39
        request(40, 0, 1, nil, mode)
        begin(player)
        player.previous, player.frame = 39, 41
        apply(player, { x = 0, y = 3, z = 2 })
        close(math.sqrt(player.x^2 + player.z^2), 2, 'end-frame length')
        close(player.y, 3)
        if mode == constant.move_direction_mode.FourWay then
            assert(math.abs(player.x) < 1e-8 or math.abs(player.z) < 1e-8, 'four-way axis')
        end
    end
end

-- No stick still means no steering in four-way mode.
reset()
stick = false
request(40, 0, 1, nil, constant.move_direction_mode.FourWay)
begin(player)
player.frame = 1
apply(player, { x = 3, y = 2, z = 4 })
close(player.x, 3)
close(player.z, 4)
assert(not pcall(action.move_to_lstick_dir, 156, 40, 0, 1, nil, 99))
print('motion regression checks passed')

-- Run from autorun: lua yunwulian/tests/damage_reflex_hurtbox.lua
local weapon_types = dofile("yunwulian/yun_modules/constant.lua").weapon_type
local current_player, weapon, scale, callback
local enabled, paused = true, false
local count = 0

package.loaded["yunwulian.yun_modules"] = {
    weapon_type = weapon_types,
    get_master_player = function() return current_player end,
    get_weapon_type = function() return weapon end,
    enabled = function() return enabled end,
    is_pausing = function() return paused end,
    set_hurtbox_scale_override = function(key, value)
        assert(key == "damage_reflex_special_guard")
        scale = value
    end,
}

sdk = {
    to_int64 = function(value) return value.enum end,
    find_type_definition = function()
        return {
            get_field = function(_, name)
                return { get_data = function(_, obj) return obj[name] end }
            end,
            get_method = function(_, name)
                return { call = function(_, obj, tag)
                    if name == "isCheckingNoHitLook" then return obj.no_hit == true end
                    if name == "isCheckingHitLook" then return obj.hit == true end
                    if name == "isActionNoAttackTag(snow.player.ActionNoAttack)"
                        or name == "isActionStatusTag(snow.player.ActStatus)" then
                        return obj.tags[tag] == true
                    end
                    error("Unexpected method: " .. name)
                end }
            end,
        }
    end,
}
re = { on_pre_application_entry = function(entry, fn)
    assert(entry == "UpdateScene")
    callback = fn
end }
dofile("damage_reflex_hurtbox.lua")

local function reset(weapon_name)
    current_player = { tags = {}, _ExGuardType = 0 }
    weapon = weapon_types[weapon_name]
    enabled, paused = true, false
end

local function expect(active, description)
    callback()
    assert(scale == (active and 2.0 or nil), description)
    count = count + 1
end

-- CPP must work without a visual effect, with either sword/axe entry.
-- Attack021 + GuardFrame comes from both native ChargeAxe FSM branches.
reset("ChargeAxe")
current_player.tags[3835935113] = true
current_player["<IsGuardActionDuration>k__BackingField"] = true
expect(true, "CPP guard window without effect")
current_player["<IsGuardActionDuration>k__BackingField"] = false
expect(false, "CPP after guard frame")
current_player["<IsDrawAnchorGuardEffect>k__BackingField"] = true
expect(false, "CPP effect alone is not a counter window")
current_player.tags = {}
current_player["<IsGuardActionDuration>k__BackingField"] = true
expect(false, "ordinary GuardFrame is not CPP")

-- Attack042 remains on Ready Stance recovery nodes; Guard does not.
reset("ChargeAxe")
current_player.tags = { [2057835936] = true, [1032510341] = true }
expect(true, "Ready Stance sword/axe guard")
current_player.tags[1032510341] = nil
current_player["<IsDrawCancelGuardEffect>k__BackingField"] = true
expect(false, "Ready Stance recovery with lingering effect")
current_player.tags = { [1032510341] = true }
expect(false, "ordinary CB shield guard")
current_player._GuardPoint = true
expect(true, "GP independent of motion and visual effect")
current_player._GuardPoint = false
expect(false, "GP window ended")

for _, name in ipairs({ "Hammer", "LongSword", "HeavyBowGun", "DualBlade" }) do
    reset(name)
    current_player._IsCounterAttack = true
    expect(true, name .. " CounterAttack window")
    current_player._IsCounterAttack = false
    current_player._IsCounterShot = true
    current_player["<IsDrawAnchorGuardEffect>k__BackingField"] = true
    expect(false, name .. " follow-up is not a counter window")
end

local lance_expected = { [1] = true, [2] = true, [3] = true, [4] = true, [7] = true }
for guard_type = 0, 9 do
    reset("Lance")
    current_player._ExGuardType = { enum = guard_type }
    expect(lance_expected[guard_type] == true, "Lance guard type " .. guard_type)
end

for _, name in ipairs({ "GreatSword", "ShortSword" }) do
    reset(name)
    expect(false, name .. " ordinary guard")
    current_player._ExGuardType = 1
    expect(true, name .. " special guard")
end

reset("GreatSword")
current_player.tags[2659953485] = true
expect(false, "Guard Tackle outside its GP child")
current_player.tags[1032510341] = true
expect(true, "Guard Tackle GP child")
current_player.tags[2659953485] = nil
expect(false, "ordinary greatsword guard")

local reflex_fields = {
    "<DamageReflex>k__BackingField",
    "<DamageReflex_MR>k__BackingField",
    "<DamageReflex_MR2>k__BackingField",
}
local excluded = { [4] = true, [9] = true, [10] = true, [11] = true }
for _, field in ipairs(reflex_fields) do
    for kind = 0, 11 do
        for _, channel in ipairs({ "no_hit", "hit" }) do
            reset("Bow")
            local info = { ["<CheckType>k__BackingField"] = { enum = kind }, [channel] = true }
            current_player[field] = info
            expect(not excluded[kind], field .. " type " .. kind .. " " .. channel)
            info[channel] = false
            expect(false, "ended reflex must restore scale")
        end
    end
end

reset("Hammer")
current_player._IsCounterAttack = true
expect(true, "active before pause")
paused = true
expect(false, "pause clears override")
paused, enabled = false, false
expect(false, "disabled clears override")
enabled, current_player = true, nil
expect(false, "player loss clears override")
print("damage_reflex_hurtbox: " .. count .. " assertions passed")

-- yun_modules/player.lua
-- Player-related functions and properties

local player = {}
local core = require("yunwulian.yun_modules.core")

-- Time functions
local get_UpTimeSecond = sdk.find_type_definition("via.Application"):get_method("get_UpTimeSecond")
local get_ElapsedSecond = sdk.find_type_definition("via.Application"):get_method("get_ElapsedSecond")

function player.get_time()
    return get_UpTimeSecond:call(nil)
end

function player.get_delta_time()
    return get_ElapsedSecond:call(nil)
end

-- Get player speed/timescale
function player.get_player_timescale()
    if not core.master_player then return end
    if core.master_player:call("get_GameObject") == nil then return end
    return core.master_player:call("get_GameObject"):call("get_TimeScale")
end

-- Set player speed/timescale
function player.set_player_timescale(value)
    if not core.master_player then return end
    if core.master_player:call("get_GameObject") == nil then return end
    core.master_player:call("get_GameObject"):call("set_TimeScale", value + .0)
end

-- Get master player object
function player.get_master_player()
    if core.master_player ~= nil then
        return core.master_player
    end
end

-- Get master player index
function player.get_master_player_index()
    if core.master_player_index ~= nil then
        return core.master_player_index
    end
end

-- Check weapon type
function player.check_using_weapon_type(tar_type)
    if core._wep_type == tar_type then return true end
    return false
end

-- Get weapon type
function player.get_weapon_type()
    if not core.master_player then return end
    return core._wep_type
end

-- Check if player has specific skill level
function player.check_equip_skill_lv(skill)
    if not core.master_player then return end
    local skill_list = core.master_player:call("get_PlayerSkillList")
    for i = 7, 1, -1 do
        if skill_list:call("hasSkill", skill, i) then
            return i
        end
    end
    return 0
end

-- Attack and affinity control
function player.set_atk(value)
    core.atk_flag = true
    core.player_atk = value
end

function player.set_affinity(value)
    core.affinity_flag = true
    core.player_affinity = value
end

function player.clear_atk()
    core.atk_flag = false
end

function player.clear_affinity()
    core.affinity_flag = false
end

function player.get_atk()
    if not core.master_player then return 0 end
    return core._atk
end

function player.get_affinity()
    if not core.master_player then return 0 end
    return core._affinity
end

-- Invincibility time (muteki)
function player.get_muteki_time()
    if not core.master_player then return end
    return core._muteki_time
end

function player.set_muteki_time(value)
    if not core.master_player then return end
    return core.master_player:set_field("_MutekiTime", value)
end

-- Hyper armor time
function player.get_hyper_armor_time()
    if not core.master_player then return end
    return core._hyper_armor_time
end

function player.set_hyper_armor_time(value)
    if not core.master_player then return end
    return core.master_player:set_field("_HyperArmorTimer", value)
end

-- Replace attack data
function player.get_replace_attack_data()
    if not core.master_player then return end
    return core._replace_atk_data
end

-- Health (vital)
function player.get_vital()
    return core.player_data:get__vital()
end

function player.set_vital(new_vital)
    return core.player_data:set__vital(new_vital)
end

function player.get_r_vital()
    return core.player_data:get_field("_r_Vital")
end

function player.set_r_vital(new_r_vital)
    return core.player_data:set_field("_r_Vital", new_r_vital)
end

-- Switch skill functions
function player.get_selected_book()
    if not core.master_player then return nil end
    local ReplaceHolder = core.master_player:get_field("_ReplaceAtkMysetHolder")
    return ReplaceHolder:call("getSelectedIndex")
end

function player.get_switch_skill(book, index)
    if not core.master_player then return 0 end
    local replace_holder = core.master_player:get_field("_ReplaceAtkMysetHolder")
    local replace_data = replace_holder:get_field("_ReplaceAtkMysetData")
    local atk_types = replace_data[book]:get_field("_ReplaceAtkTypes")
    for i = 0, 5 do
        if sdk.to_int64(atk_types[i]) == 0 then return 0 end
    end
    if index == 4 and atk_types then
        if atk_types[4]:get_field("value__") == 1 then return 3 end
        return atk_types[2]:get_field("value__") + 1
    elseif index == 5 and atk_types then
        return atk_types[5]:get_field("value__") + 1
    else
        return 0
    end
end

return player

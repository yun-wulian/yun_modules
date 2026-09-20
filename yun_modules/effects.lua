-- yun_modules/effects.lua
-- 特效系统 - 使用状态机重构（包含相机效果）
--
-- ============================================================================
-- 特效表完整使用说明
-- ============================================================================
--
-- 基础特效规则结构：
-- {
--     frame = 0,                     -- 触发帧（可选，默认0）或帧范围 {start, end}
--     currentNodeId = 0x12345678,    -- 当前节点ID限制（可选）或 {0x123, 0x456} 匹配任意一个
--     preActionId = 123,             -- 前序动作ID限制（可选）或 {123, 124, 125} 匹配任意一个
--     specialCondition = function() return true end,  -- 自定义条件（可选）
--
--     vfx = {150, 210},              -- 视觉特效 {容器ID, 特效ID}（不受hitTrigger影响）
--     force_release = false,         -- 是否强制释放特效（可选，默认false）
--     loop_action = false,           -- 是否为循环动作特效（可选）
--                                    -- true时：每个动作循环周期都会重新触发（帧数回绕时重置触发状态）
--
--     hit = {150, 210},              -- 命中位置特效（单次）或 {{150, 210}, {150, 211}} （多段）
--     isMultiHit = false,            -- 是否多段命中（可选）
--
--     hitTrigger = false,            -- 是否等待命中后触发（可选，默认false）
--                                    -- true时：cameraEffect/camera_vibration/pad_vibration等待命中后触发
--                                    -- false时：满足条件后立即触发
--                                    -- 注意：hitTrigger不影响vfx和hit字段的行为
--
--     cameraEffect = { ... },        -- 相机效果（详见下方）
--     camera_vibration = { ... },    -- 相机震动（详见下方）
--     pad_vibration = { ... },       -- 手柄震动（详见下方）
-- }
--
-- ============================================================================
-- 相机效果（cameraEffect）使用说明
-- ============================================================================
--
-- 注意：所有相机效果都是两阶段的（Forward → Reverse），确保效果总是平滑恢复
--
-- 基础用法：
-- cameraEffect = {
--     fov_offset = -20,              -- FOV偏移值（负数=缩小，正数=放大）
--     distance_offset = 1.5,         -- 相机距离偏移（正数=向前移动）
--     radial_blur = 3.0,             -- 径向模糊强度（0-15）
--     duration = 0.5,                -- Forward持续时间（秒）
--     easing = "ease_out",           -- Forward缓动函数（ease_in/ease_out/ease_in_out/linear）
-- }
-- 以上配置会：
--   1. Forward阶段（0.5秒）：从0偏移到目标值，使用ease_out缓动
--   2. Reverse阶段（0.5秒）：从目标值恢复到0，使用ease_in缓动（默认）
--
-- 自定义恢复效果：
-- cameraEffect = {
--     fov_offset = -36,              -- FOV偏移值
--     distance_offset = 2.6,         -- 距离偏移
--     radial_blur = 5.0,             -- 径向模糊
--     duration = 0.5,                -- Forward持续时间
--     easing = "ease_out",           -- Forward缓动函数
--
--     -- 自定义Reverse阶段（可选）
--     reverse_duration = 0.9,        -- Reverse持续时间（默认=duration）
--     reverse_easing = "ease_in",    -- Reverse缓动函数（默认="ease_in"）
-- }
--
-- ============================================================================
-- 相机震动（camera_vibration）使用说明
-- ============================================================================
--
-- 触发相机震动效果（屏幕抖动）：
-- camera_vibration = {
--     index = 6,                     -- 震动索引（0-10，不同强度）
--     priority = 4,                  -- 优先级（可选，默认0）
-- }
--
-- 或使用简写形式（数组）：
-- camera_vibration = {6, 4}          -- {index, priority}
--
-- ============================================================================
-- 手柄震动（pad_vibration）使用说明
-- ============================================================================
--
-- 触发手柄震动：
-- pad_vibration = {
--     id = 20,                       -- 震动ID
--     is_loop = false,               -- 是否循环（可选，默认false）
-- }
--
-- 或使用简写形式（数组）：
-- pad_vibration = {20, false}        -- {id, is_loop}
--
-- ============================================================================
-- 完整示例
-- ============================================================================
--
-- local effect_table = {
--     [weapon_type.GreatSword] = {
--         [117] = {  -- 动作ID
--             -- 示例1：立即触发的特效（传统用法）
--             {
--                 frame = 0,
--                 currentNodeId = 0x5919622b,
--                 vfx = {150, 210},
--                 cameraEffect = {
--                     fov_offset = 36,
--                     distance_offset = 2.6,
--                     radial_blur = 5.0,
--                     duration = 0.5,
--                     easing = "ease_out",
--                     reverse_duration = 0.9,
--                     reverse_easing = "ease_in",
--                 },
--                 camera_vibration = {index = 6, priority = 4},
--                 pad_vibration = {id = 20, is_loop = false},
--             },
--             -- 示例2：等待命中后触发的特效（新用法）
--             {
--                 frame = 70,                   -- 70帧之后才检测命中
--                 hitTrigger = true,            -- 等待命中后触发
--                 hit = {150, 300},             -- 命中位置特效（仍然正常生成）
--                 camera_vibration = {6, 0},    -- 震动会在命中后触发
--                 specialCondition = function()
--                     return some_condition
--                 end
--             },
--             -- 示例3：使用表格形式匹配多个前序动作
--             {
--                 frame = 0,
--                 preActionId = {420, 421, 422},  -- 从这3个动作之一转换过来都会触发
--                 vfx = {150, 501},
--                 force_release = true,
--             }
--         }
--     }
-- }
--
-- ============================================================================
-- 攻击判定特效（on_action_status.AttackActive）使用说明
-- ============================================================================
--
-- 使用 on_action_status.AttackActive 作为键，可以在攻击判定产生时触发特效，
-- 并在攻击判定结束时自动回收特效。
--
-- 特点：
-- - 特效在 AttackWork:activate 时触发（攻击判定产生，首次调用时触发）
-- - 特效在 AttackWork:destroy 时自动回收（攻击判定结束）
-- - 默认 force_release = true，确保特效被正确回收
-- - 支持所有常规规则条件（specialCondition, currentNodeId, preActionId, actionId, frame）
--
-- 规则结构（新增 actionId 字段用于过滤特定动作）：
-- {
--     actionId = 123,                -- 当前动作ID限制（可选）或 {123, 124} 匹配任意一个
--     currentNodeId = 0x12345678,    -- 当前节点ID限制（可选）
--     preActionId = 123,             -- 前序动作ID限制（可选）
--     frame = 0,                     -- 帧数限制（可选）
--     startOffset = 0,               -- 相对判定开始帧的偏移：负数提前，正数延后
--     endOffset = 0,                 -- 相对判定结束帧的偏移：负数提前，正数延后
--     specialCondition = function() return true end,  -- 自定义条件（可选）
--     vfx = {150, 300},              -- 视觉特效（攻击判定期间显示，结束时自动回收）
--     force_release = true,          -- 默认为true，设为false则不回收
-- }
--
-- 偏移单位为判定的浮点帧数。不填或均为0时，保持原来的 activate/destroy 行为。
-- 偏移规则在实际触发特效时检查条件，frame 仍是条件限制，不是偏移量。
-- 例如 startOffset=-3, endOffset=5：提前3帧出现，延后5帧回收。
-- 提前开始最早到判定初始化；偏移后的区间为空或已错过时不播放。
-- 动作切换、帧回绕、判定提前取消会清理偏移特效。延后回收不跨动作。
-- 无限判定/IgnoreEndDelay 无法预测结束，负 endOffset 不生效，正值从实际结束计时。
--
-- 示例：
-- local effect_table = {
--     [weapon_type.ChargeAxe] = {
--         [on_action_status.AttackActive] = {
--             -- 所有盾斧攻击有判定时触发
--             {
--                 vfx = {150, 300},
--             },
--             -- 只在特定动作时触发
--             {
--                 actionId = {117, 118, 119},  -- 只在这些动作ID时触发
--                 vfx = {150, 301},
--             },
--             -- 带条件的攻击判定特效
--             {
--                 specialCondition = function()
--                     return some_gauge >= 100
--                 end,
--                 vfx = {150, 302},
--             },
--         },
--     }
-- }
-- ============================================================================

local effects = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local constant = require("yunwulian.yun_modules.constant")

-- 引用常量模块的枚举
effects.on_action_status = constant.on_action_status

-- ============================================================================
-- 缓动函数库
-- ============================================================================

local Easing = {}

-- 渐入缓动 (t^2)
function Easing.ease_in(t, start_val, target_val)
    return start_val + (t * t) * (target_val - start_val)
end

-- 渐出缓动 (1 - (1-t)^2)
function Easing.ease_out(t, start_val, target_val)
    return start_val + (1 - (1 - t) * (1 - t)) * (target_val - start_val)
end

-- 线性缓动
function Easing.linear(t, start_val, target_val)
    return start_val + t * (target_val - start_val)
end

-- 渐入渐出缓动
function Easing.ease_in_out(t, start_val, target_val)
    local progress = t < 0.5 and 2 * t * t or 1 - ((-2 * t + 2) ^ 2) / 2
    return start_val + progress * (target_val - start_val)
end

-- 获取缓动函数
function Easing.get(easing_type)
    return Easing[easing_type] or Easing.linear
end

-- 限制值在 [0, 1] 范围内
local function clamp01(v)
    return math.min(1, math.max(0, v))
end

-- ============================================================================
-- 特效表注册
-- ============================================================================

-- 特效规则表 - 结构: { [weapon_type] = { [action_id] = { rules... } } }
-- 使用字典结构支持动态移除
effects.effectTable = {}
effects._effectTableNextId = 1
effects._effectTableToId = {}  -- 表引用到数字ID的映射（用于支持通过表释放）

-- 注册特效表（轮询安全）
-- 多次传入同一个表会返回相同的ID
---@param effect_table table 特效表
---@return number|nil 返回注册的索引ID，失败返回nil
function effects.push_effect_table(effect_table)
    if type(effect_table) == "table" then
        -- 检查是否已经注册过（轮询安全）
        if effects._effectTableToId[effect_table] then
            return effects._effectTableToId[effect_table]
        end

        -- 创建新的注册
        local id = effects._effectTableNextId
        effects._effectTableNextId = effects._effectTableNextId + 1
        effects.effectTable[id] = effect_table
        effects._effectTableToId[effect_table] = id
        return id
    end
    return nil
end

-- 移除特效表（轮询安全）
-- 支持传入表引用或数字ID
---@param id table|number 传入的表引用或注册时返回的索引ID
---@return boolean 是否成功移除
function effects.pop_effect_table(id)
    -- 如果传入的是表引用，查找对应的数字ID
    if type(id) == "table" then
        local numeric_id = effects._effectTableToId[id]
        if numeric_id then
            effects._effectTableToId[id] = nil
            effects.effectTable[numeric_id] = nil
            return true
        end
        return false
    end

    -- 数字ID方式
    if type(id) == "number" and effects.effectTable[id] ~= nil then
        -- 同时清除表引用映射
        local table_ref = effects.effectTable[id]
        if table_ref then
            effects._effectTableToId[table_ref] = nil
        end
        effects.effectTable[id] = nil
        return true
    end
    return false
end

-- ============================================================================
-- 特效验证接口
-- ============================================================================

-- 特效存在性缓存（避免重复查询）
-- 结构: { [containerID] = { [elementID] = true/false, ... }, ... }
local _effect_validity_cache = {}

-- 清除特效存在性缓存（在任务切换等场景调用）
function effects.clear_validity_cache()
    _effect_validity_cache = {}
end

-- 检查特效ID是否存在于当前玩家的EPV实例中
---@param container number 容器ID（EPV实例ID）
---@param efx number 特效ID（element ID）
---@return boolean 特效是否存在
function effects.is_effect_exists(container, efx)
    if not core.master_player then return false end

    -- 检查缓存
    if _effect_validity_cache[container] then
        local cached = _effect_validity_cache[container][efx]
        if cached ~= nil then
            return cached
        end
    end

    local eff_manager = core.master_player:getObjectEffectManager()
    if not eff_manager then return false end

    -- StandardDataMap: Dictionary<uint, EPVStandardData>
    local standard_data_map = eff_manager:get_field("StandardDataMap")
    if not standard_data_map then return false end

    -- 检查该 containerID 对应的 EPV 是否存在
    local success, standard_data = pcall(function()
        return standard_data_map:get_Item(container)
    end)
    if not success or not standard_data then
        -- 缓存不存在的容器
        if not _effect_validity_cache[container] then
            _effect_validity_cache[container] = {}
        end
        _effect_validity_cache[container][efx] = false
        return false
    end

    -- 检查该 EPV 中是否有指定的 element ID
    local element = standard_data:getElementFromID(efx)
    local exists = element ~= nil

    -- 缓存结果
    if not _effect_validity_cache[container] then
        _effect_validity_cache[container] = {}
    end
    _effect_validity_cache[container][efx] = exists

    return exists
end

-- 获取指定容器的所有有效特效ID列表
---@param container number 容器ID
---@return table|nil 特效ID列表，失败返回nil
function effects.get_effect_id_list(container)
    if not core.master_player then return nil end

    local eff_manager = core.master_player:getObjectEffectManager()
    if not eff_manager then return nil end

    local standard_data_map = eff_manager:get_field("StandardDataMap")
    if not standard_data_map then return nil end

    local success, standard_data = pcall(function()
        return standard_data_map:get_Item(container)
    end)
    if not success or not standard_data then return nil end

    local id_list = standard_data:getElementIDList()
    if not id_list then return nil end

    -- 转换为 Lua 表
    local result = {}
    local count = id_list:get_Count()
    for i = 0, count - 1 do
        table.insert(result, id_list:get_Item(i))
    end

    return result
end

-- ============================================================================
-- 对外公开的特效 API
-- ============================================================================

local request_position_effect = sdk.find_type_definition("via.effect.script.ObjectEffectManager"):get_method(
    "requestEffect(via.effect.script.EffectID, via.vec3, via.Quaternion, via.GameObject, System.String, via.effect.script.EffectManager.WwiseTriggerInfo)")
local identity_rotation = Quaternion.identity()
local position_effect_ids = {}

local function request_effect(container, efx, position, follow_target, follow_joint)
    if not core.master_player or not core.master_player:isMasterPlayer() then return nil end
    if not effects.is_effect_exists(container, efx) then return nil end
    local manager = core.master_player:getObjectEffectManager()
    if not manager then return nil end

    local ids = position_effect_ids[container]
    if not ids then
        ids = {}
        position_effect_ids[container] = ids
    end
    local id = ids[efx]
    if not id then
        id = sdk.create_instance("via.effect.script.EffectID", true):add_ref()
        id.ContainerID, id.ElementID = container, efx
        ids[efx] = id
    end
    return request_position_effect:call(manager, id, position, identity_rotation, follow_target, follow_joint, nil)
end

-- 世界坐标定点特效；不发送缺少坐标信息的 SingleEffectCallPacket。
function effects.set_effect_at_position(container, efx, position)
    return request_effect(container, efx, position, nil, nil)
end

-- 原生 requestEffect 绑定父对象/骨骼时，位置和旋转使用父空间。
function effects.set_effect_at_joint(container, efx, target, joint_name, local_position)
    return request_effect(container, efx, local_position, target, joint_name)
end

-- 内部函数：发送特效同步网络包
---@param container number 容器ID
---@param efx number 特效ID
local function send_effect_sync_packet(container, efx)
    if not core.master_player then return end
    local player_network = core.master_player:get_RefNetwork()
    if player_network then
        pcall(function()
            player_network:sendSingleEffectCallPacket(container, efx)
        end)
    end
end

-- 在玩家位置生成特效（不返回实例，一次性特效）
-- 此方法生成的特效会自动消失，无需手动释放，默认同步给队友
---@param container number 容器ID
---@param efx number 特效ID
---@param sync boolean|nil 是否同步给队友（可选，默认true）
---@return boolean 是否成功调用
function effects.set_effect(container, efx, sync)
    if not core.master_player or not core.master_player:isMasterPlayer() then return false end
    if not effects.is_effect_exists(container, efx) then return false end
    pcall(function() core.master_player:setItemEffect(container, efx) end)
    -- 同步给队友（默认同步）
    if sync ~= false then
        send_effect_sync_packet(container, efx)
    end
    return true
end

-- 在玩家位置生成特效（返回实例，用于后续释放）
-- 注意：此方法默认不同步给队友，因为释放特效无法同步，会导致队友端特效累积
---@param container number 容器ID
---@param efx number 特效ID
---@param sync boolean|nil 是否同步给队友（可选，默认false，因为释放无法同步）
---@return userdata|nil 特效实例，失败返回nil
function effects.set_effect_with_instance(container, efx, sync)
    if not core.master_player then return nil end
    if not effects.is_effect_exists(container, efx) then return nil end
    local success, instance = pcall(function()
        return core.master_player:setEffect(container, efx)
    end)
    if success and instance then
        -- 默认不同步（因为释放无法同步，会导致队友端累积）
        -- 只有明确指定 sync=true 时才同步
        if sync == true then
            send_effect_sync_packet(container, efx)
        end
        return instance
    end
    return nil
end

-- 触发相机震动
---@param index number 震动索引
---@param priority number 优先级
function effects.set_camera_vibration(index, priority)
    if not core.CameraManager then return end
    if not core.master_player then return end
    local vibration = core.CameraManager:get_RefCameraVibration()
    if not vibration then return end
    vibration:RequestVibration_Player(core.master_player, index, priority)
end

-- 触发手柄震动
---@param id number 震动ID
---@param is_loop boolean 是否循环
function effects.set_pad_vibration(id, is_loop)
    if not is_loop then is_loop = false end
    if not core.Pad then return end
    core.Pad:requestVibration(id, is_loop)
end

-- ============================================================================
-- 特效上下文 - 管理特效过程中的全局状态
-- ============================================================================

local EffectContext = {}
EffectContext.__index = EffectContext

function EffectContext.new()
    local self = setmetatable({}, EffectContext)

    -- 动作历史记录
    self.current_motion = 0
    self.last_motion = 0
    self.motion_bank = 0

    -- 帧数追踪（用于检测循环动作的帧数回绕）
    self.last_frame = 0

    -- 特效实例管理
    self.effect_instances = {}  -- 需要强制释放的特效实例

    -- 命中特效缓存
    self.hit_cache = {}
    self.hit_count = 0

    -- 记录已触发的特效（防止重复触发）
    self.triggered_effects = {}  -- key: "motion_index", value: true

    -- 循环动作规则追踪（只有使用了 loop_action 的规则才会被记录）
    -- 结构: { [motion_id] = { [rule_index] = true } }
    self.loop_action_triggers = nil  -- 惰性初始化，没有 loop_action 规则时为 nil

    return self
end

-- 重置上下文（动作改变时）
function EffectContext:reset()
    -- 释放所有强制释放的特效
    self:release_all_effects()

    -- 清空记录
    self.triggered_effects = {}
    self.hit_cache = {}
    self.hit_count = 0
    self.last_frame = 0
    self.loop_action_triggers = nil  -- 重置循环动作追踪
    self:clear_hit_trigger_cache()  -- 清除命中触发缓存
end

-- 更新动作历史
function EffectContext:update_motion_history(new_motion, new_bank)
    if self.current_motion ~= new_motion then
        self.last_motion = self.current_motion
        self.current_motion = new_motion
        self:reset()
    end
    self.motion_bank = new_bank
end

-- 检查特效是否已触发（使用嵌套表，零字符串拼接开销）
function EffectContext:is_effect_triggered(motion_id, rule_index)
    local motion_table = self.triggered_effects[motion_id]
    if not motion_table then
        return false
    end
    return motion_table[rule_index] == true
end

-- 标记特效已触发（使用嵌套表，零字符串拼接开销）
function EffectContext:mark_effect_triggered(motion_id, rule_index)
    local motion_table = self.triggered_effects[motion_id]
    if not motion_table then
        motion_table = {}
        self.triggered_effects[motion_id] = motion_table
    end
    motion_table[rule_index] = true
end

-- 注册需要强制释放的特效实例
function EffectContext:register_effect_instance(instance)
    if instance then
        table.insert(self.effect_instances, instance)
    end
end

-- 释放所有特效
function EffectContext:release_all_effects()
    if #self.effect_instances == 0 then
        return
    end

    for _, instance in ipairs(self.effect_instances) do
        if instance then
            pcall(function()
                instance:finishAll()
                instance:force_release()
            end)
        end
    end

    self.effect_instances = {}
end

-- 注册命中特效
function EffectContext:register_hit_effect(hit_table, frame, is_multi_hit)
    if not hit_table then
        return
    end

    self.hit_cache = {
        hit_table = hit_table,
        frame = frame,
        is_multi_hit = is_multi_hit or false
    }
end

-- 注册命中触发的规则（新增）
function EffectContext:register_hit_trigger_rule(rule, min_frame)
    if not self.hit_trigger_cache then
        self.hit_trigger_cache = {}
    end

    table.insert(self.hit_trigger_cache, {
        rule = rule,
        min_frame = min_frame or 0,  -- 最小触发帧（从 frame 字段获取）
        triggered = false
    })
end

-- 清除命中触发缓存
function EffectContext:clear_hit_trigger_cache()
    self.hit_trigger_cache = {}
end

-- 注册循环动作规则（只有 loop_action=true 的规则才会调用此方法）
function EffectContext:register_loop_action_rule(motion_id, rule_index)
    -- 惰性初始化
    if not self.loop_action_triggers then
        self.loop_action_triggers = {}
    end
    if not self.loop_action_triggers[motion_id] then
        self.loop_action_triggers[motion_id] = {}
    end
    self.loop_action_triggers[motion_id][rule_index] = true
end

-- 检测帧数回绕并重置循环动作规则的触发状态
-- 只有存在 loop_action 规则时才会有实际开销
function EffectContext:check_loop_action_reset(current_frame)
    -- 没有 loop_action 规则，直接返回（零开销）
    if not self.loop_action_triggers then
        self.last_frame = current_frame
        return
    end

    -- 检测帧数回绕（当前帧小于上一帧，说明动作循环了）
    if current_frame < self.last_frame then
        -- 只重置 loop_action 规则的触发状态
        for motion_id, rules in pairs(self.loop_action_triggers) do
            local motion_table = self.triggered_effects[motion_id]
            if motion_table then
                for rule_index, _ in pairs(rules) do
                    motion_table[rule_index] = nil
                end
            end
        end
    end

    self.last_frame = current_frame
end

-- 全局特效上下文实例
local effect_context = EffectContext.new()

-- ============================================================================
-- 攻击判定特效管理器 - 管理基于攻击判定的特效
-- ============================================================================

local AttackActiveEffectManager = {}
AttackActiveEffectManager.__index = AttackActiveEffectManager

function AttackActiveEffectManager.new()
    local self = setmetatable({}, AttackActiveEffectManager)

    -- 活跃的攻击判定特效
    -- key: attack_work实例的内存地址
    -- value: { effect_instances = {}, weapon_type = number }
    self.active_attack_effects = {}
    self.timed_attack_effects = {}
    self.tails = {}
    self.update_serial = 0

    return self
end

-- 查找匹配的攻击判定特效规则
---@param weapon_type number 武器类型
---@return table|nil 特效规则列表
function AttackActiveEffectManager:find_attack_active_rules(weapon_type)
    -- 使用pairs支持字典结构
    for table_id, sub_effect_table in pairs(effects.effectTable) do
        if sub_effect_table[weapon_type] then
            local weapon_table = sub_effect_table[weapon_type]
            if weapon_table[effects.on_action_status.AttackActive] then
                return weapon_table[effects.on_action_status.AttackActive], table_id
            end
        end
    end
    return nil
end

-- 检查规则是否满足条件（使用现有的条件检查器）
---@param rule table 特效规则
---@param current_frame number 当前帧数
---@return boolean 是否满足条件
function AttackActiveEffectManager:check_rule_conditions(rule, current_frame, context)
    context = context or core
    -- 1. 检查特殊条件
    if rule.specialCondition then
        local success, result = pcall(rule.specialCondition)
        if not success or result ~= true then
            return false
        end
    end

    -- 2. 检查节点ID（支持单个值或表格）
    local currentNodeId = rule.currentNodeId or rule.nodeID
    if currentNodeId ~= nil then
        if type(currentNodeId) == "table" then
            local matched = false
            for _, node_id in ipairs(currentNodeId) do
                if node_id == context._current_node then
                    matched = true
                    break
                end
            end
            if not matched then
                return false
            end
        else
            if context._current_node ~= currentNodeId then
                return false
            end
        end
    end

    -- 3. 检查前序动作（支持单个值或表格）
    local preActionId = rule.preActionId or rule.lastMotion
    if preActionId ~= nil then
        if type(preActionId) == "table" then
            local matched = false
            for _, action_id in ipairs(preActionId) do
                if action_id == context._pre_action_id then
                    matched = true
                    break
                end
            end
            if not matched then
                return false
            end
        else
            if preActionId ~= context._pre_action_id then
                return false
            end
        end
    end

    -- 4. 检查当前动作ID（新增：可选过滤特定动作）
    local actionId = rule.actionId
    if actionId ~= nil then
        if type(actionId) == "table" then
            local matched = false
            for _, act_id in ipairs(actionId) do
                if act_id == context._action_id then
                    matched = true
                    break
                end
            end
            if not matched then
                return false
            end
        else
            if actionId ~= context._action_id then
                return false
            end
        end
    end

    -- 5. 检查帧数范围（可选）
    if rule.frame ~= nil then
        local frame = rule.frame
        if type(frame) == "table" then
            if current_frame < (frame[1] + 0.0) or current_frame > (frame[2] + 0.0) then  -- 转换为浮点数
                return false
            end
        else
            if current_frame < (frame + 0.0) then  -- 转换为浮点数
                return false
            end
        end
    end

    return true
end

local function attack_offset(rule, name)
    local value = rule[name]
    if value == nil then return 0 end
    assert(type(value) == "number" and value == value and math.abs(value) < math.huge,
        "AttackActive." .. name .. " must be a finite number")
    return value
end

local function has_attack_offset(rule)
    return attack_offset(rule, "startOffset") ~= 0 or attack_offset(rule, "endOffset") ~= 0
end

local function play_attack_effect(rule)
    local instance
    if rule.vfx and type(rule.vfx) == "table" and #rule.vfx >= 2 then
        if rule.force_release ~= false then
            instance = effects.set_effect_with_instance(rule.vfx[1], rule.vfx[2])
        else
            effects.set_effect(rule.vfx[1], rule.vfx[2])
        end
    end
    if rule.camera_vibration then
        local index = rule.camera_vibration.index or rule.camera_vibration[1]
        local priority = rule.camera_vibration.priority or rule.camera_vibration[2] or 0
        if index then effects.set_camera_vibration(index, priority) end
    end
    if rule.pad_vibration then
        local id = rule.pad_vibration.id or rule.pad_vibration[1]
        local is_loop = rule.pad_vibration.is_loop or rule.pad_vibration[2] or false
        if id then effects.set_pad_vibration(id, is_loop) end
    end
    return instance
end

local function finish_attack_effect(entry)
    if entry.instance then
        entry.instance:finishAll()
        entry.instance:force_release()
        entry.instance = nil
    end
    entry.finished = true
end

local function clear_timed_attack(record)
    for _, entry in ipairs(record.entries) do finish_attack_effect(entry) end
end

local function attack_end_frame(work)
    if (work:get_HitData():get_HitAttr() & 0x100) ~= 0 then return nil end
    local frame = work:get_TotalFrame()
    if frame >= 0 then return frame end
end

function AttackActiveEffectManager:on_attack_initialize(work)
    local id = work:get_address()
    local previous = self.timed_attack_effects[id]
    if previous then clear_timed_attack(previous) end
    self.timed_attack_effects[id] = nil
    local rules, table_id = self:find_attack_active_rules(core._wep_type)
    if not rules then return end

    local entries = {}
    for _, rule in ipairs(rules) do
        if has_attack_offset(rule) then
            entries[#entries + 1] = {
                rule = rule,
                start_offset = attack_offset(rule, "startOffset"),
                end_offset = attack_offset(rule, "endOffset"),
            }
        end
    end
    if #entries == 0 then return end
    local owner = core.master_player
    local layer = owner:getMotionLayer(0)
    self.timed_attack_effects[id] = {
        work = work, owner = owner, entries = entries, table_id = table_id,
        weapon_type = core._wep_type,
        start_frame = work:get_StartDelay(),
        layer_index = work:get_RefMotionLayerIndex(),
        motion_id = layer:get_MotionID(), bank_id = layer:get_MotionBankID(),
    }
end

-- 条件读当前动画层，避免判定先于 PlayerMotionControl.lateUpdate 时读到上一招。
function AttackActiveEffectManager:update_timed_attack(record, timer, end_frame, activated)
    if record.owner ~= core.master_player or core.is_loading_visiable
        or record.weapon_type ~= core._wep_type or not effects.effectTable[record.table_id] then
        clear_timed_attack(record)
        return false
    end
    local layer = record.owner:getMotionLayer(0)
    local frame = layer:get_Frame()
    -- initialize 时动作 ID 已更新，但帧数可能尚未从上一招重置；在首次判定更新建立基准。
    if layer:get_MotionID() ~= record.motion_id or layer:get_MotionBankID() ~= record.bank_id
        or (record.last_frame and frame < record.last_frame) then
        clear_timed_attack(record)
        return false
    end
    record.last_frame = frame
    local pending = false
    for _, entry in ipairs(record.entries) do
        if not entry.finished then
            local stop = end_frame and end_frame + entry.end_offset
            if stop and timer >= stop then
                finish_attack_effect(entry)
            elseif not entry.started and ((entry.start_offset == 0 and activated)
                or (entry.start_offset ~= 0 and timer >= math.max(0, record.start_frame + entry.start_offset))) then
                entry.started = true
                local context = {
                    _action_id = layer:get_MotionID(),
                    _pre_action_id = layer:get_PrevMotionID(),
                    _current_node = core.mPlBHVT and core.mPlBHVT:getCurrentNodeID(0),
                }
                if self:check_rule_conditions(entry.rule, frame, context) then
                    entry.instance = play_attack_effect(entry.rule)
                else
                    entry.finished = true
                end
            end
            pending = pending or not entry.finished
        end
    end
    return pending
end

function AttackActiveEffectManager:update_timed_attacks(rsc)
    -- 尾段脱离 AttackWork，地址被下一段判定复用也不会覆盖已有特效。
    for i = #self.tails, 1, -1 do
        local record = self.tails[i]
        if record.destroy_serial ~= self.update_serial then
            if record.layer_index >= 0 then
                local frame = record.owner:getMotionLayer(record.layer_index):get_Frame()
                if frame < record.tail_frame then
                    clear_timed_attack(record)
                    table.remove(self.tails, i)
                    goto continue_tail
                end
                record.timer = record.timer + frame - record.tail_frame
                record.tail_frame = frame
            else
                local motion = rsc:get_Motion()
                if motion:get_PlayState() == 0 then
                    record.timer = record.timer + rsc:get_DeltaTime() * motion:get_PlaySpeed() * motion:get_SecondaryPlaySpeed()
                end
            end
        end
        if not self:update_timed_attack(record, record.timer, record.end_frame, false) then
            table.remove(self.tails, i)
        end
        ::continue_tail::
    end
    for id, record in pairs(self.timed_attack_effects) do
        if not self:update_timed_attack(record, record.work:get_Timer(), attack_end_frame(record.work), false) then
            self.timed_attack_effects[id] = nil
        end
    end
end

function AttackActiveEffectManager:destroy_timed_attack(work)
    local id = work:get_address()
    local record = self.timed_attack_effects[id]
    if not record then return end
    self.timed_attack_effects[id] = nil
    local timer = work:get_Timer()
    local end_frame = attack_end_frame(work)
    if end_frame and timer < end_frame then
        clear_timed_attack(record)
        return
    end
    for _, entry in ipairs(record.entries) do
        if entry.end_offset <= 0 then finish_attack_effect(entry) end
    end
    record.end_frame = end_frame or timer
    record.timer = timer
    record.work = nil
    record.destroy_serial = self.update_serial
    if record.layer_index >= 0 then
        record.tail_frame = record.owner:getMotionLayer(record.layer_index):get_Frame()
    end
    if self:update_timed_attack(record, timer, record.end_frame, false) then
        self.tails[#self.tails + 1] = record
    end
end

-- 攻击判定激活时触发特效（首次activate调用时触发）
---@param attack_work userdata AttackWork实例
---@param weapon_type number 武器类型
function AttackActiveEffectManager:on_attack_activate(attack_work, weapon_type)
    if not attack_work or not core.master_player then
        return
    end

    -- 获取attack_work的唯一标识（内存地址）
    local attack_work_id = attack_work:get_address()

    -- 如果已经存在，跳过（防止重复触发）
    if self.active_attack_effects[attack_work_id] then
        return
    end

    local rules = self:find_attack_active_rules(weapon_type)
    if not rules then return end

    -- 获取当前帧数
    local current_frame = math.floor(core._action_frame or 0)

    -- 创建特效实例存储
    local effect_data = {
        effect_instances = {},
        weapon_type = weapon_type
    }

    -- 遍历规则，生成特效
    for rule_index, rule in ipairs(rules) do
        if has_attack_offset(rule) then goto continue end
        -- 使用条件检查器检查所有条件
        if not self:check_rule_conditions(rule, current_frame) then
            goto continue
        end

        local instance = play_attack_effect(rule)
        if instance then
            table.insert(effect_data.effect_instances, { instance = instance, rule_index = rule_index })
        end

        ::continue::
    end

    -- 始终存储记录（用于标记已处理，防止activate持续调用时重复触发）
    self.active_attack_effects[attack_work_id] = effect_data
end

-- 攻击判定结束时回收特效
---@param attack_work userdata AttackWork实例
function AttackActiveEffectManager:on_attack_destroy(attack_work)
    if not attack_work then
        return
    end

    -- 获取attack_work的唯一标识
    local attack_work_id = attack_work:get_address()

    -- 查找并回收特效
    local effect_data = self.active_attack_effects[attack_work_id]
    if effect_data then
        -- 回收所有特效实例
        for _, effect_info in ipairs(effect_data.effect_instances) do
            local instance = effect_info.instance
            if instance then
                pcall(function()
                    instance:finishAll()
                    instance:force_release()
                end)
            end
        end

        -- 移除记录
        self.active_attack_effects[attack_work_id] = nil
    end
end

-- 清除所有攻击判定特效（动作改变或任务状态改变时调用）
function AttackActiveEffectManager:clear_all()
    for _, effect_data in pairs(self.active_attack_effects) do
        for _, effect_info in ipairs(effect_data.effect_instances) do
            local instance = effect_info.instance
            if instance then
                pcall(function()
                    instance:finishAll()
                    instance:force_release()
                end)
            end
        end
    end
    self.active_attack_effects = {}
    for _, record in pairs(self.timed_attack_effects) do clear_timed_attack(record) end
    for _, record in ipairs(self.tails) do clear_timed_attack(record) end
    self.timed_attack_effects = {}
    self.tails = {}
end

-- 全局攻击判定特效管理器实例
local attack_active_effect_manager = AttackActiveEffectManager.new()

function effects.clear_attack_effects()
    attack_active_effect_manager:clear_all()
end

function effects.update_attack_effect_lifecycle()
    if attack_active_effect_manager.owner ~= core.master_player or core.is_loading_visiable then
        effects.clear_attack_effects()
        attack_active_effect_manager.owner = core.master_player
    end
end

-- ============================================================================
-- 相机效果管理器 - 管理持续的相机效果（FOV、偏移、径向模糊等）
-- ============================================================================

local CameraEffectManager = {}
CameraEffectManager.__index = CameraEffectManager

function CameraEffectManager.new()
    local self = setmetatable({}, CameraEffectManager)

    -- 活跃的相机效果列表
    self.active_effects = {}

    -- 当前径向模糊值（用于钩子）
    self.current_radial_blur = nil

    -- 复用的Vector3f对象（优化：避免每帧创建新对象）
    self.reused_vector = Vector3f.new(0, 0, 0)

    -- 计算结果缓存（在update_logic中计算，在apply_to_camera中应用）
    self.computed_fov_offset = 0
    self.computed_distance_offset = 0
    self.computed_radial_blur = 0

    return self
end

-- 检查是否暂停
function CameraEffectManager:is_paused()
    return core.TimeScaleManager and core.TimeScaleManager:get__Pausing()
end

-- 注册一个新的相机效果
---@param motion_id number 动作ID
---@param rule_index number 规则索引
---@param camera_effect table 相机效果配置
---@param start_frame number 开始帧
function CameraEffectManager:register_effect(motion_id, rule_index, camera_effect, start_frame)
    local effect_id = tostring(motion_id) .. "_" .. tostring(rule_index)

    -- 如果已存在，不重复注册
    if self.active_effects[effect_id] then
        return
    end

    local current_time = utils.get_game_time()

    self.active_effects[effect_id] = {
        config = camera_effect,
        start_time = current_time,
        start_frame = start_frame,

        -- FOV偏移量（相对于初始值的偏移）
        fov_current_offset = 0,
        fov_peak_offset = nil,  -- 峰值偏移（forward阶段结束时的值）

        -- 距离偏移相关
        distance_offset_start = 0,
        distance_offset_current = 0,
        distance_offset_peak = 0,

        -- 径向模糊相关
        radial_blur_start = 0,
        radial_blur_current = 0,
        radial_blur_peak = 0,

        -- 阶段控制
        phase = "forward",  -- "forward" 或 "reverse"（默认总是有reverse阶段）
        reverse_start_time = nil,  -- reverse阶段开始时间
    }
end

-- 获取相机joint
function CameraEffectManager:get_camera_joint()
    local camera = sdk.get_primary_camera()
    if not camera then return nil end

    local camera_gameobject = camera:get_GameObject()
    if not camera_gameobject then return nil end

    local camera_transform = camera_gameobject:get_Transform()
    if not camera_transform then return nil end

    return camera_transform:get_Joints():get_elements()[1]
end

-- 更新逻辑：计算所有效果的偏移量（在UpdateScene中调用）
function CameraEffectManager:update_logic()
    -- 如果暂停，跳过更新
    if self:is_paused() then
        return
    end

    local current_time = utils.get_game_time()
    local current_frame = core._action_frame or 0

    -- 累积效果值
    local total_fov_offset = 0
    local total_distance_offset = 0
    local total_radial_blur = 0

    -- 遍历并更新所有活跃效果
    local effects_to_remove = {}

    for effect_id, effect in pairs(self.active_effects) do
        local config = effect.config

        -- ===== Forward 阶段 =====
        if effect.phase == "forward" then
            local elapsed_time = current_time - effect.start_time
            local duration = (config.duration or 1.0) + 0.0  -- 转换为浮点数
            local progress = clamp01(elapsed_time / duration)

            -- 获取缓动函数
            local easing_func = Easing.get(config.easing or "ease_out")

            -- 计算FOV偏移（从0到目标偏移量）
            if config.fov_offset then
                local current_offset = easing_func(progress, 0, config.fov_offset)
                effect.fov_current_offset = current_offset
                total_fov_offset = total_fov_offset + current_offset
            end

            -- 计算距离偏移
            if config.distance_offset then
                local target_distance = config.distance_offset
                effect.distance_offset_current = easing_func(progress, 0, target_distance)
                total_distance_offset = total_distance_offset + effect.distance_offset_current
            end

            -- 计算径向模糊
            if config.radial_blur then
                local target_blur = config.radial_blur
                effect.radial_blur_current = easing_func(progress, 0, target_blur)
                total_radial_blur = total_radial_blur + effect.radial_blur_current
            end

            -- 检查是否完成 forward 阶段
            if progress >= 1.0 then
                -- 记录峰值偏移量（forward 结束时的值）
                effect.fov_peak_offset = config.fov_offset
                effect.distance_offset_peak = effect.distance_offset_current
                effect.radial_blur_peak = effect.radial_blur_current

                -- 可选保持阶段：在进入 reverse 之前保持效果不变
                local keep_duration = (config.keep_duration or 0) + 0.0  -- 转换为浮点数
                if keep_duration > 0 then
                    effect.phase = "keep"
                    effect.keep_start_time = current_time
                else
                    effect.phase = "reverse"
                    effect.reverse_start_time = current_time
                end
            end

        -- ===== Keep 阶段（可选）=====
        elseif effect.phase == "keep" then
            local keep_duration = (config.keep_duration or 0) + 0.0  -- 转换为浮点数
            local elapsed_time = current_time - (effect.keep_start_time or current_time)

            -- 在保持阶段使用 forward 结束时的峰值
            if config.fov_offset then
                local current_offset = effect.fov_peak_offset or config.fov_offset
                effect.fov_current_offset = current_offset
                total_fov_offset = total_fov_offset + current_offset
            end

            if config.distance_offset then
                effect.distance_offset_current = effect.distance_offset_peak or effect.distance_offset_current
                total_distance_offset = total_distance_offset + effect.distance_offset_current
            end

            if config.radial_blur then
                effect.radial_blur_current = effect.radial_blur_peak or effect.radial_blur_current
                total_radial_blur = total_radial_blur + effect.radial_blur_current
            end

            -- 保持时间结束后，进入 reverse 阶段
            if keep_duration <= 0 or elapsed_time >= keep_duration then
                effect.phase = "reverse"
                effect.reverse_start_time = current_time
            end

        -- ===== Reverse 阶段 =====
        elseif effect.phase == "reverse" then
            local elapsed_time = current_time - effect.reverse_start_time
            local duration = (config.reverse_duration or config.duration or 1.0) + 0.0  -- 转换为浮点数
            local progress = clamp01(elapsed_time / duration)

            -- 获取reverse缓动函数
            local easing_func = Easing.get(config.reverse_easing or "ease_in")

            -- 从峰值偏移恢复到0偏移
            if config.fov_offset then
                local current_offset = easing_func(progress, effect.fov_peak_offset or config.fov_offset, 0)
                effect.fov_current_offset = current_offset
                total_fov_offset = total_fov_offset + current_offset
            end

            if config.distance_offset then
                effect.distance_offset_current = easing_func(progress, effect.distance_offset_peak, 0)
                total_distance_offset = total_distance_offset + effect.distance_offset_current
            end

            -- 径向模糊在reverse阶段使用固定0.5秒淡出
            if config.radial_blur then
                local blur_fade_duration = 0.5
                local blur_progress = clamp01(elapsed_time / blur_fade_duration)
                local blur_easing_func = Easing.get("ease_in")
                effect.radial_blur_current = blur_easing_func(blur_progress, effect.radial_blur_peak, 0)
                total_radial_blur = total_radial_blur + effect.radial_blur_current
            end

            -- 检查是否完成reverse阶段
            if progress >= 1.0 then
                table.insert(effects_to_remove, effect_id)
            end

        end
    end

    -- 移除已完成的效果
    for _, effect_id in ipairs(effects_to_remove) do
        self.active_effects[effect_id] = nil
    end

    -- 保存计算结果（将在 apply_to_camera 中应用）
    self.computed_fov_offset = total_fov_offset
    self.computed_distance_offset = total_distance_offset
    self.computed_radial_blur = total_radial_blur

    -- 径向模糊通过钩子处理
    self.current_radial_blur = total_radial_blur > 0 and total_radial_blur or nil
end

-- 应用到相机：将计算好的偏移量应用到相机（在BeginRendering中调用）
function CameraEffectManager:apply_to_camera()
    local camera = sdk.get_primary_camera()
    if not camera then
        return
    end

    -- 每帧都应用FOV偏移（游戏每帧都会重置FOV到基础值）
    if self.computed_fov_offset ~= 0 then
        local current_fov = camera:get_FOV()
        camera:set_FOV(current_fov + self.computed_fov_offset)
    end

    -- 应用距离偏移
    if self.computed_distance_offset ~= 0 then
        local camera_joint = self:get_camera_joint()
        if camera_joint then
            local cam_pos = camera_joint:get_LocalPosition()
            -- 复用Vector3f对象，避免每帧创建新对象
            self.reused_vector.x = cam_pos.x
            self.reused_vector.y = cam_pos.y
            self.reused_vector.z = cam_pos.z - self.computed_distance_offset
            camera_joint:set_LocalPosition(self.reused_vector)
        end
    end
end

-- 清除所有效果
function CameraEffectManager:clear_all()
    self.active_effects = {}
    -- FOV无需手动恢复，游戏每帧都会重置到基础值
    self.current_radial_blur = nil
end

-- 全局相机效果管理器实例（使用前置声明，避免循环依赖）
camera_effect_manager = CameraEffectManager.new()

-- ============================================================================
-- 条件检查器 - 封装各种特效触发条件检查逻辑
-- ============================================================================

local ConditionChecker = {}

-- 检查特殊条件
---@param rule table 特效规则
---@return boolean 是否满足特殊条件
function ConditionChecker.check_special_condition(rule)
    local condition = rule.specialCondition
    if type(condition) == "function" then
        local success, result = pcall(condition)
        if not success then
            -- 条件函数执行出错，记录错误
            return false
        end
        return result == true
    end
    -- 没有特殊条件时默认通过
    return condition ~= false
end

-- 检查节点ID
---@param rule table 特效规则
---@return boolean 是否满足条件
function ConditionChecker.check_node_id(rule)
    -- 兼容旧字段名 nodeID
    local currentNodeId = rule.currentNodeId or rule.nodeID
    if currentNodeId == nil then
        return true  -- 没有节点限制
    end

    -- 支持表格形式：匹配任意一个节点
    if type(currentNodeId) == "table" then
        for _, node_id in ipairs(currentNodeId) do
            if node_id == core._current_node then
                return true
            end
        end
        return false
    end

    -- 单个值形式：精确匹配
    return core._current_node == currentNodeId
end

-- 检查前序动作
---@param rule table 特效规则
---@param context table 特效上下文
---@return boolean 是否满足条件
function ConditionChecker.check_motion_history(rule, context)
    -- 兼容旧字段名 lastMotion
    local preActionId = rule.preActionId or rule.lastMotion
    if preActionId == nil then
        return true
    end

    -- 支持表格形式：匹配任意一个前序动作
    if type(preActionId) == "table" then
        for _, action_id in ipairs(preActionId) do
            if action_id == context.last_motion then
                return true
            end
        end
        return false
    end

    -- 单个值形式：精确匹配
    return preActionId == context.last_motion
end

-- 检查帧数范围
---@param rule table 特效规则
---@param current_frame number 当前帧数
---@return boolean 是否满足条件
function ConditionChecker.check_frame(rule, current_frame)
    local frame = rule.frame

    -- 没有帧数限制，默认帧0触发
    if frame == nil then
        return current_frame >= 0
    end

    -- 帧数范围 {start, end}
    if type(frame) == "table" then
        return current_frame >= (frame[1] + 0.0) and current_frame <= (frame[2] + 0.0)  -- 转换为浮点数
    end

    -- 单一帧数
    return current_frame >= (frame + 0.0)  -- 转换为浮点数
end

-- 检查所有前置条件
---@param rule table 特效规则
---@param context table 特效上下文
---@param current_frame number 当前帧数
---@return boolean 是否满足所有条件
function ConditionChecker.check_all_conditions(rule, context, current_frame)
    -- 1. 检查特殊条件（武器特定条件）
    if not ConditionChecker.check_special_condition(rule) then
        return false
    end

    -- 2. 检查节点ID
    if not ConditionChecker.check_node_id(rule) then
        return false
    end

    -- 3. 检查动作历史
    if not ConditionChecker.check_motion_history(rule, context) then
        return false
    end

    -- 4. 检查帧数
    if not ConditionChecker.check_frame(rule, current_frame) then
        return false
    end

    return true
end

-- ============================================================================
-- 特效执行器 - 封装特效执行的所有操作
-- ============================================================================

local EffectExecutor = {}

-- 在玩家位置生成特效（内部使用，调用公开 API 以获得同步）
---@param container number 容器ID
---@param effect number 特效ID
---@param force_release boolean 是否需要强制释放
---@param context table 特效上下文
function EffectExecutor.set_effect(container, effect, force_release, context)
    if not core.master_player then return end
    if not effects.is_effect_exists(container, effect) then return end

    if force_release then
        -- 需要强制释放的特效，使用公开 API 获取实例
        local instance = effects.set_effect_with_instance(container, effect)
        if instance then
            context:register_effect_instance(instance)
        end
    else
        -- 普通特效，使用公开 API
        effects.set_effect(container, effect)
    end
end

-- 在命中位置生成特效
---@param hit_position userdata 命中位置
---@param container number 容器ID
---@param effect number 特效ID
function EffectExecutor.set_hit_effect(hit_position, container, effect)
    if not effects.set_effect_at_position(container, effect, hit_position) then return end

    -- 同步给队友（使用内部函数直接发送）
    send_effect_sync_packet(container, effect)
end

-- 执行特效规则
---@param rule table 特效规则
---@param context table 特效上下文
---@param motion_id number 动作ID
---@param rule_index number 规则索引
function EffectExecutor.execute(rule, context, motion_id, rule_index)
    -- 检查是否需要等待命中触发
    local hit_trigger = rule.hitTrigger

    -- 1. 生成视觉特效（不受 hitTrigger 影响）
    local vfx = rule.vfx
    if vfx and type(vfx) == "table" and #vfx >= 2 then
        local force_release = rule.force_release or false
        EffectExecutor.set_effect(vfx[1], vfx[2], force_release, context)
    end

    -- 2. 注册命中特效（不受 hitTrigger 影响，保持原有行为）
    local hit = rule.hit
    if hit and type(hit) == "table" then
        local frame = rule.frame
        local is_multi_hit = rule.isMultiHit or false
        context:register_hit_effect(hit, frame, is_multi_hit)
    end

    -- 3. 如果开启了 hitTrigger，注册到命中触发缓存，不立即执行
    if hit_trigger then
        local min_frame = (type(rule.frame) == "table" and rule.frame[1] or (rule.frame or 0)) + 0.0  -- 转换为浮点数
        context:register_hit_trigger_rule(rule, min_frame)
        return  -- 不继续执行下面的效果，等待命中后再触发
    end

    -- 4. 注册相机效果（立即执行，除非 hitTrigger=true）
    local camera_effect = rule.cameraEffect
    if camera_effect then
        local start_frame = (type(rule.frame) == "table" and rule.frame[1] or (rule.frame or 0)) + 0.0  -- 转换为浮点数
        camera_effect_manager:register_effect(motion_id, rule_index, camera_effect, start_frame)
    end

    -- 5. 触发相机震动（立即执行，除非 hitTrigger=true）
    local camera_vibration = rule.camera_vibration
    if camera_vibration then
        local index = camera_vibration.index or camera_vibration[1]
        local priority = camera_vibration.priority or camera_vibration[2] or 0
        if index then
            effects.set_camera_vibration(index, priority)
        end
    end

    -- 6. 触发手柄震动（立即执行，除非 hitTrigger=true）
    local pad_vibration = rule.pad_vibration
    if pad_vibration then
        local id = pad_vibration.id or pad_vibration[1]
        local is_loop = pad_vibration.is_loop or pad_vibration[2] or false
        if id then
            effects.set_pad_vibration(id, is_loop)
        end
    end
end

-- ============================================================================
-- 特效规则处理器 - 静态函数，零对象创建开销
-- ============================================================================

local EffectRuleProcessor = {}

-- 处理特效规则（每帧调用）- 静态函数版本
---@param rule table 特效规则
---@param context table 特效上下文
---@param motion_id number 动作ID
---@param rule_index number 规则索引
---@param current_frame number 当前帧数
---@return boolean 是否成功执行特效
function EffectRuleProcessor.process(rule, context, motion_id, rule_index, current_frame)
    -- 1. 检查是否已经触发过
    if context:is_effect_triggered(motion_id, rule_index) then
        return false
    end

    -- 2. 检查所有前置条件
    if not ConditionChecker.check_all_conditions(rule, context, current_frame) then
        return false
    end

    -- 3. 执行特效
    EffectExecutor.execute(rule, context, motion_id, rule_index)

    -- 4. 标记为已触发
    context:mark_effect_triggered(motion_id, rule_index)

    -- 5. 如果是循环动作规则，注册以便帧数回绕时重置
    if rule.loop_action then
        context:register_loop_action_rule(motion_id, rule_index)
    end

    return true
end

-- ============================================================================
-- 特效状态机 - 主状态机，协调所有特效规则处理
-- ============================================================================

local EffectStateMachine = {}
EffectStateMachine.__index = EffectStateMachine

-- 创建特效状态机
---@param effect_table table 特效表
---@param context table 特效上下文
---@return table 特效状态机实例
function EffectStateMachine.new(effect_table, context)
    local self = setmetatable({}, EffectStateMachine)
    self.effect_table = effect_table
    self.context = context
    return self
end

-- 查找匹配的特效规则列表
---@param sub_effect_table table 子特效表
---@param weapon_type number 武器类型
---@param motion_id number 动作ID
---@return table|nil 特效规则列表
function EffectStateMachine:find_effect_rules(sub_effect_table, weapon_type, motion_id)
    -- 检查武器类型是否存在
    if sub_effect_table[weapon_type] == nil then
        return nil
    end

    local weapon_table = sub_effect_table[weapon_type]

    -- 检查动作ID是否存在
    if weapon_table[motion_id] == nil then
        return nil
    end

    return weapon_table[motion_id]
end

-- 处理单个特效表
---@param sub_effect_table table 子特效表
---@param weapon_type number 武器类型
---@param motion_id number 动作ID
---@param motion_bank number 动作库ID
---@param current_frame number 当前帧数
function EffectStateMachine:process_effect_table(sub_effect_table, weapon_type, motion_id, motion_bank, current_frame)
    -- 只处理主武器库（bank 100）
    if motion_bank ~= 100 then
        return
    end

    -- 查找匹配的特效规则
    local rules = self:find_effect_rules(sub_effect_table, weapon_type, motion_id)
    if not rules then
        return
    end

    -- 遍历所有规则（直接调用静态函数，零对象创建开销）
    for index, rule in ipairs(rules) do
        EffectRuleProcessor.process(rule, self.context, motion_id, index, current_frame)
    end
end

-- 更新状态机（每帧调用）
---@param weapon_type number 武器类型
---@param motion_id number 动作ID
---@param motion_bank number 动作库ID
---@param current_frame number 当前帧数
function EffectStateMachine:update(weapon_type, motion_id, motion_bank, current_frame)
    -- 遍历所有特效表（使用pairs支持字典结构）
    for _, sub_effect_table in pairs(self.effect_table) do
        self:process_effect_table(sub_effect_table, weapon_type, motion_id, motion_bank, current_frame)
    end
end

-- ============================================================================
-- 全局状态机实例和更新函数
-- ============================================================================

-- 全局状态机实例
local effect_state_machine = nil

-- 初始化状态机
local function init_state_machine()
    if not effect_state_machine then
        effect_state_machine = EffectStateMachine.new(effects.effectTable, effect_context)
    end
end

-- 特效包装函数
local function effect_wrapper()
    init_state_machine()

    if not core.master_player then
        return
    end

    -- 直接使用 core 维护的动作信息（由 hooks.lua 自动更新）
    local weapon_type = core._wep_type
    local motion_id = core._action_id
    local motion_bank = core._action_bank_id
    local current_frame = math.floor(core._action_frame or 0)

    -- 更新动作历史
    effect_context:update_motion_history(motion_id, motion_bank)

    -- 检测循环动作的帧数回绕（只有存在 loop_action 规则时才有开销）
    effect_context:check_loop_action_reset(current_frame)

    -- 更新状态机
    effect_state_machine:update(weapon_type, motion_id, motion_bank, current_frame)
end

-- 主更新函数（在UpdateScene中调用）
function effects.update()
    -- 更新视觉特效状态机（VFX、命中特效等）
    effect_wrapper()

    -- 更新相机效果逻辑（计算偏移量，不应用到相机）
    camera_effect_manager:update_logic()
end

-- ============================================================================
-- 命中特效处理钩子
-- ============================================================================

-- 在敌人受伤时触发命中特效
function effects.on_enemy_damage(dmg_info, hit_pos, player_index, weapon_type)
    -- 检查攻击者是否是主玩家
    if dmg_info:get_AttackerID() ~= player_index then
        return
    end

    -- 检查武器类型是否匹配
    if dmg_info:get_WeaponType() ~= weapon_type then
        return
    end

    local current_frame = math.floor(core._action_frame or 0)

    -- ===== 1. 处理命中特效（VFX） =====
    local cache = effect_context.hit_cache
    if cache.hit_table then
        -- 检查帧数范围
        if type(cache.frame) == "table" then
            if current_frame > (cache.frame[2] + 0.0) then  -- 转换为浮点数
                -- 超出范围，跳过命中特效
                goto skip_hit_vfx
            end
        end

        -- 增加命中计数
        effect_context.hit_count = effect_context.hit_count + 1

        -- 生成命中特效
        local hit_table = cache.hit_table
        if type(hit_table[1]) == "table" then
            -- 多段命中，使用对应索引的特效
            local index = math.min(effect_context.hit_count, #hit_table)
            EffectExecutor.set_hit_effect(hit_pos, hit_table[index][1], hit_table[index][2])
        else
            -- 单次命中
            EffectExecutor.set_hit_effect(hit_pos, hit_table[1], hit_table[2])
        end

        -- 如果不是多段命中，清除缓存
        if not cache.is_multi_hit then
            effect_context.hit_cache = {}
            effect_context.hit_count = 0
        end
    end

    ::skip_hit_vfx::

    -- ===== 2. 处理命中触发规则（hitTrigger） =====
    if not effect_context.hit_trigger_cache then
        return
    end

    for _, trigger_data in ipairs(effect_context.hit_trigger_cache) do
        -- 检查是否已经触发过
        if trigger_data.triggered then
            goto continue
        end

        -- 检查帧数是否满足最小要求
        if current_frame < trigger_data.min_frame then
            goto continue
        end

        local rule = trigger_data.rule

        -- 触发相机效果
        if rule.cameraEffect then
            -- 使用特殊ID注册（使用负数避免与正常特效冲突）
            local motion_id = core._action_id or 0
            local unique_id = -1000000 - current_frame  -- 使用负数ID标识命中触发
            camera_effect_manager:register_effect(motion_id, unique_id, rule.cameraEffect, current_frame)
        end

        -- 触发相机震动
        if rule.camera_vibration then
            local index = rule.camera_vibration.index or rule.camera_vibration[1]
            local priority = rule.camera_vibration.priority or rule.camera_vibration[2] or 0
            if index then
                effects.set_camera_vibration(index, priority)
            end
        end

        -- 触发手柄震动
        if rule.pad_vibration then
            local id = rule.pad_vibration.id or rule.pad_vibration[1]
            local is_loop = rule.pad_vibration.is_loop or rule.pad_vibration[2] or false
            if id then
                effects.set_pad_vibration(id, is_loop)
            end
        end

        -- 标记为已触发
        trigger_data.triggered = true

        ::continue::
    end
end

-- ============================================================================
-- 径向模糊处理（从钩子调用）
-- ============================================================================

-- 应用径向模糊
---@param is_org_blur_enabled boolean 游戏原本是否启用模糊
function effects.apply_radial_blur(is_org_blur_enabled)
    local current_blur = camera_effect_manager.current_radial_blur
    if not current_blur then
        return
    end

    -- 使用 core 维护的 GameCamera
    if not core.GameCamera then
        return
    end

    local post_effect = core.GameCamera:get_GameObject():getComponent(
        sdk.typeof("snow.SnowPostEffectParam"))
    if not post_effect then
        return
    end

    local ldr_post_process = post_effect:get_field("_SnowLDRPostProcess")
    if not ldr_post_process then
        return
    end

    local radial_blur_param = ldr_post_process:get_RadialBlur()
    if not radial_blur_param then
        return
    end

    -- 获取径向模糊组件
    local effect_helper = sdk.find_type_definition("via.effect.script.EffectHelper")
    if not effect_helper then
        return
    end

    local pt_behavior = effect_helper:get_method("get_ptBehavior"):call(nil)
    if not pt_behavior then
        return
    end

    local radial_blur_component = pt_behavior:getRadialBlurComponent()
    if not radial_blur_component then
        return
    end

    -- 如果游戏原本没有开启径向模糊，设置默认参数
    if not is_org_blur_enabled then
        local color = radial_blur_component:get_Color()
        color:set_r(255)
        color:set_g(255)
        color:set_b(255)
        color:set_a(255)
        radial_blur_component:set_Color(color)
        radial_blur_component:set_ColorRate(1.0)
        radial_blur_component:set_OccludeScale(1.0)
        radial_blur_component:set_OccludeSampleNum(16)
        radial_blur_component:setLookAtType(1)
    end

    -- 应用模糊强度和启用状态
    radial_blur_param:set_BlurPower(current_blur)
    radial_blur_param:set_Enabled(current_blur > 0)
end

-- ============================================================================
-- 渲染层回调 - 相机效果应用
-- ============================================================================

-- 在渲染前应用相机效果（每帧调用）
-- 注意：只应用已计算好的值，逻辑更新在UpdateScene中完成
---@diagnostic disable-next-line: undefined-global
re.on_pre_application_entry("BeginRendering", function()
    -- 应用已计算好的相机效果到相机
    camera_effect_manager:apply_to_camera()
end)

-- ============================================================================
-- 钩子处理函数 - 由hooks.lua调用
-- ============================================================================

-- 径向模糊原始启用状态
local is_org_blur_enabled = nil

-- 钩子：命中特效（敌人受伤时触发）
---@param args table 钩子参数
function effects.hook_pre_enemy_damage(args)
    if not core.master_player then return end

    local dmg_info = sdk.to_managed_object(args[3])
    local hit_pos = dmg_info:get_HitPos()
    local player_index = core.master_player_index
    local weapon_type = core._wep_type

    -- 调用特效系统的命中处理
    effects.on_enemy_damage(dmg_info, hit_pos, player_index, weapon_type)
end

-- 钩子：径向模糊 - 记录原始启用状态
---@param args table 钩子参数
function effects.hook_pre_radial_blur_enabled(args)
    is_org_blur_enabled = args[3]
end

-- 钩子：径向模糊 - 应用参数
function effects.hook_pre_radial_blur_apply()
    -- 调用特效系统处理径向模糊
    effects.apply_radial_blur(is_org_blur_enabled)
    is_org_blur_enabled = nil
end

-- 只处理主玩家自己的 RSC 判定。
local function master_attack_work(args)
    effects.update_attack_effect_lifecycle()
    if not core.master_player or core.is_loading_visiable then return nil end
    local work = sdk.to_managed_object(args[2])
    if work and work:get_RSCCtrl() == core.master_player:getRSCController() then return work end
end

function effects.hook_pre_attack_work_initialize(args)
    thread.get_hook_storage().attack_effect_work = master_attack_work(args)
end

function effects.hook_post_attack_work_initialize(retval)
    local work = thread.get_hook_storage().attack_effect_work
    if work then attack_active_effect_manager:on_attack_initialize(work) end
    return retval
end

function effects.hook_pre_update_attack_works(args)
    effects.update_attack_effect_lifecycle()
    local rsc = sdk.to_managed_object(args[2])
    local is_master = core.master_player and not core.is_loading_visiable
        and rsc == core.master_player:getRSCController()
    thread.get_hook_storage().attack_effect_rsc = is_master and rsc or nil
    if is_master then
        attack_active_effect_manager.update_serial = attack_active_effect_manager.update_serial + 1
    end
end

function effects.hook_post_update_attack_works(retval)
    local rsc = thread.get_hook_storage().attack_effect_rsc
    if rsc then attack_active_effect_manager:update_timed_attacks(rsc) end
    return retval
end

function effects.hook_pre_attack_work_activate(args)
    local work = master_attack_work(args)
    if not work then return end
    local id = work:get_address()
    local record = attack_active_effect_manager.timed_attack_effects[id]
    if record and not attack_active_effect_manager:update_timed_attack(record, work:get_Timer(), attack_end_frame(work), true) then
        attack_active_effect_manager.timed_attack_effects[id] = nil
    end
    attack_active_effect_manager:on_attack_activate(work, core._wep_type)
end

-- 钩子：攻击判定销毁（攻击判定结束时触发）
---@param args table 钩子参数
function effects.hook_pre_attack_work_destroy(args)
    local attack_work = master_attack_work(args)
    if not attack_work then return end

    -- 回收攻击判定特效
    attack_active_effect_manager:on_attack_destroy(attack_work)
    attack_active_effect_manager:destroy_timed_attack(attack_work)
end

-- ============================================================================
-- 直接调用接口
-- ============================================================================

-- 直接触发相机效果（立即生效，无需通过状态机）
---@param camera_effect table 相机效果配置
function effects.trigger_camera_effect(camera_effect)
    if not camera_effect_manager then
        return false
    end

    -- 使用特殊ID来注册效果
    camera_effect_manager:register_effect(9999, 9999, camera_effect, 0)
    return true
end

-- 向后兼容的别名（将来可能移除）
effects.test_camera_effect = effects.trigger_camera_effect

-- 清除所有相机效果（用于测试）
function effects.clear_all_camera_effects()
    if not camera_effect_manager then
        return false
    end

    camera_effect_manager:clear_all()
    return true
end

-- 获取活跃的相机效果数量（用于调试）
function effects.get_active_camera_effects_count()
    if not camera_effect_manager then
        return 0
    end

    local count = 0
    for _ in pairs(camera_effect_manager.active_effects) do
        count = count + 1
    end
    return count
end

return effects

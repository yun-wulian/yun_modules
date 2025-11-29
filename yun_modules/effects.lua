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
--     nodeID = 0x12345678,           -- 节点ID限制（可选）
--     lastMotion = 123,              -- 前序动作限制（可选）
--     specialCondition = function() return true end,  -- 自定义条件（可选）
--
--     vfx = {150, 210},              -- 视觉特效 {容器ID, 特效ID}
--     force_release = false,         -- 是否强制释放特效（可选，默认false）
--
--     hit = {150, 210},              -- 命中特效（单次）或 {{150, 210}, {150, 211}} （多段）
--     isMultiHit = false,            -- 是否多段命中（可选）
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
--             {
--                 frame = 0,
--                 nodeID = 0x5919622b,
--                 vfx = {150, 210},
--                 cameraEffect = {
--                     fov_offset = 36,
--                     distance_offset = 2.6,
--                     radial_blur = 5.0,
--                     duration = 0.5,
--                     easing = "ease_out",
--                     -- 自定义恢复效果（可选）
--                     reverse_duration = 0.9,
--                     reverse_easing = "ease_in",
--                 },
--                 camera_vibration = {index = 6, priority = 4},
--                 pad_vibration = {id = 20, is_loop = false},
--             }
--         }
--     }
-- }
-- ============================================================================

local effects = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")

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
effects.effectTable = {}

-- 注册特效表
---@param effect_table table 特效表
function effects.push_effect_table(effect_table)
    if type(effect_table) == "table" then
        table.insert(effects.effectTable, effect_table)
    end
end

-- ============================================================================
-- 对外公开的特效 API
-- ============================================================================

-- 在玩家位置生成特效
---@param container number 容器ID
---@param efx number 特效ID
function effects.set_effect(container, efx)
    if not core.master_player then return end
    core.master_player:call("setItemEffect", container, efx)
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

    -- 特效实例管理
    self.effect_instances = {}  -- 需要强制释放的特效实例

    -- 命中特效缓存
    self.hit_cache = {}
    self.hit_count = 0

    -- 记录已触发的特效（防止重复触发）
    self.triggered_effects = {}  -- key: "motion_index", value: true

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

-- 全局特效上下文实例
local effect_context = EffectContext.new()

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

    -- 上一帧的FOV累积偏移量（用于增量更新）
    self.last_fov_offset = 0

    -- 计算结果缓存（在update_logic中计算，在apply_to_camera中应用）
    self.computed_fov_offset = 0
    self.computed_distance_offset = 0
    self.computed_radial_blur = 0

    return self
end

-- 检查是否暂停
function CameraEffectManager:is_paused()
    return core.TimeScaleManager and core.TimeScaleManager:call("get__Pausing")
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

    local camera_gameobject = camera:call("get_GameObject")
    if not camera_gameobject then return nil end

    local camera_transform = camera_gameobject:call("get_Transform")
    if not camera_transform then return nil end

    return camera_transform:call("get_Joints"):get_elements()[1]
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
            local duration = config.duration or 1.0
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

            -- 检查是否完成forward阶段
            if progress >= 1.0 then
                -- 始终进入reverse阶段（平滑恢复）
                effect.phase = "reverse"
                effect.reverse_start_time = current_time
                -- 记录峰值偏移量
                effect.fov_peak_offset = config.fov_offset
                effect.distance_offset_peak = effect.distance_offset_current
                effect.radial_blur_peak = effect.radial_blur_current
            end

        -- ===== Reverse 阶段 =====
        elseif effect.phase == "reverse" then
            local elapsed_time = current_time - effect.reverse_start_time
            local duration = config.reverse_duration or config.duration or 1.0
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

    -- 应用FOV增量（只在偏移量变化时写入）
    if self.computed_fov_offset ~= self.last_fov_offset then
        local current_fov = camera:call("get_FOV")
        local delta = self.computed_fov_offset - self.last_fov_offset
        camera:call("set_FOV", current_fov + delta)
        self.last_fov_offset = self.computed_fov_offset
    end

    -- 应用距离偏移
    if self.computed_distance_offset ~= 0 then
        local camera_joint = self:get_camera_joint()
        if camera_joint then
            local cam_pos = camera_joint:call("get_LocalPosition")
            -- 复用Vector3f对象，避免每帧创建新对象
            self.reused_vector.x = cam_pos.x
            self.reused_vector.y = cam_pos.y
            self.reused_vector.z = cam_pos.z - self.computed_distance_offset
            camera_joint:call("set_LocalPosition", self.reused_vector)
        end
    end
end

-- 清除所有效果
function CameraEffectManager:clear_all()
    self.active_effects = {}

    -- 如果有累积的FOV偏移，需要恢复（应用负的偏移量）
    if self.last_fov_offset ~= 0 then
        local camera = sdk.get_primary_camera()
        if camera then
            local current_fov = camera:call("get_FOV")
            camera:call("set_FOV", current_fov - self.last_fov_offset)
        end
        self.last_fov_offset = 0
    end

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
    local nodeID = rule.nodeID
    if nodeID == nil then
        return true  -- 没有节点限制
    end

    -- 直接使用 core 维护的当前节点ID
    return core._current_node == nodeID
end

-- 检查前序动作
---@param rule table 特效规则
---@param context table 特效上下文
---@return boolean 是否满足条件
function ConditionChecker.check_motion_history(rule, context)
    -- 检查上一个动作
    if rule.lastMotion ~= nil then
        if rule.lastMotion ~= context.last_motion then
            return false
        end
    end

    return true
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
        return current_frame >= frame[1] and current_frame <= frame[2]
    end

    -- 单一帧数
    return current_frame >= frame
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

-- 复用的Vector3f对象（用于命中特效计算，避免频繁创建）
local reused_up_vector = Vector3f.new(0, 1, 0)

-- 在玩家位置生成特效
---@param container number 容器ID
---@param effect number 特效ID
---@param force_release boolean 是否需要强制释放
---@param context table 特效上下文
function EffectExecutor.set_effect(container, effect, force_release, context)
    if not core.master_player then return end

    if force_release then
        -- 需要强制释放的特效，使用 setEffect 获取实例
        local instance = core.master_player:setEffect(container, effect)
        context:register_effect_instance(instance)
    else
        -- 普通特效，使用 setItemEffect（无返回值）
        core.master_player:call("setItemEffect", container, effect)
    end
end

-- 在命中位置生成特效
---@param hit_position userdata 命中位置
---@param container number 容器ID
---@param effect number 特效ID
function EffectExecutor.set_hit_effect(hit_position, container, effect)
    if not core.master_player then
        return
    end

    local effectContainer = sdk.create_instance("via.effect.script.EffectID", true):add_ref()
    effectContainer.ContainerID = container
    effectContainer.ElementID = effect

    local effManager = core.master_player:call("getObjectEffectManager")
    if not effManager then
        return
    end

    effManager:call(
        "requestEffect(via.effect.script.EffectID, via.vec3, via.Quaternion, via.GameObject, System.String, via.effect.script.EffectManager.WwiseTriggerInfo)",
        effectContainer,
        hit_position,
        hit_position:cross(reused_up_vector):to_quat(),
        nil, nil, nil
    )
end

-- 执行特效规则
---@param rule table 特效规则
---@param context table 特效上下文
---@param motion_id number 动作ID
---@param rule_index number 规则索引
function EffectExecutor.execute(rule, context, motion_id, rule_index)
    -- 1. 生成视觉特效
    local vfx = rule.vfx
    if vfx and type(vfx) == "table" and #vfx >= 2 then
        local force_release = rule.force_release or false
        EffectExecutor.set_effect(vfx[1], vfx[2], force_release, context)
    end

    -- 2. 注册命中特效
    local hit = rule.hit
    if hit then
        local frame = rule.frame
        local is_multi_hit = rule.isMultiHit or false
        context:register_hit_effect(hit, frame, is_multi_hit)
    end

    -- 3. 注册相机效果
    local camera_effect = rule.cameraEffect
    if camera_effect then
        local start_frame = type(rule.frame) == "table" and rule.frame[1] or (rule.frame or 0)
        camera_effect_manager:register_effect(motion_id, rule_index, camera_effect, start_frame)
    end

    -- 4. 触发相机震动
    local camera_vibration = rule.camera_vibration
    if camera_vibration then
        local index = camera_vibration.index or camera_vibration[1]
        local priority = camera_vibration.priority or camera_vibration[2] or 0
        if index then
            effects.set_camera_vibration(index, priority)
        end
    end

    -- 5. 触发手柄震动
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
    -- 遍历所有特效表
    for _, sub_effect_table in ipairs(self.effect_table) do
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
    local cache = effect_context.hit_cache
    if not cache.hit_table then
        return
    end

    -- 检查攻击者是否是主玩家
    if dmg_info:call("get_AttackerID") ~= player_index then
        return
    end

    -- 检查武器类型是否匹配
    if dmg_info:get_WeaponType() ~= weapon_type then
        return
    end

    -- 检查帧数范围
    if type(cache.frame) == "table" then
        local current_frame = math.floor(core._action_frame)
        if current_frame > cache.frame[2] then
            return
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

    local post_effect = core.GameCamera:call("get_GameObject"):call("getComponent(System.Type)",
        sdk.typeof("snow.SnowPostEffectParam"))
    if not post_effect then
        return
    end

    local ldr_post_process = post_effect:get_field("_SnowLDRPostProcess")
    if not ldr_post_process then
        return
    end

    local radial_blur_param = ldr_post_process:call("get_RadialBlur")
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

    local radial_blur_component = pt_behavior:call("getRadialBlurComponent")
    if not radial_blur_component then
        return
    end

    -- 如果游戏原本没有开启径向模糊，设置默认参数
    if not is_org_blur_enabled then
        local color = radial_blur_component:call("get_Color")
        color:call("set_r", 255)
        color:call("set_g", 255)
        color:call("set_b", 255)
        color:call("set_a", 255)
        radial_blur_component:call("set_Color", color)
        radial_blur_component:call("set_ColorRate", 1.0)
        radial_blur_component:call("set_OccludeScale", 1.0)
        radial_blur_component:call("set_OccludeSampleNum", 16)
        radial_blur_component:call("setLookAtType", 1)
    end

    -- 应用模糊强度和启用状态
    radial_blur_param:call("set_BlurPower", current_blur)
    radial_blur_param:call("set_Enabled", current_blur > 0)
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
    local hit_pos = dmg_info:call("get_HitPos")
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

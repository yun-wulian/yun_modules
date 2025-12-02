-- yun_modules/derive.lua
-- 派生系统，用于动作转换和连招
--
-- ============================================================================
-- 派生表完整使用说明
-- ============================================================================
--
-- 基础派生规则结构：
-- {
--     targetNode = 0x12345678,       -- 目标节点ID（必需）
--     targetCmd = 1,                 -- 目标按键命令（普通派生必需，自动派生不需要）
--
--     -- 前置条件（可选）
--     preActionId = 123,             -- 前序动作ID限制（可选）或 {123, 124, 125} 匹配任意一个
--     preNodeId = 0x12345678,        -- 前序节点ID限制（可选）或 {0x123, 0x456} 匹配任意一个
--     specialCondition = function() return true end,  -- 自定义条件函数（可选）
--
--     -- 帧数设置（可选）
--     startFrame = 10,               -- 派生开始帧（可选，默认使用游戏原始派生开始帧）
--     preFrame = 10.0,               -- 前置输入帧数（可选，默认 10.0）
--
--     -- 输入设置（可选）
--     isHolding = false,             -- 是否需要按住按键（可选，默认 false）
--     holdingTime = 0.5,             -- 按住时长（秒）（可选，配合 isHolding 使用）
--     tarLstickDir = 1,              -- 摇杆方向限制（可选，四个方向）
--     isByPlayerDir = true,          -- 摇杆方向是否基于玩家朝向（可选，默认 true）
--     needIgnoreOriginalKey = 1,     -- 需要屏蔽的原始按键命令（可选）
--
--     -- 翔虫设置（可选）
--     useWire = {1, 5.0},            -- 使用翔虫 {消耗数量, 冷却时间（秒）}（可选）
--
--     -- 转向设置（可选）
--     turnRange = 180,               -- 允许的转向角度范围（可选）
--
--     -- 跳帧设置（可选）
--     jmpFrame = 20,                 -- 派生后跳转到指定帧数（可选）
--
--     -- 速度设置（可选）
--     actionSpeed = {                -- 动作速度修改（可选）
--         frame = {{0, 10}, {20, 30}},  -- 帧数范围列表
--         speed = {2.0, 0.5}            -- 对应的速度倍率
--     },
--
--     -- 攻击倍率（可选，{倍率, 持续命中次数}）
--     atkMult = {2.0, 3},            -- 攻击倍率（可选）
--     eleMult = {1.5, 3},            -- 属性倍率（可选）
--     stunMult = {2.0, 3},           -- 眩晕倍率（可选）
--     staMult = {1.5, 3},            -- 耐力倍率（可选）
--
--     -- 特殊派生（可选）
--     hit = true,                    -- 命中派生（设为 true 表示需要命中才能派生）
--     hitLag = 5,                    -- 命中延迟帧数（可选，配合 hit 使用）
--     counterAtk = {true, 1, {10, 30}},  -- 反击派生 {是否启用, 次数, {开始帧, 结束帧}}（可选）
--
--     -- 回调函数（可选）
--     onDeriveSuccess = function()   -- 派生成功后的回调函数（可选）
--         -- 自定义代码
--     end
-- }
--
-- ============================================================================
-- 派生类型说明
-- ============================================================================
--
-- 1. 普通派生（NORMAL）
--    - 需要 targetNode 和 targetCmd
--    - 玩家按下对应按键后触发
--
-- 2. 自动派生（AUTO）
--    - 只需要 targetNode，不需要 targetCmd
--    - 满足条件后自动触发
--
-- 3. 命中派生（HIT）
--    - 需要 targetNode 和 hit = true
--    - 攻击命中敌人后触发
--
-- 4. 反击派生（COUNTER）
--    - 需要 targetNode 和 counterAtk = {true, 次数, {开始帧, 结束帧}}
--    - 在指定帧数内受到攻击时触发
--
-- ============================================================================
-- 完整示例
-- ============================================================================
--
-- local derive_table = {
--     [weapon_type.ChargeAxe] = {
--         [100] = {  -- 动作ID
--             -- 示例1：普通派生（需要按键）
--             {
--                 targetNode = 0x12345678,
--                 targetCmd = 1,           -- 按键命令
--                 preActionId = {99, 100}, -- 从动作 99 或 100 转换过来
--                 startFrame = 10,
--                 preFrame = 15.0,
--                 atkMult = {1.5, 1},      -- 攻击倍率 1.5 倍，持续 1 次命中
--             },
--             -- 示例2：自动派生（无需按键）
--             {
--                 targetNode = 0x87654321,
--                 -- 不设置 targetCmd，满足条件后自动派生
--                 specialCondition = function()
--                     -- 自定义条件
--                     return some_value > 10
--                 end,
--                 jmpFrame = 20,           -- 派生后跳转到第 20 帧
--             },
--             -- 示例3：命中派生
--             {
--                 targetNode = 0xAABBCCDD,
--                 hit = true,              -- 命中后触发
--                 hitLag = 5,              -- 命中后延迟 5 帧
--                 atkMult = {2.0, 1},
--             },
--             -- 示例4：反击派生
--             {
--                 targetNode = 0x11223344,
--                 counterAtk = {true, 1, {10, 30}},  -- 10-30 帧内受击，触发 1 次反击
--                 needIgnoreOriginalKey = 2,  -- 屏蔽原始按键命令 2
--             },
--             -- 示例5：翔虫派生
--             {
--                 targetNode = 0x55667788,
--                 targetCmd = 3,
--                 useWire = {1, 5.0},      -- 消耗 1 个翔虫，冷却 5 秒
--                 tarLstickDir = 1,        -- 需要向前推摇杆
--                 turnRange = 90,          -- 允许 90 度转向
--             },
--             -- 示例6：带速度修改的派生
--             {
--                 targetNode = 0x99AABBCC,
--                 targetCmd = 4,
--                 actionSpeed = {
--                     frame = {{0, 15}, {20, 40}},  -- 两个帧数区间
--                     speed = {2.0, 0.5}            -- 对应速度倍率
--                 },
--                 onDeriveSuccess = function()
--                     log.info("派生成功！")
--                 end
--             }
--         }
--     }
-- }
-- ============================================================================

local derive = {}
local core = require("yunwulian.yun_modules.core")
local utils = require("yunwulian.yun_modules.utils")
local input = require("yunwulian.yun_modules.input")
local action = require("yunwulian.yun_modules.action")
local player = require("yunwulian.yun_modules.player")

-- 派生表注册
derive.deriveTable = {}

-- 钩子函数
derive.hook_evaluate_post = {}

-- 注册派生表
---@param derive_table table 派生表
function derive.push_derive_table(derive_table)
    if type(derive_table) == "table" then
        table.insert(derive.deriveTable, derive_table)
    end
end

-- 添加按键判定函数
---@param func function 函数
function derive.push_evaluate_post_functions(func)
    if type(func) == "function" then
        table.insert(derive.hook_evaluate_post, func)
    end
end

-- ============================================================================
-- 状态机重构 - 新实现
-- ============================================================================

-- 常量定义
local CONST = {
    DEFAULT_PRE_FRAME = 10.0,
}

-- 派生类型
local DeriveType = {
    NORMAL = "normal",        -- 普通派生（需要输入）
    HIT = "hit",             -- 命中派生
    COUNTER = "counter",     -- 反击派生
    AUTO = "auto"            -- 自动派生（无需输入）
}

-- 派生上下文 - 管理派生过程中的全局状态
local DeriveContext = {}
DeriveContext.__index = DeriveContext

function DeriveContext.new()
    local self = setmetatable({}, DeriveContext)

    -- 输入状态
    self.input_cache = 0
    self.pressed_time = 0.0

    -- 命中和反击状态
    self.hit_success = -1
    self.counter_success = false
    self.hit_counter_info = {}
    self.need_hit_info = {}

    -- 派生数据
    self.derive_atk_data = {}
    self.need_speed_change = {}
    self.ignore_keys = {}

    -- 跳帧相关
    self.jmp_frame_cache = 0
    self.jmp_frame_id = 0

    -- 回调相关
    self.callback_cache = nil
    self.callback_id = 0

    -- 清理相关
    self.need_clear = -1
    self.wrappered_id = nil

    -- 其他状态
    self.this_derive_cmd = 0
    self.this_is_by_action_id = true

    -- 速度控制状态
    self.speed_original = nil
    self.speed_index = nil
    self.speed_modified = false
    self.speed_node_id = nil

    -- specialCondition派生执行跟踪
    self.executed_special_derives = {} -- 记录已执行的特殊派生

    return self
end

-- 重置上下文（动作改变时）
function DeriveContext:reset()
    -- 注意：input_cache 不在这里重置！和旧实现保持一致
    -- input_cache 只在执行派生后清零
    self.pressed_time = 0.0
    self.hit_success = -1
    self.counter_success = false
    self.hit_counter_info = {}
    self.need_hit_info = {}
    self.derive_atk_data = {}
    self.jmp_frame_cache = 0
    self.jmp_frame_id = 0
    self.callback_cache = nil
    self.callback_id = 0
    self.need_clear = -1
    self.executed_special_derives = {} -- 清除特殊派生执行记录
end

-- 检查是否需要清理数据
function DeriveContext:check_and_clear()
    if core._pre_action_id ~= self.wrappered_id and
       core._pre_node_id ~= self.wrappered_id and
       self.need_clear == core._pre_node_id then
        self:reset()
    end
end

-- 缓存输入
function DeriveContext:cache_input(target_node)
    if self.input_cache == 0 then
        self.input_cache = target_node
        return true
    end
    return false
end

-- 清除输入缓存
function DeriveContext:clear_input_cache()
    self.input_cache = 0
end

-- 检查按键是否按住特定时长
function DeriveContext:check_holding_key(key, time)
    if input.check_input_by_isOn(key) then
        self.pressed_time = self.pressed_time + player.get_delta_time()
        if self.pressed_time > time then
            self.pressed_time = 0.0
            return true
        end
    elseif not input.check_input_by_isOn(key) and self.pressed_time ~= 0 then
        self.pressed_time = 0.0
    end
    return false
end

-- 速度改变处理
function DeriveContext:update_speed()
    local found_active_node = false
    for id, speed_table in pairs(self.need_speed_change) do
        if core._current_node == id then
            found_active_node = true
            if self.speed_node_id ~= id then
                self.speed_original = player.get_player_timescale()
                self.speed_node_id = id
                self.speed_modified = false
                self.speed_index = nil
            end
            local target_speed, target_index = nil, nil
            for i, frameRange in ipairs(speed_table["frame"]) do
                if utils.isFrameInRange(core._action_frame, frameRange) then
                    target_speed, target_index = speed_table["speed"][i], i
                    break
                end
            end
            if target_speed then
                if self.speed_index ~= target_index then
                    player.set_player_timescale(target_speed)
                    self.speed_index = target_index
                    self.speed_modified = true
                end
            else
                if self.speed_modified then
                    player.set_player_timescale(self.speed_original or -1.0)
                    self.speed_modified = false
                    self.speed_index = nil
                end
            end
            break
        elseif core._pre_node_id == id then
            self.need_speed_change[id] = nil
            if self.speed_node_id == id then
                if self.speed_modified then
                    player.set_player_timescale(self.speed_original or -1.0)
                end
                self.speed_original = nil
                self.speed_index = nil
                self.speed_modified = false
                self.speed_node_id = nil
            end
        end
    end
    if not found_active_node and self.speed_modified then
        player.set_player_timescale(self.speed_original or -1.0)
        self.speed_original = nil
        self.speed_index = nil
        self.speed_modified = false
        self.speed_node_id = nil
    end
end

-- 全局派生上下文实例
local derive_context = DeriveContext.new()

-- 错误信息缓冲区
local error_messages = {}

-- ============================================================================
-- 条件检查器 - 封装各种派生条件检查逻辑
-- ============================================================================

local ConditionChecker = {}

-- 检查特殊条件标志
---@param rule table 派生规则
---@return boolean 是否满足特殊条件
function ConditionChecker.check_special_condition(rule)
    local condition = rule.specialCondition
    if type(condition) == "function" then
        local success, result = pcall(condition)
        if not success then
            table.insert(error_messages, tostring(result))
            return false
        end
        return result == true
    end
    return condition ~= false
end

-- 检查前置动作ID
---@param rule table 派生规则
---@return boolean 是否满足条件
function ConditionChecker.check_pre_action_id(rule)
    local preActionId = rule.preActionId
    if preActionId == nil then
        return true
    end

    -- 支持表格形式：匹配任意一个前序动作
    if type(preActionId) == "table" then
        for _, action_id in ipairs(preActionId) do
            if action_id == core._pre_action_id then
                return true
            end
        end
        return false
    end

    -- 单个值形式：精确匹配
    return core._pre_action_id == preActionId
end

-- 检查前置节点ID
---@param rule table 派生规则
---@return boolean 是否满足条件
function ConditionChecker.check_pre_node_id(rule)
    local preNodeId = rule.preNodeId
    if preNodeId == nil then
        return true
    end

    -- 支持表格形式：匹配任意一个前序节点
    if type(preNodeId) == "table" then
        for _, node_id in ipairs(preNodeId) do
            if node_id == core._pre_node_id then
                return true
            end
        end
        return false
    end

    -- 单个值形式：精确匹配
    return core._pre_node_id == preNodeId
end

-- 检查所有前置条件
---@param rule table 派生规则
---@return boolean 是否满足所有前置条件
function ConditionChecker.check_preconditions(rule)
    if not ConditionChecker.check_special_condition(rule) then
        return false
    end
    if not ConditionChecker.check_pre_action_id(rule) then
        return false
    end
    if not ConditionChecker.check_pre_node_id(rule) then
        return false
    end
    return true
end

-- 获取派生的开始帧（自动派生默认0，普通派生默认使用游戏原始帧）
---@param rule table 派生规则
---@return number 开始帧
local function get_start_frame(rule)
    if rule.startFrame ~= nil then
        return rule.startFrame
    end
    -- 自动派生（无targetCmd）默认立即执行，普通派生使用游戏默认帧
    return rule.targetCmd == nil and 0 or core._derive_start_frame
end

-- 检查是否在输入窗口内
---@param rule table 派生规则
---@return boolean 是否在输入窗口内
function ConditionChecker.check_input_window(rule)
    local startFrame = get_start_frame(rule)
    local preFrame = rule.preFrame or CONST.DEFAULT_PRE_FRAME

    -- 在输入窗口内：当前帧 >= (开始帧 - 前置帧)
    return (startFrame - preFrame) <= core._action_frame
end

-- 检查是否到达开始帧
---@param rule table 派生规则
---@return boolean 是否到达开始帧
function ConditionChecker.check_start_frame(rule)
    return get_start_frame(rule) <= core._action_frame
end

-- 检查翔虫数量
---@param rule table 派生规则
---@return boolean 是否有足够的翔虫
function ConditionChecker.check_wire_gauge(rule)
    local useWire = rule.useWire
    if useWire ~= nil then
        if useWire[1] > core.master_player:getUsableHunterWireNum() then
            return false
        end
    end
    return true
end

-- 检查摇杆方向
---@param rule table 派生规则
---@return boolean 是否满足摇杆方向条件
function ConditionChecker.check_lstick_direction(rule)
    local tarLstickDir = rule.tarLstickDir
    if tarLstickDir == nil then
        return true
    end

    local isByPlayerDir = rule.isByPlayerDir

    -- 默认或显式设置为 true：基于玩家方向
    if isByPlayerDir == nil or isByPlayerDir then
        return input.check_lstick_dir_for_player_only_quad(tarLstickDir)
    else
        -- 基于世界方向
        return input.check_lstick_dir(tarLstickDir)
    end
end

-- 检查输入（普通按键）
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否检测到输入
function ConditionChecker.check_input(rule, context)
    local targetCmd = rule.targetCmd
    local isHolding = rule.isHolding
    local holdingTime = rule.holdingTime

    -- 如果没有目标命令，表示自动派生（无需输入）
    if targetCmd == nil then
        return true
    end

    -- 检查按住特定时长
    if holdingTime then
        return context:check_holding_key(targetCmd, holdingTime)
    end

    -- 检查是否按住
    if isHolding and not holdingTime then
        return input.check_input_by_isOn(targetCmd)
    end

    -- 默认：检查是否按下（单次触发）
    return input.check_input_by_isCmd(targetCmd)
end

-- 检查是否满足命中条件
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否满足命中条件
function ConditionChecker.check_hit_condition(rule, context)
    if rule.hit == nil then
        return false
    end

    -- 检查是否命中成功
    if context.hit_success == -1 then
        return false
    end

    -- 检查命中延迟
    local hitLag = rule.hitLag
    if hitLag ~= nil then
        if context.hit_success + hitLag >= core._action_frame then
            return false
        end
    end

    return true
end

-- 检查是否满足反击条件
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否满足反击条件
function ConditionChecker.check_counter_condition(rule, context)
    if rule.counterAtk == nil then
        return false
    end

    return context.counter_success
end

-- 获取派生类型
---@param rule table 派生规则
---@return string 派生类型
function ConditionChecker.get_derive_type(rule)
    if rule.counterAtk ~= nil then
        return DeriveType.COUNTER
    elseif rule.hit ~= nil then
        return DeriveType.HIT
    elseif rule.targetCmd == nil then
        return DeriveType.AUTO
    else
        return DeriveType.NORMAL
    end
end

-- ============================================================================
-- 输入处理器 - 封装输入检测和缓存逻辑
-- ============================================================================

local InputHandler = {}

-- 初始化特殊派生信息（命中、反击等）
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
function InputHandler.init_special_info(rule, context, wrappered_id)
    -- 设置反击信息
    if rule.counterAtk ~= nil and context.hit_counter_info[1] == nil then
        context.hit_counter_info = utils.deepCopy(rule.counterAtk)
    end

    -- 设置命中信息
    if rule.hit ~= nil then
        context.need_hit_info = { core._action_id, rule.startFrame or core._derive_start_frame }
    end

    -- 注意：needIgnoreOriginalKey 已移至条件检查通过后处理
    -- 确保只有在"等待按键"状态时才屏蔽原始按键
end

-- 处理输入检测和缓存
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否成功缓存输入
function InputHandler.process_input_cache(rule, context)
    -- 如果已经有缓存，不再处理
    if context.input_cache ~= 0 then
        return false
    end

    local targetNode = rule.targetNode
    local targetCmd = rule.targetCmd
    local derive_type = ConditionChecker.get_derive_type(rule)

    -- 自动派生（无需输入）
    if derive_type == DeriveType.AUTO then
        return context:cache_input(targetNode)
    end

    -- 命中派生和反击派生不在这里处理输入
    if derive_type == DeriveType.HIT or derive_type == DeriveType.COUNTER then
        return false
    end

    -- 普通派生：检查输入
    if targetCmd ~= nil then
        if ConditionChecker.check_input(rule, context) then
            return context:cache_input(targetNode)
        end
    end

    return false
end

-- ============================================================================
-- 派生执行器 - 封装派生执行的所有操作
-- ============================================================================

local DeriveExecutor = {}

-- 执行派生动作
---@param target_node number 目标节点
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
function DeriveExecutor.execute(target_node, rule, context, wrappered_id)
    -- 记录已执行的特殊派生
    if rule.specialCondition and type(rule.specialCondition) == "function" then
        local derive_key = wrappered_id .. "_" .. tostring(target_node)
        context.executed_special_derives[derive_key] = true
    end

    -- 设置当前节点
    action.set_current_node(target_node)

    -- 消耗翔虫（在动作改变后）
    DeriveExecutor.consume_wire_gauge(rule)

    -- 应用转向
    DeriveExecutor.apply_turn(rule)

    -- 应用跳帧
    DeriveExecutor.apply_jump_frame(rule, context, wrappered_id)

    -- 应用速度改变
    DeriveExecutor.apply_speed_change(rule, context, target_node)

    -- 应用攻击倍率
    DeriveExecutor.apply_attack_multipliers(rule, context)

    -- 应用派生成功回调
    DeriveExecutor.apply_callback(rule, context, wrappered_id)

    -- 设置清理标志和清除输入缓存
    context.need_clear = target_node or -1
    context:clear_input_cache()
end

-- 应用转向
---@param rule table 派生规则
function DeriveExecutor.apply_turn(rule)
    local turnRange = rule.turnRange
    if turnRange ~= nil then
        input.turn_to_lstick_dir(turnRange)
    end
end

-- 应用跳帧
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
function DeriveExecutor.apply_jump_frame(rule, context, wrappered_id)
    local jmpFrame = rule.jmpFrame
    if jmpFrame ~= nil then
        context.jmp_frame_cache = jmpFrame
        context.jmp_frame_id = wrappered_id
    end
end

-- 应用速度改变
---@param rule table 派生规则
---@param context table 派生上下文
---@param target_node number 目标节点
function DeriveExecutor.apply_speed_change(rule, context, target_node)
    local actionSpeed = rule.actionSpeed
    if actionSpeed ~= nil then
        context.need_speed_change[target_node] = utils.deepCopy(actionSpeed)
    end
end

-- 应用攻击倍率
---@param rule table 派生规则
---@param context table 派生上下文
function DeriveExecutor.apply_attack_multipliers(rule, context)
    -- 攻击倍率
    if rule.atkMult ~= nil then
        context.derive_atk_data.atkMult = utils.deepCopy(rule.atkMult)
    end

    -- 属性倍率
    if rule.eleMult ~= nil then
        context.derive_atk_data.eleMult = utils.deepCopy(rule.eleMult)
    end

    -- 眩晕倍率
    if rule.stunMult ~= nil then
        context.derive_atk_data.stunMult = utils.deepCopy(rule.stunMult)
    end

    -- 耐力倍率
    if rule.staMult ~= nil then
        context.derive_atk_data.staMult = utils.deepCopy(rule.staMult)
    end
end

-- 应用派生成功回调
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
function DeriveExecutor.apply_callback(rule, context, wrappered_id)
    local callback = rule.onDeriveSuccess
    if callback ~= nil and type(callback) == "function" then
        context.callback_cache = callback
        context.callback_id = wrappered_id
    end
end

-- 消耗翔虫
---@param rule table 派生规则
function DeriveExecutor.consume_wire_gauge(rule)
    local useWire = rule.useWire
    if useWire ~= nil then
        -- 第二个参数必须是浮点数类型
        core.master_player:useHunterWireGauge(useWire[1], useWire[2] * 1.0)
    end
end

-- ============================================================================
-- 派生规则处理器 - 静态函数，零对象创建开销
-- ============================================================================

local DeriveRuleProcessor = {}

-- 处理派生规则（每帧调用）- 静态函数版本
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
---@return boolean 是否成功执行派生
function DeriveRuleProcessor.process(rule, context, wrappered_id)
    -- 1. 检查前置条件
    if not ConditionChecker.check_preconditions(rule) then
        return false
    end

    -- 2. 检查目标节点是否存在
    local targetNode = rule.targetNode
    if targetNode == nil then
        return false
    end

    -- 3. 检查是否为specialCondition派生且已执行过，防止重复执行
    if rule.specialCondition and type(rule.specialCondition) == "function" then
        local derive_key = wrappered_id .. "_" .. tostring(targetNode)
        if context.executed_special_derives[derive_key] then
            return false -- 已经执行过这个特殊派生，跳过
        end
    end

    -- 4. 初始化特殊派生信息（每帧都要检查，因为可能需要更新）
    InputHandler.init_special_info(rule, context, wrappered_id)

    -- 5. 获取派生类型（提前获取，用于判断是否需要帧数检查）
    local derive_type = ConditionChecker.get_derive_type(rule)

    -- 6. 对于命中派生和反击派生，跳过输入窗口和开始帧检查（它们基于事件触发）
    if derive_type ~= DeriveType.HIT and derive_type ~= DeriveType.COUNTER then
        -- 检查是否在输入窗口内
        if not ConditionChecker.check_input_window(rule) then
            return false
        end

        -- 检查是否到达开始帧
        if not ConditionChecker.check_start_frame(rule) then
            return false
        end
    end

    -- 7. 检查翔虫数量
    if not ConditionChecker.check_wire_gauge(rule) then
        return false
    end

    -- 8. 检查摇杆方向
    if not ConditionChecker.check_lstick_direction(rule) then
        return false
    end

    -- 9. 设置需要忽略的原始按键（所有条件都满足，准备接收输入）
    -- 只对普通派生（需要按键输入）进行处理
    if derive_type == DeriveType.NORMAL and rule.needIgnoreOriginalKey ~= nil then
        if not context.ignore_keys[wrappered_id] then
            context.ignore_keys[wrappered_id] = {}
        end

        -- 检查是否已经添加过，避免重复
        local already_exists = false
        for _, key in ipairs(context.ignore_keys[wrappered_id]) do
            if key == rule.needIgnoreOriginalKey then
                already_exists = true
                break
            end
        end

        if not already_exists then
            table.insert(context.ignore_keys[wrappered_id], rule.needIgnoreOriginalKey)
        end
    end

    -- 10. 处理输入检测和缓存（普通派生和自动派生）
    if derive_type == DeriveType.NORMAL or derive_type == DeriveType.AUTO then
        InputHandler.process_input_cache(rule, context)
    end

    -- 11. 尝试执行派生
    return DeriveRuleProcessor.try_execute(rule, context, wrappered_id, derive_type, targetNode)
end

-- 尝试执行派生（静态函数）
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
---@param derive_type string 派生类型
---@param targetNode number 目标节点
---@return boolean 是否成功执行
function DeriveRuleProcessor.try_execute(rule, context, wrappered_id, derive_type, targetNode)
    -- 普通派生和自动派生：检查输入缓存
    if derive_type == DeriveType.NORMAL or derive_type == DeriveType.AUTO then
        -- 关键修复：验证 input_cache 是否匹配当前规则的 targetNode，并且是在有效的输入窗口内缓存的
        if context.input_cache ~= 0 and context.input_cache == targetNode then
            -- 额外的验证：确保当前帧在输入窗口内，避免使用过期的缓存
            local startFrame = get_start_frame(rule)
            local preFrame = rule.preFrame or CONST.DEFAULT_PRE_FRAME
            local currentFrame = core._action_frame

            -- 检查是否在有效的输入窗口内（当前帧 >= 开始帧 - 前置帧）
            if (startFrame - preFrame) <= currentFrame then
                DeriveExecutor.execute(targetNode, rule, context, wrappered_id)
                return true
            else
                -- 如果不在输入窗口内，清除过期的缓存
                context:clear_input_cache()
            end
        end
    end

    -- 命中派生
    if derive_type == DeriveType.HIT then
        if ConditionChecker.check_hit_condition(rule, context) then
            DeriveExecutor.execute(targetNode, rule, context, wrappered_id)
            context.hit_success = -1  -- 重置命中标志
            return true
        end
    end

    -- 反击派生
    if derive_type == DeriveType.COUNTER then
        if ConditionChecker.check_counter_condition(rule, context) then
            DeriveExecutor.execute(targetNode, rule, context, wrappered_id)
            context.counter_success = false  -- 重置反击标志
            return true
        end
    end

    return false
end

-- ============================================================================
-- 派生状态机 - 主状态机，协调所有派生规则处理
-- ============================================================================

local DeriveStateMachine = {}
DeriveStateMachine.__index = DeriveStateMachine

-- 创建派生状态机
---@param derive_table table 派生表
---@param context table 派生上下文
---@return table 派生状态机实例
function DeriveStateMachine.new(derive_table, context)
    local self = setmetatable({}, DeriveStateMachine)
    self.derive_table = derive_table
    self.context = context
    return self
end

-- 查找匹配的动作表
---@param sub_derive_table table 子派生表
---@return table|nil 动作表
---@return number|nil 包装ID
---@return boolean|nil 是否通过动作ID
function DeriveStateMachine:find_action_table(sub_derive_table)
    -- 检查武器类型是否匹配
    if sub_derive_table[core._wep_type] == nil then
        return nil, nil, nil
    end

    local wep_table = sub_derive_table[core._wep_type]

    -- 首先尝试匹配动作ID
    local action_table = wep_table[core._action_id]
    if action_table ~= nil then
        return action_table, core._action_id, true
    end

    -- 其次尝试匹配节点ID
    action_table = wep_table[core._current_node]
    if action_table ~= nil then
        return action_table, core._current_node, false
    end

    return nil, nil, nil
end

-- 处理单个派生表
---@param sub_derive_table table 子派生表
---@return boolean 是否成功执行派生
function DeriveStateMachine:process_derive_table(sub_derive_table)
    -- 查找匹配的动作表
    local action_table, wrapped_id, is_by_action_id = self:find_action_table(sub_derive_table)

    if action_table == nil or wrapped_id == nil then
        return false
    end

    -- 更新上下文状态
    self.context.wrappered_id = wrapped_id
    self.context.this_is_by_action_id = is_by_action_id

    -- 遍历所有派生规则（直接调用静态函数，零对象创建开销）
    for _, rule in ipairs(action_table) do
        local success = DeriveRuleProcessor.process(rule, self.context, wrapped_id)

        -- 如果成功执行派生，退出循环
        if success then
            return true
        end
    end

    return false
end

-- 更新状态机（每帧调用）
function DeriveStateMachine:update()
    -- 检查玩家是否存在
    if not core.master_player then
        return
    end

    -- 遍历所有派生表
    for _, sub_derive_table in ipairs(self.derive_table) do
        local success = self:process_derive_table(sub_derive_table)

        -- 如果成功执行派生，退出循环
        if success then
            break
        end
    end
end

-- ============================================================================
-- 派生包装函数 - 状态机实现
-- ============================================================================

-- 全局状态机实例
local derive_state_machine = nil

-- 派生包装函数
local function derive_wrapper(derive_table)
    if not derive_state_machine then
        derive_state_machine = DeriveStateMachine.new(derive_table, derive_context)
    end
    derive_state_machine.derive_table = derive_table
    derive_state_machine:update()
end

local function jmpFrame()
    if derive_context.jmp_frame_cache ~= 0 and derive_context.jmp_frame_id ~= 0 then
        if derive_context.jmp_frame_id == core._pre_node_id or derive_context.jmp_frame_id == core._pre_action_id then
            action.set_now_action_frame(derive_context.jmp_frame_cache)
            derive_context.jmp_frame_cache = 0
            derive_context.jmp_frame_id = 0
        end
    end
end

local function executeCallback()
    if derive_context.callback_cache ~= nil and derive_context.callback_id ~= 0 then
        -- 检查ID是否匹配（派生成功，动作已改变）
        if derive_context.callback_id == core._pre_node_id or
           derive_context.callback_id == core._pre_action_id then
            -- 使用pcall保护，避免用户函数报错影响系统
            local success, err = pcall(derive_context.callback_cache)
            if not success then
                table.insert(error_messages, "onDeriveSuccess callback error: " .. tostring(err))
            end

            -- 清除缓存，保证只执行一次
            derive_context.callback_cache = nil
            derive_context.callback_id = 0
        end
    end
end

local function wrappered_id_clear_data()
    derive_context:check_and_clear()
end

-- 更新函数
function derive.update()
    derive_wrapper(derive.deriveTable)
    derive_context:update_speed()
end

-- 延迟更新（用于清理）
function derive.late_update()
    wrappered_id_clear_data()
end

-- 动作改变回调
function derive.on_action_change()
    jmpFrame()
    executeCallback()
    derive_context.hit_counter_info = {}
    derive_context.need_hit_info = {} -- 清除命中信息
    derive_context.executed_special_derives = {} -- 清除特殊派生执行记录
    derive_context.hit_success = -1 -- 清除命中标志
    derive_context.counter_success = false -- 清除反击标志
end

-- 获取派生攻击数据（用于钩子和调试）
---@return table 派生攻击数据
function derive.get_derive_atk_data()
    return derive_context.derive_atk_data
end

-- 获取命中计数器信息
---@return table 命中计数器信息
function derive.get_hit_counter_info()
    return derive_context.hit_counter_info
end

-- 获取需要命中的信息
---@return table 需要命中的信息
function derive.get_need_hit_info()
    return derive_context.need_hit_info
end

-- 设置命中成功
---@param value any 值
function derive.set_hit_success(value)
    derive_context.hit_success = value
end

-- 设置反击成功
---@param value boolean 值
function derive.set_counter_success(value)
    derive_context.counter_success = value
end

-- 获取命中成功
---@return any 命中成功值
function derive.get_hit_success()
    return derive_context.hit_success
end

-- 获取反击成功
---@return boolean 是否反击成功
function derive.get_counter_success()
    return derive_context.counter_success
end

-- 设置派生开始帧
---@param value number 值
function derive.set_derive_start_frame(value)
    core._derive_start_frame = value
end

-- 获取当前派生命令
---@return number 派生命令
function derive.get_this_derive_cmd()
    return derive_context.this_derive_cmd
end

-- 设置当前派生命令
---@param value number 值
function derive.set_this_derive_cmd(value)
    derive_context.this_derive_cmd = value
end

-- 获取忽略的按键
---@return table 忽略的按键表
function derive.get_ignore_keys()
    return derive_context.ignore_keys
end

-- 获取是否通过动作ID
---@return boolean 是否通过动作ID
function derive.get_this_is_by_action_id()
    return derive_context.this_is_by_action_id
end

-- 绘制错误信息
function derive.draw_errors()
    if #error_messages > 0 and imgui.tree_node("派生错误") then
        for _, msg in ipairs(error_messages) do
            imgui.text_colored(1, 0, 0, 1, msg)
        end
        if imgui.button("清空") then error_messages = {} end
        imgui.tree_pop()
    end
end

-- ============================================================================
-- 钩子处理函数 - 由hooks.lua调用
-- ============================================================================

-- 钩子：命令评估（按键按下检测）- 后置处理
---@param retval any 返回值
---@param commandbase any 命令基对象
---@param commandarg any 命令参数
---@return any 修改后的返回值
function derive.hook_evaluate_post_command(retval, commandbase, commandarg)
    -- 设置当前派生命令
    local cmd_type = commandbase:get_field("CmdType")
    derive.set_this_derive_cmd(cmd_type)

    -- 处理按键忽略
    local ignore_keys = derive.get_ignore_keys()
    local this_is_by_action_id = derive.get_this_is_by_action_id()

    if this_is_by_action_id and ignore_keys[core._action_id] ~= nil then
        for _, value in ipairs(ignore_keys[core._action_id]) do
            if cmd_type == value then
                return sdk.to_ptr(0)
            end
        end
    elseif not this_is_by_action_id and ignore_keys[core._current_node] ~= nil then
        for _, value in ipairs(ignore_keys[core._current_node]) do
            if cmd_type == value then
                return sdk.to_ptr(0)
            end
        end
    end

    -- 设置派生开始帧
    if commandbase:get_field("StartFrame") > 1 then
        derive.set_derive_start_frame(commandbase:get_field("StartFrame"))
    end

    -- 执行注册的钩子函数
    for _, func in ipairs(derive.hook_evaluate_post) do
        retval = func(retval, commandbase, commandarg)
    end

    return retval
end

-- 钩子：反击检测 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_check_calc_damage(retval)
    local dmgOwnerType = thread.get_hook_storage()["damageData"]:get_OwnerType()
    if (dmgOwnerType == 1 or dmgOwnerType == 0) then
        local hit_counter_info = derive.get_hit_counter_info()
        if next(hit_counter_info) ~= nil then
            local frameInfo = hit_counter_info[3]
            if frameInfo and core._action_frame >= frameInfo[1] and core._action_frame <= frameInfo[2] then
                if hit_counter_info[2] > 0 then
                    hit_counter_info[2] = hit_counter_info[2] - 1
                    if hit_counter_info[1] then
                        derive.set_counter_success(true)
                    end
                    return sdk.to_ptr(2)
                end
            end
        end
    end

    return retval
end

-- 钩子：命中检测 - 前置处理
function derive.hook_pre_after_calc_damage(hitInfo)
    local damageData = hitInfo:get_AttackData()
    local dmgOwnerType = damageData:get_OwnerType()

    if dmgOwnerType == 2 then
        -- 处理命中信息
        local need_hit_info = derive.get_need_hit_info()
        if need_hit_info and next(need_hit_info) ~= nil then
            if need_hit_info[1] == core._action_id and need_hit_info[2] <= core._derive_start_frame then
                derive.set_hit_success(core._action_frame)
            end
        end

        -- 处理派生攻击数据持续时间
        local derive_atk_data = derive.get_derive_atk_data()
        if derive_atk_data and next(derive_atk_data) ~= nil then
            for key, subtable in pairs(derive_atk_data) do
                if subtable and subtable[2] and subtable[2] > 1 then
                    subtable[2] = subtable[2] - 1
                else
                    derive_atk_data[key] = nil
                end
            end
        end
    end
end

-- 钩子：攻击控制 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_calc_total_attack(retval)
    if not core.master_player then return retval end

    -- 处理攻击倍率
    if core.atk_flag then
        core.player_data:set_field("_Attack", core.player_atk)
    end

    -- 处理派生攻击倍率
    local derive_atk_data = derive.get_derive_atk_data()
    if derive_atk_data and derive_atk_data["atkMult"] ~= nil then
        core.player_data:set_field("_Attack", core.player_data:get_field("_Attack") * derive_atk_data["atkMult"][1])
    end

    return retval
end

-- 钩子：元素伤害倍率 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_element_sharpness_adjust(retval)
    local derive_atk_data = derive.get_derive_atk_data()
    if derive_atk_data and derive_atk_data["eleMult"] ~= nil then
        local eleValue = sdk.to_float(retval)
        return sdk.float_to_ptr(eleValue * derive_atk_data["eleMult"][1])
    end
    return retval
end

-- 钩子：眩晕伤害倍率 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_adjust_total_stun_attack(retval)
    local derive_atk_data = derive.get_derive_atk_data()
    if derive_atk_data and derive_atk_data["stunMult"] ~= nil then
        local stunMult = sdk.to_float(retval)
        return sdk.float_to_ptr(stunMult * derive_atk_data["stunMult"][1])
    end
    return retval
end

-- 钩子：耐力伤害倍率 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_adjust_total_stamina_attack(retval)
    local derive_atk_data = derive.get_derive_atk_data()
    if derive_atk_data and derive_atk_data["staMult"] ~= nil then
        local staMult = sdk.to_float(retval)
        return sdk.float_to_ptr(staMult * derive_atk_data["staMult"][1])
    end
    return retval
end

return derive

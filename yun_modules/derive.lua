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
--     tarLstickDir = 1,              -- 摇杆方向限制（可选，四个方向，-1表示任意方向）
--     isByPlayerDir = true,          -- 摇杆方向是否基于玩家朝向（可选，默认 true）
--     needIgnoreOriginalKey = 1,     -- 需要屏蔽的原始按键命令（可选，支持表格 {1, 2, 3}）
--     delay = true,                  -- 延迟派生（可选，用于连招组合键优先级控制）
--                                    -- true 使用默认延迟时间（约0.083秒）
--                                    -- 或指定秒数如 delay = 0.1（0.1秒）
--                                    -- 延迟派生会等待一小段时间，期间可被非延迟派生抢占
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
--    - 需要 targetNode 和 hit = true，不设置 targetCmd
--    - 攻击命中敌人后自动触发
--
-- 4. 反击派生（COUNTER）
--    - 需要 targetNode 和 counterAtk = {true, 次数, {开始帧, 结束帧}}，不设置 targetCmd
--    - 在指定帧数内受到攻击时自动触发
--
-- 5. 命中解锁派生（HIT + NORMAL）
--    - 需要 targetNode、hit = true 和 targetCmd
--    - 命中后解锁，然后需要按下按键才触发
--    - 适用于：命中后可选择是否追击的场景
--
-- 6. 反击解锁派生（COUNTER + NORMAL）
--    - 需要 targetNode、counterAtk 和 targetCmd
--    - 反击成功后解锁，然后需要按下按键才触发
--    - 适用于：反击后可选择追击方式的场景
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
--             -- 示例3：命中派生（命中后自动触发）
--             {
--                 targetNode = 0xAABBCCDD,
--                 hit = true,              -- 命中后自动触发
--                 hitLag = 5,              -- 命中后延迟 5 帧
--                 atkMult = {2.0, 1},
--             },
--             -- 示例4：反击派生（反击后自动触发）
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
--             },
--             -- 示例7：命中解锁派生（命中后需要按键才触发）
--             {
--                 targetNode = 0xDDEEFF00,
--                 hit = true,              -- 需要先命中
--                 targetCmd = 1,           -- 命中后按 A 键才派生
--                 hitLag = 3,              -- 命中后延迟 3 帧才能按键
--                 atkMult = {2.5, 1},
--             },
--             -- 示例8：反击解锁派生（反击后需要按键才触发）
--             {
--                 targetNode = 0x00112233,
--                 counterAtk = {true, 1, {5, 25}},  -- 5-25 帧内受击解锁
--                 targetCmd = 0,           -- 解锁后按 X 键才派生
--                 atkMult = {3.0, 1},
--             }
--         }
--     }
-- }
--
-- ============================================================================
-- 按键枚举使用说明
-- ============================================================================
--
-- 派生系统使用两种按键检测方式，对应两个枚举：
--
-- 1. constant.isCmd - 用于 targetCmd 字段（单次触发检测）
--    - 检测按键是否被按下（瞬间触发）
--    - 常用值：
--      constant.isCmd.AtkX      = 0   -- X攻击
--      constant.isCmd.AtkA      = 1   -- A攻击
--      constant.isCmd.AtkXA     = 2   -- X+A攻击
--      constant.isCmd.Escape    = 19  -- 回避
--      constant.isCmd.Guard     = 26  -- 防御
--      constant.isCmd.WireUp    = 33  -- 翔虫向上
--      constant.isCmd.WireFront = 34  -- 翔虫向前
--
-- 2. constant.isOn - 用于 isHolding 检测（按住检测）
--    - 检测按键是否被持续按住
--    - 常用值：
--      constant.isOn.Atk_X  = 0   -- X攻击
--      constant.isOn.Atk_A  = 1   -- A攻击
--      constant.isOn.Atk_R1 = 2   -- R1攻击
--      constant.isOn.Escape = 3   -- 回避
--      constant.isOn.Guard  = 4   -- 防御
--      constant.isOn.ZL     = 8   -- ZL
--      constant.isOn.ZR     = 9   -- ZR
--
-- 3. constant.commandFsm - 用于 needIgnoreOriginalKey 字段（屏蔽原始按键）
--    - 屏蔽游戏原始按键命令，防止派生时触发游戏默认动作
--    - 常用值：
--      constant.commandFsm.AtkA     = 1   -- A攻击
--      constant.commandFsm.AtkX     = 2   -- X攻击
--      constant.commandFsm.AtkXA    = 4   -- X+A攻击
--      constant.commandFsm.AtkR1    = 8   -- R1攻击
--      constant.commandFsm.Escape   = 24  -- 回避
--      constant.commandFsm.Guard    = 31  -- 防御
--      constant.commandFsm.WireUp   = 37  -- 翔虫向上
--      constant.commandFsm.WireFront = 38 -- 翔虫向前
--
-- 示例：使用枚举定义派生
-- local constant = require("yunwulian.yun_modules.constant")
-- local derive_table = {
--     [constant.weapon_type.ChargeAxe] = {
--         [100] = {
--             {
--                 targetNode = 0x12345678,
--                 targetCmd = constant.isCmd.AtkXA,  -- X+A攻击触发
--             },
--             {
--                 targetNode = 0x87654321,
--                 targetCmd = constant.isCmd.Guard,  -- 防御触发
--                 isHolding = true,                  -- 需要按住（使用 isOn 检测）
--             },
--             -- 示例3：使用 needIgnoreOriginalKey 屏蔽原始按键
--             {
--                 targetNode = 0xAABBCCDD,
--                 targetCmd = constant.isCmd.AtkA,   -- A攻击触发
--                 needIgnoreOriginalKey = constant.commandFsm.AtkA,  -- 屏蔽原始A攻击
--             },
--             -- 示例4：屏蔽多个原始按键
--             {
--                 targetNode = 0x11223344,
--                 targetCmd = constant.isCmd.AtkXA,  -- X+A攻击触发
--                 needIgnoreOriginalKey = {         -- 屏蔽多个按键
--                     constant.commandFsm.AtkX,
--                     constant.commandFsm.AtkA,
--                     constant.commandFsm.AtkXA,
--                 },
--             },
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
local constant = require("yunwulian.yun_modules.constant")

-- 派生表注册（使用字典结构支持动态移除）
derive.deriveTable = {}
derive._deriveTableNextId = 1
derive._deriveTableToId = {}  -- 表引用到数字ID的映射（用于支持通过表释放）

-- 钩子函数（使用字典结构支持动态移除）
derive.hook_evaluate_post = {}
derive._hookEvaluatePostNextId = 1
derive._hookFuncToId = {}  -- 函数引用到数字ID的映射（用于支持通过函数释放）

-- ============================================================================
-- 独立反击系统（Counter API）
-- ============================================================================
-- 反击注册表（使用字典结构支持动态移除）
derive.counter_registry = {}
derive._counterNextId = 1
-- 当前动作的活跃反击状态
derive._active_counters = {}

-- 注册派生表（轮询安全）
-- 多次传入同一个表会返回相同的ID
---@param derive_table table 派生表
---@return number|nil 返回注册的索引ID，失败返回nil
function derive.push_derive_table(derive_table)
    if type(derive_table) == "table" then
        -- 检查是否已经注册过（轮询安全）
        if derive._deriveTableToId[derive_table] then
            return derive._deriveTableToId[derive_table]
        end

        -- 创建新的注册
        local id = derive._deriveTableNextId
        derive._deriveTableNextId = derive._deriveTableNextId + 1
        derive.deriveTable[id] = derive_table
        derive._deriveTableToId[derive_table] = id
        return id
    end
    return nil
end

-- 移除派生表（轮询安全）
-- 支持传入表引用或数字ID
---@param id table|number 传入的表引用或注册时返回的索引ID
---@return boolean 是否成功移除
function derive.pop_derive_table(id)
    -- 如果传入的是表引用，查找对应的数字ID
    if type(id) == "table" then
        local numeric_id = derive._deriveTableToId[id]
        if numeric_id then
            derive._deriveTableToId[id] = nil
            derive.deriveTable[numeric_id] = nil
            return true
        end
        return false
    end

    -- 数字ID方式
    if type(id) == "number" and derive.deriveTable[id] ~= nil then
        -- 同时清除表引用映射
        local table_ref = derive.deriveTable[id]
        if table_ref then
            derive._deriveTableToId[table_ref] = nil
        end
        derive.deriveTable[id] = nil
        return true
    end
    return false
end

-- 添加按键判定函数（轮询安全）
-- 多次传入同一个函数会返回相同的ID
---@param func function 函数
---@return number|nil 返回注册的索引ID，失败返回nil
function derive.push_evaluate_post_functions(func)
    if type(func) == "function" then
        -- 检查是否已经注册过（轮询安全）
        if derive._hookFuncToId[func] then
            return derive._hookFuncToId[func]
        end

        -- 创建新的注册
        local id = derive._hookEvaluatePostNextId
        derive._hookEvaluatePostNextId = derive._hookEvaluatePostNextId + 1
        derive.hook_evaluate_post[id] = func
        derive._hookFuncToId[func] = id
        return id
    end
    return nil
end

-- 移除按键判定函数（轮询安全）
-- 支持传入函数引用或数字ID
---@param id function|number 传入的函数引用或注册时返回的索引ID
---@return boolean 是否成功移除
function derive.pop_evaluate_post_functions(id)
    -- 如果传入的是函数引用，查找对应的数字ID
    if type(id) == "function" then
        local numeric_id = derive._hookFuncToId[id]
        if numeric_id then
            derive._hookFuncToId[id] = nil
            derive.hook_evaluate_post[numeric_id] = nil
            return true
        end
        return false
    end

    -- 数字ID方式
    if type(id) == "number" and derive.hook_evaluate_post[id] ~= nil then
        -- 同时清除函数引用映射
        local func_ref = derive.hook_evaluate_post[id]
        if func_ref then
            derive._hookFuncToId[func_ref] = nil
        end
        derive.hook_evaluate_post[id] = nil
        return true
    end
    return false
end

-- ============================================================================
-- 独立反击接口（Counter API）
-- ============================================================================
--
-- 方式1：一次性注册（需自己管理生命周期）
-- local counter_id = derive.add_counter(100, 3, {10, 30}, function()
--     log.info("成功抵挡伤害！")
-- end)
-- derive.remove_counter(counter_id) -- 移除
--
-- 方式2：轮询安全（可重复调用，推荐）
-- derive.set_counter("my_mod_counter", 100, 3, {10, 30}, function()
--     log.info("成功抵挡伤害！")
-- end)
-- derive.unset_counter("my_mod_counter") -- 移除
--
-- action_id 支持表格形式，匹配任意一个动作ID：
-- derive.set_counter("my_counter", {100, 101, 102}, 3, {10, 30}, callback)
--
-- 在动作ID 100 的第 10-30 帧范围内，可以抵挡 3 次伤害
-- 每次抵挡时会调用回调函数
--
-- ============================================================================

--- 添加独立反击
---@param action_id number|table 动作ID（单个或表格形式 {100, 101, 102}）
---@param counter_count number 可抵挡次数
---@param frame_range table {开始帧, 结束帧}
---@param callback function|nil 每次抵挡时的回调函数（可选）
---@return number 返回注册的ID，用于后续移除
function derive.add_counter(action_id, counter_count, frame_range, callback)
    local id = derive._counterNextId
    derive._counterNextId = derive._counterNextId + 1
    derive.counter_registry[id] = {
        action_id = action_id,
        max_count = counter_count,
        frame_range = frame_range,
        callback = callback
    }
    return id
end

--- 移除独立反击
---@param id number 注册时返回的ID
---@return boolean 是否成功移除
function derive.remove_counter(id)
    if type(id) == "number" and derive.counter_registry[id] ~= nil then
        derive.counter_registry[id] = nil
        -- 同时清除活跃状态
        derive._active_counters[id] = nil
        return true
    end
    return false
end

--- 设置独立反击（幂等/轮询安全版本）
--- 使用 key 作为唯一标识，重复调用会更新而不是创建新的
---@param key string 唯一标识符（如 "my_mod_counter_1"）
---@param action_id number|table 动作ID（单个或表格形式 {100, 101, 102}）
---@param counter_count number 可抵挡次数
---@param frame_range table {开始帧, 结束帧}
---@param callback function|nil 每次抵挡时的回调函数（可选）
function derive.set_counter(key, action_id, counter_count, frame_range, callback)
    -- 使用字符串key作为ID，直接覆盖
    derive.counter_registry[key] = {
        action_id = action_id,
        max_count = counter_count,
        frame_range = frame_range,
        callback = callback
    }
end

--- 移除独立反击（通过key）
---@param key string 设置时使用的唯一标识符
---@return boolean 是否成功移除
function derive.unset_counter(key)
    if type(key) == "string" and derive.counter_registry[key] ~= nil then
        derive.counter_registry[key] = nil
        derive._active_counters[key] = nil
        return true
    end
    return false
end

-- ============================================================================
-- 状态机重构 - 新实现
-- ============================================================================

-- 引用常量模块
local CONST = constant.derive
local DeriveType = constant.derive_type

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
    self.derive_atk_data_pending = false  -- 标记是否刚设置，派生后第一次动作改变不清除
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
    self.speed_change_pending = false  -- 标记速度配置是否刚设置，派生后第一次动作改变不清除

    -- specialCondition派生执行跟踪
    self.executed_special_derives = {} -- 记录已执行的特殊派生

    -- 预输入和延迟派生状态
    self.pre_input_last = nil          -- 预输入阶段最后的输入 {targetNode, rule, wrappered_id}
    self.delay_pending = nil           -- 延迟等待的派生信息 {targetNode, rule, wrappered_id, delay_time}
    self.delay_elapsed = 0             -- 延迟已等待时间（秒）

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
    -- 清除预输入和延迟状态
    self.pre_input_last = nil
    self.delay_pending = nil
    self.delay_elapsed = 0
    self.ignore_keys = {} -- 清除忽略的按键
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

-- 保存预输入（预输入阶段存储最后一个输入，覆盖式）
---@param targetNode number 目标节点
---@param rule table 派生规则
---@param wrappered_id number 包装ID
function DeriveContext:save_pre_input(targetNode, rule, wrappered_id)
    self.pre_input_last = {
        targetNode = targetNode,
        rule = rule,
        wrappered_id = wrappered_id
    }
end

-- 清除预输入
function DeriveContext:clear_pre_input()
    self.pre_input_last = nil
end

-- 获取延迟时间（秒）
---@param rule table 派生规则
---@return number 延迟时间（秒）
function DeriveContext:get_delay_time(rule)
    local delay = rule.delay
    if delay == true then
        return CONST.DEFAULT_DELAY_TIME
    elseif type(delay) == "number" then
        return delay
    end
    return 0
end

-- 设置延迟等待
---@param targetNode number 目标节点
---@param rule table 派生规则
---@param wrappered_id number 包装ID
function DeriveContext:set_delay_pending(targetNode, rule, wrappered_id)
    local delay_time = self:get_delay_time(rule)
    self.delay_pending = {
        targetNode = targetNode,
        rule = rule,
        wrappered_id = wrappered_id,
        delay_time = delay_time
    }
    self.delay_elapsed = 0
end

-- 清除延迟等待
function DeriveContext:clear_delay_pending()
    self.delay_pending = nil
    self.delay_elapsed = 0
end

-- 更新延迟计时
---@return boolean 是否到期
function DeriveContext:update_delay_elapsed()
    if self.delay_pending then
        self.delay_elapsed = self.delay_elapsed + player.get_delta_time()
        return self.delay_elapsed >= self.delay_pending.delay_time
    end
    return false
end

-- 检查是否有延迟等待中
---@return boolean 是否有延迟等待
function DeriveContext:has_delay_pending()
    return self.delay_pending ~= nil
end

-- 速度改变处理
function DeriveContext:update_speed()
    -- 如果没有速度变化记录，直接返回
    if next(self.need_speed_change) == nil then
        return
    end

    -- 查找当前节点的速度配置
    local speed_table = self.need_speed_change[core._current_node]

    if speed_table then
        -- 当前节点有速度配置
        if self.speed_node_id ~= core._current_node then
            -- 新的节点，保存当前速度作为原始速度（仅在未修改时保存）
            if not self.speed_modified then
                self.speed_original = player.get_player_timescale()
            end
            self.speed_node_id = core._current_node
            self.speed_index = nil
        end

        -- 查找当前帧对应的速度
        local target_speed, target_index = nil, nil
        for i, frameRange in ipairs(speed_table["frame"]) do
            -- 转换帧数范围为浮点数
            local startF, endF = frameRange[1] + 0.0, frameRange[2] + 0.0
            if utils.isFrameInRange(core._action_frame, {startF, endF}) then
                target_speed, target_index = speed_table["speed"][i], i
                break
            end
        end

        if target_speed then
            -- 在速度区间内
            if self.speed_index ~= target_index then
                player.set_player_timescale(target_speed)
                self.speed_index = target_index
                self.speed_modified = true
            end
        else
            -- 不在任何速度区间内，恢复原始速度
            if self.speed_modified then
                player.set_player_timescale(self.speed_original or -1.0)
                self.speed_modified = false
                self.speed_index = nil
            end
        end
    else
        -- 当前节点没有速度配置
        -- 只有在之前应用过速度修改时才清理旧记录和恢复速度
        -- 这样避免在派生刚执行时（core._current_node 尚未更新）误删配置
        if self.speed_modified then
            -- 清理不再匹配的旧记录（节点已改变）
            for id, _ in pairs(self.need_speed_change) do
                if id ~= core._current_node then
                    self.need_speed_change[id] = nil
                end
            end

            -- 恢复原始速度
            player.set_player_timescale(self.speed_original or -1.0)
            self.speed_original = nil
            self.speed_index = nil
            self.speed_modified = false
            self.speed_node_id = nil
        end
    end
end

-- 全局派生上下文实例
local derive_context = DeriveContext.new()

-- 错误信息缓冲区
local error_messages = {}

-- ============================================================================
-- 独立反击系统 - 内部函数
-- ============================================================================

--- 内部函数：检查动作ID是否匹配
---@param config_action_id number|table 配置的动作ID（单个或表格）
---@param current_action_id number 当前动作ID
---@return boolean 是否匹配
local function match_action_id(config_action_id, current_action_id)
    if type(config_action_id) == "table" then
        -- 表格形式：匹配任意一个
        for _, aid in ipairs(config_action_id) do
            if aid == current_action_id then
                return true
            end
        end
        return false
    else
        -- 单个值：精确匹配
        return config_action_id == current_action_id
    end
end

--- 内部函数：检查并激活当前动作的反击
--- 在动作改变时调用，初始化当前动作的反击状态
local function activate_counters_for_action()
    derive._active_counters = {}
    for reg_id, counter_config in pairs(derive.counter_registry) do
        if match_action_id(counter_config.action_id, core._action_id) then
            -- 为当前动作创建活跃的反击状态
            derive._active_counters[reg_id] = {
                remaining_count = counter_config.max_count,
                frame_range = counter_config.frame_range,
                callback = counter_config.callback
            }
        end
    end
end

--- 内部函数：处理独立反击检测
--- 在受伤检测钩子中调用
---@return number|nil 返回2表示抵挡伤害，nil表示不处理
local function process_counter_damage()
    -- 检查是否有活跃的反击配置
    if next(derive._active_counters) == nil then
        return nil
    end

    local current_frame = core._action_frame

    for _, active_counter in pairs(derive._active_counters) do
        local frame_range = active_counter.frame_range
        -- 检查帧数范围
        if current_frame >= (frame_range[1] + 0.0) and current_frame <= (frame_range[2] + 0.0) then
            -- 检查剩余次数
            if active_counter.remaining_count > 0 then
                active_counter.remaining_count = active_counter.remaining_count - 1

                -- 调用回调函数
                if active_counter.callback and type(active_counter.callback) == "function" then
                    local success, err = pcall(active_counter.callback)
                    if not success then
                        table.insert(error_messages, "Counter callback error: " .. tostring(err))
                    end
                end

                return 2 -- 完全抵挡伤害
            end
        end
    end

    return nil
end

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
        return rule.startFrame + 0.0  -- 转换为浮点数
    end
    -- 自动派生（无targetCmd）默认立即执行，普通派生使用游戏默认帧
    return rule.targetCmd == nil and 0.0 or core._derive_start_frame
end

-- 检查是否在输入窗口内
---@param rule table 派生规则
---@return boolean 是否在输入窗口内
function ConditionChecker.check_input_window(rule)
    local startFrame = get_start_frame(rule)
    local preFrame = (rule.preFrame or CONST.DEFAULT_PRE_FRAME) + 0.0  -- 转换为浮点数

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
        if context.hit_success + (hitLag + 0.0) >= core._action_frame then  -- 转换为浮点数
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
    -- 有 targetCmd 时，hit 和 counterAtk 作为前置解锁条件，类型仍为 NORMAL
    if rule.targetCmd ~= nil then
        return DeriveType.NORMAL
    end

    -- 无 targetCmd 时，保持原有自动派生逻辑
    if rule.counterAtk ~= nil then
        return DeriveType.COUNTER
    elseif rule.hit ~= nil then
        return DeriveType.HIT
    else
        return DeriveType.AUTO
    end
end

-- 检查命中解锁条件（用于 hit + targetCmd 的情况）
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否已解锁
function ConditionChecker.check_hit_unlock(rule, context)
    -- 如果规则没有 hit 要求，直接通过
    if rule.hit == nil then
        return true
    end

    -- 需要 hit，检查是否已命中
    if context.hit_success == -1 then
        return false
    end

    -- 检查命中延迟
    local hitLag = rule.hitLag
    if hitLag ~= nil then
        if context.hit_success + (hitLag + 0.0) >= core._action_frame then
            return false
        end
    end

    return true
end

-- 检查反击解锁条件（用于 counterAtk + targetCmd 的情况）
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否已解锁
function ConditionChecker.check_counter_unlock(rule, context)
    -- 如果规则没有 counterAtk 要求，直接通过
    if rule.counterAtk == nil then
        return true
    end

    -- 需要 counterAtk，检查是否已反击成功
    return context.counter_success
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
        context.need_hit_info = { core._action_id, (rule.startFrame or core._derive_start_frame) + 0.0 }  -- 转换为浮点数
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
        context.jmp_frame_cache = jmpFrame + 0.0  -- 转换为浮点数，避免整数类型导致的问题
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
        context.speed_change_pending = true  -- 标记为待处理，派生后第一次动作改变不清除
    end
end

-- 应用攻击倍率
---@param rule table 派生规则
---@param context table 派生上下文
function DeriveExecutor.apply_attack_multipliers(rule, context)
    local has_mult = false

    -- 攻击倍率
    if rule.atkMult ~= nil then
        context.derive_atk_data.atkMult = utils.deepCopy(rule.atkMult)
        has_mult = true
    end

    -- 属性倍率
    if rule.eleMult ~= nil then
        context.derive_atk_data.eleMult = utils.deepCopy(rule.eleMult)
        has_mult = true
    end

    -- 眩晕倍率
    if rule.stunMult ~= nil then
        context.derive_atk_data.stunMult = utils.deepCopy(rule.stunMult)
        has_mult = true
    end

    -- 耐力倍率
    if rule.staMult ~= nil then
        context.derive_atk_data.staMult = utils.deepCopy(rule.staMult)
        has_mult = true
    end

    -- 标记为待处理，派生后的第一次动作改变不清除
    if has_mult then
        context.derive_atk_data_pending = true
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
    if derive_type == DeriveType.HIT or derive_type == DeriveType.COUNTER then
        -- 命中和反击派生直接尝试执行
        return DeriveRuleProcessor.try_execute_special(rule, context, wrappered_id, derive_type, targetNode)
    end

    -- ============================================================================
    -- 以下逻辑仅适用于普通派生和自动派生
    -- ============================================================================

    -- 7. 检查是否在输入窗口内（startFrame - preFrame 到当前帧）
    if not ConditionChecker.check_input_window(rule) then
        return false
    end

    -- 8. 检查翔虫数量（提前检查，避免无效的输入记录）
    if not ConditionChecker.check_wire_gauge(rule) then
        return false
    end

    -- 9. 检查摇杆方向
    if not ConditionChecker.check_lstick_direction(rule) then
        return false
    end

    -- 10. 计算是否到达开始帧（区分预输入阶段和可派生阶段）
    local is_derivable = ConditionChecker.check_start_frame(rule)
    local has_delay = rule.delay ~= nil

    -- 11. 设置需要忽略的原始按键（在输入窗口内就需要设置）
    if derive_type == DeriveType.NORMAL and rule.needIgnoreOriginalKey ~= nil then
        DeriveRuleProcessor.add_ignore_key(rule, context, wrappered_id)
    end

    -- 12. 检测当前帧输入
    local has_input = false
    if derive_type == DeriveType.NORMAL then
        has_input = ConditionChecker.check_input(rule, context)
    elseif derive_type == DeriveType.AUTO then
        has_input = true -- 自动派生始终"有输入"
    end

    -- ============================================================================
    -- 核心逻辑：预输入阶段 vs 可派生阶段
    -- ============================================================================

    if not is_derivable then
        -- 【预输入阶段】：只记录输入，不执行
        if has_input then
            context:save_pre_input(targetNode, rule, wrappered_id)
        end
        return false
    end

    -- 【可派生阶段】：到达startFrame，可以执行派生
    return DeriveRuleProcessor.try_execute(rule, context, wrappered_id, derive_type, targetNode, has_input, has_delay)
end

-- 添加忽略按键的辅助函数
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
function DeriveRuleProcessor.add_ignore_key(rule, context, wrappered_id)
    if not context.ignore_keys[wrappered_id] then
        context.ignore_keys[wrappered_id] = {}
    end

    local ignoreKey = rule.needIgnoreOriginalKey

    -- 支持表格形式 {1, 2, 3}
    if type(ignoreKey) == "table" then
        for _, key in ipairs(ignoreKey) do
            local exists = false
            for _, existing in ipairs(context.ignore_keys[wrappered_id]) do
                if existing == key then
                    exists = true
                    break
                end
            end
            if not exists then
                table.insert(context.ignore_keys[wrappered_id], key)
            end
        end
    else
        -- 单个值
        local exists = false
        for _, existing in ipairs(context.ignore_keys[wrappered_id]) do
            if existing == ignoreKey then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(context.ignore_keys[wrappered_id], ignoreKey)
        end
    end
end

-- 检查解锁条件（静态辅助函数，避免每次调用创建闭包）
---@param rule table 派生规则
---@param context table 派生上下文
---@return boolean 是否已解锁
function DeriveRuleProcessor.check_unlock_conditions(rule, context)
    if not ConditionChecker.check_hit_unlock(rule, context) then
        return false
    end
    if not ConditionChecker.check_counter_unlock(rule, context) then
        return false
    end
    return true
end

-- 执行派生并重置解锁标志（静态辅助函数，避免每次调用创建闭包）
---@param targetNode number 目标节点
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
function DeriveRuleProcessor.execute_and_reset_unlock(targetNode, rule, context, wrappered_id)
    DeriveExecutor.execute(targetNode, rule, context, wrappered_id)
    -- 执行成功后重置解锁标志
    if rule.hit ~= nil then
        context.hit_success = -1
    end
    if rule.counterAtk ~= nil then
        context.counter_success = false
    end
end

-- 尝试执行命中/反击派生（静态函数）
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
---@param derive_type string 派生类型
---@param targetNode number 目标节点
---@return boolean 是否成功执行
function DeriveRuleProcessor.try_execute_special(rule, context, wrappered_id, derive_type, targetNode)
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

-- 尝试执行普通/自动派生（静态函数）
-- 【可派生阶段】的核心逻辑
---@param rule table 派生规则
---@param context table 派生上下文
---@param wrappered_id number 包装ID
---@param derive_type string 派生类型
---@param targetNode number 目标节点
---@param has_input boolean 当前帧是否有输入
---@param has_delay boolean 是否是delay派生
---@return boolean 是否成功执行
function DeriveRuleProcessor.try_execute(rule, context, wrappered_id, derive_type, targetNode, has_input, has_delay)
    -- ============================================================================
    -- 情况1：有delay_pending正在等待
    -- ============================================================================
    if context:has_delay_pending() then
        -- 检查是否有非delay派生的输入要抢占
        if has_input and not has_delay then
            -- 检查解锁条件
            if not DeriveRuleProcessor.check_unlock_conditions(rule, context) then
                return false
            end
            -- 非delay派生抢占delay派生
            context:clear_delay_pending()
            context:clear_pre_input()
            DeriveRuleProcessor.execute_and_reset_unlock(targetNode, rule, context, wrappered_id)
            return true
        end

        -- 检查是否有新的delay派生输入（覆盖现有的）
        if has_input and has_delay then
            -- 新的delay派生覆盖旧的
            context:set_delay_pending(targetNode, rule, wrappered_id)
            context:clear_pre_input()
            return false -- 还未执行，继续等待
        end

        -- 没有新输入，检查当前等待的delay是否到期
        -- 注意：这里不检查，delay到期在update中统一处理
        return false
    end

    -- ============================================================================
    -- 情况2：没有delay_pending，检查预输入
    -- ============================================================================
    local pre_input = context.pre_input_last

    -- 首先处理预输入（如果有且匹配当前规则）
    -- 使用规则引用比较，确保只有保存预输入的那个规则才能消费它
    if pre_input and pre_input.rule == rule then
        -- 检查解锁条件（预输入可能在命中之前记录，需要等待解锁）
        if not DeriveRuleProcessor.check_unlock_conditions(rule, context) then
            return false -- 保留预输入，等待下一帧再检查
        end

        local pre_has_delay = rule.delay ~= nil

        if pre_has_delay then
            -- 预输入的派生是delay类型，开始等待
            context:set_delay_pending(targetNode, rule, wrappered_id)
            context:clear_pre_input()
            return false -- 开始等待，还未执行
        else
            -- 预输入的派生是非delay类型，立即执行
            context:clear_pre_input()
            DeriveRuleProcessor.execute_and_reset_unlock(targetNode, rule, context, wrappered_id)
            return true
        end
    end

    -- ============================================================================
    -- 情况3：没有预输入，检查当前帧输入
    -- ============================================================================
    if has_input then
        -- 检查解锁条件
        if not DeriveRuleProcessor.check_unlock_conditions(rule, context) then
            return false
        end

        if has_delay then
            -- delay派生，开始等待
            context:set_delay_pending(targetNode, rule, wrappered_id)
            return false -- 开始等待，还未执行
        else
            -- 非delay派生，立即执行
            DeriveRuleProcessor.execute_and_reset_unlock(targetNode, rule, context, wrappered_id)
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

    -- 遍历所有派生表（使用pairs支持字典结构）
    for _, sub_derive_table in pairs(self.derive_table) do
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

-- 处理delay到期
local function process_delay_timeout()
    if derive_context:has_delay_pending() then
        -- 更新延迟计时
        if derive_context:update_delay_elapsed() then
            -- 延迟到期，检查解锁条件
            local pending = derive_context.delay_pending
            local rule = pending.rule

            -- 检查解锁条件（复用静态函数）
            if not DeriveRuleProcessor.check_unlock_conditions(rule, derive_context) then
                return -- 未解锁，继续等待（不清除 delay_pending）
            end

            -- 执行派生并重置解锁标志（复用静态函数）
            DeriveRuleProcessor.execute_and_reset_unlock(
                pending.targetNode,
                rule,
                derive_context,
                pending.wrappered_id
            )

            derive_context:clear_delay_pending()
        end
    end
end

-- 更新函数
function derive.update()
    -- 先处理delay到期（优先于新输入检测）
    process_delay_timeout()
    -- 处理派生规则（包括新输入检测和抢占）
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
    -- 清除预输入和延迟状态
    derive_context:clear_pre_input()
    derive_context:clear_delay_pending()
    derive_context.ignore_keys = {} -- 清除忽略的按键

    -- 派生攻击数据清除逻辑：
    -- 如果是刚派生设置的（pending=true），第一次动作改变不清除，只取消标志
    -- 如果不是刚设置的（pending=false），清除数据
    if derive_context.derive_atk_data_pending then
        derive_context.derive_atk_data_pending = false
    else
        derive_context.derive_atk_data = {}
    end

    -- 清理速度状态：恢复原始速度并重置状态标志
    if derive_context.speed_modified then
        player.set_player_timescale(derive_context.speed_original or -1.0)
    end
    derive_context.speed_original = nil
    derive_context.speed_index = nil
    derive_context.speed_modified = false
    derive_context.speed_node_id = nil

    -- 速度配置清除逻辑（与 derive_atk_data_pending 类似）：
    -- 如果是刚派生设置的（pending=true），第一次动作改变不清除，只取消标志
    -- 如果不是刚设置的（pending=false），清除数据
    if derive_context.speed_change_pending then
        derive_context.speed_change_pending = false
    else
        derive_context.need_speed_change = {}
    end

    -- 激活当前动作的独立反击配置
    activate_counters_for_action()
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

    -- 执行注册的钩子函数（使用pairs支持字典结构）
    for _, func in pairs(derive.hook_evaluate_post) do
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
        -- 优先检查独立反击系统（Counter API）
        local counter_result = process_counter_damage()
        if counter_result then
            return sdk.to_ptr(counter_result)
        end

        -- 检查派生系统的反击（counterAtk）
        local hit_counter_info = derive.get_hit_counter_info()
        if next(hit_counter_info) ~= nil then
            local frameInfo = hit_counter_info[3]
            if frameInfo and core._action_frame >= (frameInfo[1] + 0.0) and core._action_frame <= (frameInfo[2] + 0.0) then  -- 转换为浮点数
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
        -- 处理命中信息（用于命中派生）
        local need_hit_info = derive.get_need_hit_info()
        if need_hit_info and next(need_hit_info) ~= nil then
            if need_hit_info[1] == core._action_id and need_hit_info[2] <= core._derive_start_frame then
                derive.set_hit_success(core._action_frame)
            end
        end
        -- 注意：派生攻击数据（atkMult等）的次数消耗已移至各自的钩子函数中
        -- 在应用倍率时立即消耗，而不是等到命中时，避免没命中时倍率保留/叠加的问题
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
        -- 应用后立即消耗次数，防止重复应用
        if derive_atk_data["atkMult"][2] > 1 then
            derive_atk_data["atkMult"][2] = derive_atk_data["atkMult"][2] - 1
        else
            derive_atk_data["atkMult"] = nil
        end
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
        local result = sdk.float_to_ptr(eleValue * derive_atk_data["eleMult"][1])
        -- 应用后立即消耗次数，防止重复应用
        if derive_atk_data["eleMult"][2] > 1 then
            derive_atk_data["eleMult"][2] = derive_atk_data["eleMult"][2] - 1
        else
            derive_atk_data["eleMult"] = nil
        end
        return result
    end
    return retval
end

-- 钩子：眩晕伤害倍率 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_adjust_total_stun_attack(retval)
    local derive_atk_data = derive.get_derive_atk_data()
    if derive_atk_data and derive_atk_data["stunMult"] ~= nil then
        local stunValue = sdk.to_float(retval)
        local result = sdk.float_to_ptr(stunValue * derive_atk_data["stunMult"][1])
        -- 应用后立即消耗次数，防止重复应用
        if derive_atk_data["stunMult"][2] > 1 then
            derive_atk_data["stunMult"][2] = derive_atk_data["stunMult"][2] - 1
        else
            derive_atk_data["stunMult"] = nil
        end
        return result
    end
    return retval
end

-- 钩子：耐力伤害倍率 - 后置处理
---@param retval any 返回值
---@return any 修改后的返回值
function derive.hook_post_adjust_total_stamina_attack(retval)
    local derive_atk_data = derive.get_derive_atk_data()
    if derive_atk_data and derive_atk_data["staMult"] ~= nil then
        local staValue = sdk.to_float(retval)
        local result = sdk.float_to_ptr(staValue * derive_atk_data["staMult"][1])
        -- 应用后立即消耗次数，防止重复应用
        if derive_atk_data["staMult"][2] > 1 then
            derive_atk_data["staMult"][2] = derive_atk_data["staMult"][2] - 1
        else
            derive_atk_data["staMult"] = nil
        end
        return result
    end
    return retval
end

return derive

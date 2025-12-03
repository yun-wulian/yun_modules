-- yun_modules/enemy.lua
-- 怪物相关功能模块

local enemy = {}

-- 硬直类型枚举
enemy.flinch_type = {
    MARIONETTE_FRIENDLY_FIRE = 0,   -- 操控友伤
    MARIONETTE_START = 1,            -- 操控开始
    PARTS_LOSS = 2,                  -- 部位丢失（超强硬直）
    FALL_TRAP = 3,                   -- 落穴陷阱
    SHOCK_TRAP = 4,                  -- 麻痹陷阱
    PARALYZE = 5,                    -- 麻痹
    SLEEP = 6,                       -- 睡眠
    STUN = 7,                        -- 击晕
    MARIONETTE_L = 8,                -- 大型操控
    FLASH = 9,                       -- 闪光
    SOUND = 10,                      -- 音波
    GIMMICK_L = 11,                  -- 大型机关
    EM2EM_L = 12,                    -- 大型怪物间伤害
    GIMMICK_KNOCKBACK = 13,          -- 机关击退（推荐使用）
    HIGH_PARTS = 14,                 -- 高位部位
    MARIONETTE_M = 15,               -- 中型操控
    GIMMICK_M = 16,                  -- 中型机关
    EM2EM_M = 17,                    -- 中型怪物间伤害
    MULTI_PARTS = 18,                -- 多部位
    ELEMENT_WEAK = 19,               -- 属性弱点
    PARTS_BREAK = 20,                -- 部位破坏（明显硬直）
    SLEEP_END = 21,                  -- 睡眠结束
    STAMINA = 22,                    -- 体力耗尽
    PARTS = 23,                      -- 普通部位硬直
    MARIONETTE_S = 24,               -- 小型操控
    GIMMICK_S = 25,                  -- 小型机关
    EM2EM_S = 26,                    -- 小型怪物间伤害
    STEEL_FANG = 27,                 -- 钢龙牙
    MYSTERY_MAXIMUM_ACTIVITY_RELEASE = 28,  -- 神秘最大活动释放
}

-- 备用硬直类型表（当主硬直类型不可用时使用）
-- 顺序：推荐类型 20, 13, 9, 10，然后是 9-25 范围内的其他类型
local FALLBACK_FLINCH_TYPES = {
    20,  -- 部位破坏（明显硬直）
    13,  -- 机关击退
    9,   -- 闪光
    10,  -- 音波
    12,  -- 大型怪物间伤害
    14,  -- 高位部位
    15,  -- 中型操控
    16,  -- 中型机关
    17,  -- 中型怪物间伤害
    18,  -- 多部位
    19,  -- 属性弱点
    22,  -- 体力耗尽
    23,  -- 普通部位硬直
    24,  -- 小型操控
    25,  -- 小型机关
}

--- 内部函数：尝试应用硬直（不含备用逻辑）
---@param enemy_instance userdata 怪物实例对象
---@param flinch_type number 硬直类型
---@param action_no number 动作编号
---@param damage_attr number 伤害属性
---@param timing number 执行时机
---@return boolean success 是否成功
---@return string|nil error_msg 错误信息（如果失败）
local function apply_flinch_internal(enemy_instance, flinch_type, action_no, damage_attr, timing)
    local success, error_msg = pcall(function()
        -- 获取类型定义并创建实例
        local type_def = sdk.find_type_definition("snow.enemy.EnemyDamageStockParam")
        if not type_def then
            error("无法找到 EnemyDamageStockParam 类型定义")
        end

        local stock = type_def:create_instance()
        if not stock then
            error("创建伤害参数对象失败")
        end

        -- 调用硬直方法
        enemy_instance:requestThinkInterrupt_Damage(
            flinch_type,  -- DamageCategory
            action_no,    -- 动作编号
            damage_attr,  -- 伤害属性
            stock,        -- 参数对象
            timing,       -- 执行时机
            nil,          -- 成功回调
            nil           -- 失败回调
        )
    end)

    if not success then
        return false, tostring(error_msg)
    end

    return true, nil
end

--- 给怪物设置硬直（支持自动备用硬直）
---@param enemy_instance userdata 怪物实例对象
---@param flinch_type number 硬直类型（参考 enemy.flinch_type 枚举）
---@param options table|nil 可选参数表 {damage_angle=0.0, original_damage=0.0, action_no=0, timing=0}
---@return boolean success 是否成功
---@return string|nil error_msg 错误信息（如果失败）
function enemy.set_flinch(enemy_instance, flinch_type, options)
    -- 参数检查：如果怪物实例为 nil，直接返回成功（不执行任何操作）
    -- 这种情况通常发生在远程攻击（shell）时，避免对错误的怪物触发硬直
    if not enemy_instance then
        return true, nil
    end

    if type(flinch_type) ~= "number" then
        return false, "硬直类型必须是数字"
    end

    -- 验证怪物实例有效性
    if not sdk.is_managed_object(enemy_instance) then
        return false, "怪物实例无效"
    end

    -- 默认选项
    local opts = options or {}
    local action_no = opts.action_no or 0
    local damage_attr = opts.damage_attr or 0
    local timing = opts.timing or 0  -- 0=Immediately, 1=ThinkTop, 2=ActionEnd

    -- 检查原始硬直类型是否可用
    local is_available = pcall(function()
        return enemy_instance:isEnableDamageCategory(flinch_type, 0)
    end)

    if is_available then
        local can_use = enemy_instance:isEnableDamageCategory(flinch_type, 0)
        if can_use then
            -- 原始硬直类型可用，直接应用
            return apply_flinch_internal(enemy_instance, flinch_type, action_no, damage_attr, timing)
        end
    end

    -- 原始硬直类型不可用，尝试备用类型
    for _, fallback_type in ipairs(FALLBACK_FLINCH_TYPES) do
        -- 跳过与原始类型相同的备用类型
        if fallback_type ~= flinch_type then
            local check_ok = pcall(function()
                return enemy_instance:isEnableDamageCategory(fallback_type, 0)
            end)

            if check_ok then
                local can_use_fallback = enemy_instance:isEnableDamageCategory(fallback_type, 0)
                if can_use_fallback then
                    -- 找到可用的备用硬直类型，应用它
                    return apply_flinch_internal(enemy_instance, fallback_type, action_no, damage_attr, timing)
                end
            end
        end
    end

    -- 所有备用类型都不可用
    return false, "怪物不支持任何可用的硬直类型"
end

--- 便捷函数：触发击退硬直
---@param enemy_instance userdata 怪物实例对象
---@return boolean success 是否成功
---@return string|nil error_msg 错误信息（如果失败）
function enemy.trigger_knockback(enemy_instance)
    return enemy.set_flinch(enemy_instance, enemy.flinch_type.GIMMICK_KNOCKBACK)
end

--- 便捷函数：触发部位破坏硬直
---@param enemy_instance userdata 怪物实例对象
---@return boolean success 是否成功
---@return string|nil error_msg 错误信息（如果失败）
function enemy.trigger_parts_break(enemy_instance)
    return enemy.set_flinch(enemy_instance, enemy.flinch_type.PARTS_BREAK)
end

--- 便捷函数：触发部位丢失硬直（超强）
---@param enemy_instance userdata 怪物实例对象
---@return boolean success 是否成功
---@return string|nil error_msg 错误信息（如果失败）
function enemy.trigger_parts_loss(enemy_instance)
    return enemy.set_flinch(enemy_instance, enemy.flinch_type.PARTS_LOSS)
end

return enemy

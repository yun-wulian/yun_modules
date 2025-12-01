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

--- 给怪物设置硬直
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

    -- 默认选项
    local opts = options or {}
    local action_no = opts.action_no or 0
    local damage_attr = opts.damage_attr or 0
    local timing = opts.timing or 0  -- 0=Immediately, 1=ThinkTop, 2=ActionEnd

    -- 使用 pcall 捕获错误
    local success, error_msg = pcall(function()
        -- 验证怪物实例有效性
        if not sdk.is_managed_object(enemy_instance) then
            error("怪物实例无效")
        end

        -- 获取类型定义并创建实例（推荐方式）
        local type_def = sdk.find_type_definition("snow.enemy.EnemyDamageStockParam")
        if not type_def then
            error("无法找到 EnemyDamageStockParam 类型定义")
        end

        local stock = type_def:create_instance()
        if not stock then
            error("创建伤害参数对象失败")
        end

        -- 不设置任何字段，使用默认值
        -- 经测试，在某些情况下（如远程攻击）设置字段会导致崩溃
        -- 默认值应该已经满足需求

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

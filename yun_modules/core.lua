-- yun_modules/core.lua
-- 核心变量和游戏数据管理

local core = {}

-- 武器类型枚举
core.weapon_type = {
    GreatSword = 0,      -- 大剑
    SlashAxe = 1,        -- 斩击斧
    LongSword = 2,       -- 太刀
    LightBowGun = 3,     -- 轻弩
    HeavyBowGun = 4,     -- 重弩
    Hammer = 5,          -- 锤
    GunLance = 6,        -- 铳枪
    Lance = 7,           -- 长枪
    ShortSword = 8,      -- 短剑
    DualBlade = 9,       -- 双剑
    Horn = 10,           -- 狩猎笛
    ChargeAxe = 11,      -- 充能斧
    InsectGlaive = 12,   -- 操虫棍
    Bow = 13             -- 弓
}

-- 方向枚举
core.direction = {
    Up = 0,              -- 上
    Down = 1,            -- 下
    Left = 2,            -- 左
    Right = 3,           -- 右
    RightUp = 4,         -- 右上
    RightDown = 5,       -- 右下
    LeftUp = 6,          -- 左上
    LeftDown = 7         -- 左下
}

-- 核心游戏对象单例
core.GuiManager = nil           -- GUI管理器
core.TimeScaleManager = nil     -- 时间缩放管理器
core.CameraManager = nil        -- 相机管理器
core.Pad = nil                  -- 手柄输入
core.PlayerManager = nil        -- 玩家管理器

-- 玩家状态变量
core.master_player = nil        -- 主玩家对象
core.master_player_index = nil  -- 主玩家索引
core.player_data = nil          -- 玩家数据
core.mPlObj = nil               -- 玩家游戏对象
core.mPlBHVT = nil              -- 玩家行为树
core.PlayerMotionCtrl = nil     -- 玩家动作控制

-- 动作状态变量
core._action_bank_id = nil      -- 动作库ID
core._action_id = nil           -- 当前动作ID
core._pre_action_id = nil       -- 前一个动作ID
core._pre_node_id = nil         -- 前一个节点ID
core._action_frame = nil        -- 当前动作帧
core._current_node = nil        -- 当前行为树节点
core._wep_type = nil            -- 武器类型
core._derive_start_frame = 0    -- 派生开始帧

-- 玩家属性
core._muteki_time = nil         -- 无敌时间
core._hyper_armor_time = nil    -- 霸体时间
core._atk = nil                 -- 攻击力
core._affinity = nil            -- 会心率
core._replace_atk_data = {}     -- 替换攻击数据

-- 动作值追踪
core._motion_value = nil                   -- 动作值
core._slash_axe_motion_value = 0           -- 斩击斧动作值
core._motion_value_id = nil                -- 动作值ID
core._slash_axe_motion_value_id = nil      -- 斩击斧动作值ID

-- 攻击/会心率覆盖
core.player_atk = nil           -- 玩家攻击力
core.player_affinity = nil      -- 玩家会心率
core.atk_flag = false           -- 攻击力修改标志
core.affinity_flag = false      -- 会心率修改标志

-- 游戏状态标志
core.is_in_quest = false        -- 是否在任务中
core.is_loading_visiable = false -- 是否显示加载界面
core._should_draw_ui = false    -- 是否绘制UI

-- 初始化单例
function core.init_singletons()
    core.GuiManager = sdk.get_managed_singleton('snow.gui.GuiManager')
    core.TimeScaleManager = sdk.get_managed_singleton('snow.TimeScaleManager')
    core.CameraManager = sdk.get_managed_singleton("snow.CameraManager")
    core.Pad = sdk.get_managed_singleton('snow.Pad')
    core.PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
end

-- 更新游戏数据（每帧调用）
function core.update_game_data()
    if not core.master_player then return end

    core.master_player_index = core.master_player:get_field("_PlayerIndex")
    core.mPlObj = core.master_player:call("get_GameObject")
    core.mPlBHVT = core.mPlObj:call("getComponent(System.Type)", sdk.typeof("via.behaviortree.BehaviorTree"))
    core.player_data = core.master_player:call("get_PlayerData")
    core._wep_type = core.master_player:get_field("_playerWeaponType")

    -- 更新UI标志（需要状态模块函数）
    -- core._should_draw_ui = enabled() and not is_pausing() and should_hud_show()

    core._atk = core.player_data:get_field("_Attack")

    if core._current_node ~= core.mPlBHVT:call("getCurrentNodeID", 0) then
        core._pre_node_id = core._current_node
        core._current_node = core.mPlBHVT:call("getCurrentNodeID", 0)
    end

    core._action_frame = core.master_player:call("getMotionLayer", 0):call("get_Frame")
    core._affinity = core.player_data:get_field("_CriticalRate")
    core._muteki_time = core.master_player:get_field("_MutekiTime")
    core._replace_atk_data = {
        core.master_player:get_field("_replaceAttackTypeA"),
        core.master_player:get_field("_replaceAttackTypeB"),
        core.master_player:get_field("_replaceAttackTypeC"),
        core.master_player:get_field("_replaceAttackTypeD"),
        core.master_player:get_field("_replaceAttackTypeE"),
        core.master_player:get_field("_replaceAttackTypeF")
    }
    core._hyper_armor_time = core.master_player:get_field("_HyperArmorTimer")
end

-- 查找并设置主玩家
---@return boolean 是否成功找到主玩家
function core.find_master_player()
    if not core.PlayerManager then
        core.PlayerManager = sdk.get_managed_singleton('snow.player.PlayerManager')
    end
    if not core.PlayerManager then return false end

    core.master_player = core.PlayerManager:call("findMasterPlayer")
    if not core.master_player or not core.master_player:isMasterPlayer() then
        core.master_player = nil
        return false
    end
    return true
end

return core
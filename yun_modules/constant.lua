-- yun_modules/constant.lua
-- 常量定义模块 - 集中管理所有枚举和常量

local constant = {}

-- ============================================================================
-- 武器类型枚举
-- ============================================================================

constant.weapon_type = {
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

-- ============================================================================
-- 方向枚举
-- ============================================================================

constant.direction = {
    Up = 0,              -- 上
    Down = 1,            -- 下
    Left = 2,            -- 左
    Right = 3,           -- 右
    RightUp = 4,         -- 右上
    RightDown = 5,       -- 右下
    LeftUp = 6,          -- 左上
    LeftDown = 7         -- 左下
}

-- ============================================================================
-- 硬直类型枚举
-- ============================================================================

constant.flinch_type = {
    MARIONETTE_FRIENDLY_FIRE = 0,    -- 操控友伤
    MARIONETTE_START = 1,            -- 操控开始
    PARTS_LOSS = 2,                  -- 断尾
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
constant.FALLBACK_FLINCH_TYPES = {
    20,  -- 部位破坏（明显硬直）
    13,  -- 机关击退
    9,   -- 闪光
    10,  -- 音波
    0,   -- 御龙友伤
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
    7,   -- 击晕
}

-- ============================================================================
-- 攻击判定状态枚举
-- ============================================================================

constant.on_action_status = {
    AttackActive = "AttackActive"  -- 攻击判定激活时（从initialize到destroy）
}

-- ============================================================================
-- 派生系统常量
-- ============================================================================

constant.derive = {
    DEFAULT_PRE_FRAME = 10.0,
    DEFAULT_DELAY_TIME = 0.083, -- 延迟等待时间（秒），约等于60fps下的5帧
}

-- ============================================================================
-- 派生类型枚举
-- ============================================================================

constant.derive_type = {
    NORMAL = "normal",        -- 普通派生（需要输入）
    HIT = "hit",             -- 命中派生
    COUNTER = "counter",     -- 反击派生
    AUTO = "auto"            -- 自动派生（无需输入）
}

-- ============================================================================
-- 玩家输入命令枚举 (snow.player.PlayerInput.Command)
-- 用于 isCmd 方法检测按键命令
-- 使用方式: constant.isCmd.AtkX, constant.isCmd.Escape 等
-- ============================================================================

constant.isCmd = {
    AtkX = 0,                        -- X攻击
    AtkA = 1,                        -- A攻击
    AtkXA = 2,                       -- X+A攻击
    AtkXR1 = 3,                      -- X+R1攻击
    AtkAR1 = 4,                      -- A+R1攻击
    AtkXAR1 = 5,                     -- X+A+R1攻击
    AtkR2 = 6,                       -- R2攻击
    AtkR2On = 7,                     -- R2按住
    AtkR2Off = 8,                    -- R2释放
    AtkR1Release = 9,                -- R1释放
    AtkR2Release = 10,               -- R2释放
    AtkXOn = 11,                     -- X按住
    AtkAOn = 12,                     -- A按住
    AtkXOff = 13,                    -- X松开
    AtkAOff = 14,                    -- A松开
    AtkXRelease = 15,                -- X释放
    AtkARelease = 16,                -- A释放
    WpStart = 17,                    -- 武器开始
    WpEnd = 18,                      -- 武器结束
    Escape = 19,                     -- 回避
    EscapeR = 20,                    -- 右回避
    EscapeL = 21,                    -- 左回避
    EscapeF = 22,                    -- 前回避
    EscapeB = 23,                    -- 后回避
    AtkR1 = 24,                      -- R1攻击
    Dash = 25,                       -- 冲刺
    Guard = 26,                      -- 防御
    Sit = 27,                        -- 坐下
    WpStartXAR = 28,                 -- 武器开始XAR
    Ride = 29,                       -- 骑乘
    Tsuta = 30,                      -- 藤蔓
    TsutaEnd = 31,                   -- 藤蔓结束
    TsutaDash = 32,                  -- 藤蔓冲刺
    WireUp = 33,                     -- 翔虫向上
    WireFront = 34,                  -- 翔虫向前
    WireTarget = 35,                 -- 翔虫瞄准
    WireStopEnd = 36,                -- 翔虫停止结束
    WireEscape = 37,                 -- 翔虫回避
    WireUpGunner = 38,               -- 翔虫向上（枪手）
    WireFrontGunner = 39,            -- 翔虫向前（枪手）
    PopAction = 40,                  -- 弹出动作
    GimmickPopAction = 41,           -- 机关弹出动作
    GimmickCancel = 42,              -- 机关取消
    NpcFacilityPopAction = 43,       -- NPC设施弹出动作
    LongJump = 44,                   -- 长跳
    ItemPopAction = 45,              -- 物品弹出动作
    EnvCreaturePopAction = 46,       -- 环境生物弹出动作
    AtkR1Delay = 47,                 -- R1延迟攻击
    AtkAwithoutR1 = 48,              -- A攻击（无R1）
    AtkXwithoutR1 = 49,              -- X攻击（无R1）
    AtkXAwithoutR1 = 50,             -- X+A攻击（无R1）
    AtkXorA = 51,                    -- X或A攻击
    AtkXwithoutA = 52,               -- X攻击（无A）
    AtkAwithoutX = 53,               -- A攻击（无X）
    AtkXwithoutAandR1 = 54,          -- X攻击（无A和R1）
    AtkAwithoutXandR1 = 55,          -- A攻击（无X和R1）
    ItemY = 56,                      -- Y物品
    ItemYOn = 57,                    -- Y物品按住
    ItemYOff = 58,                   -- Y物品松开
    KunaiAimZLOn = 59,               -- 苦无瞄准ZL按住
    RideDriftOn = 60,                -- 骑乘漂移按住
    RideDriftOff = 61,               -- 骑乘漂移松开
    RideJump = 62,                   -- 骑乘跳跃
    SlidingJump = 63,                -- 滑行跳跃
    Marionette = 64,                 -- 御龙
    AnyTrigger = 65,                 -- 任意触发
    OtomoPopAction = 66,             -- 随从弹出动作
    AtkRB = 67,                      -- RB攻击
    HagitoriPopAction = 68,          -- 剥取弹出动作
    TrapRemovePopAction = 69,        -- 陷阱移除弹出动作
    LongJumpPointRelease = 70,       -- 长跳点释放
    AtkBNoDelay = 71,                -- B攻击（无延迟）
    AtkBOff = 72,                    -- B松开
    AtkXAOn = 73,                    -- X+A按住
    AtkR1ZL = 74,                    -- R1+ZL攻击
    OtomoCommunicationStart = 75,    -- 随从交流开始
    OtomoCommunicationA = 76,        -- 随从交流A
    OtomoCommunicationB = 77,        -- 随从交流B
    OtomoCommunicationX = 78,        -- 随从交流X
    OtomoCommunicationY = 79,        -- 随从交流Y
    AtkR1ZR = 80,                    -- R1+ZR攻击
    AtkR1Off = 81,                   -- R1松开
    AtkXInclude = 82,                -- X攻击（包含）
    AtkAInclude = 83,                -- A攻击（包含）
    DeliveryPopAction = 84,          -- 交付弹出动作
    Fishing = 85,                    -- 钓鱼
    DropEnvCreature = 86,            -- 放下环境生物
    Decide = 87,                     -- 确定
    Cancel = 88,                     -- 取消
    AtkR1On = 89,                    -- R1按住
    AtkZLB = 90,                     -- ZL+B攻击
    Marionette_AtkA = 91,            -- 御龙A攻击
    Marionette_AtkX = 92,            -- 御龙X攻击
    Marionette_AtkXA = 93,           -- 御龙X+A攻击
    Marionette_Escape = 94,          -- 御龙回避
    Marionette_FreeRun = 95,         -- 御龙自由移动
    Marionette_Separation = 96,      -- 御龙分离
    BowEscape = 97,                  -- 弓回避
    BowChangeBottle = 98,            -- 弓更换瓶
    BowReadyShot = 99,               -- 弓准备射击
    BowFireShot = 100,               -- 弓射击
    BowFireShotTrg = 101,            -- 弓射击触发
    BowDragonShot = 102,             -- 弓龙之一矢
    BowComboArrowAtk = 103,          -- 弓连段箭攻击
    BowAtkA = 104,                   -- 弓A攻击
    BowAtkAOn = 105,                 -- 弓A按住
    BowAtkARelease = 106,            -- 弓A释放
    BowWireUpReadyBow = 107,         -- 弓翔虫向上准备
    BowWireFrontReadyBow = 108,      -- 弓翔虫向前准备
    BowgunShotTrg = 109,             -- 弩射击触发
    BowgunShotOn = 110,              -- 弩射击按住
    BowgunShotOnWithoutStrike = 111, -- 弩射击按住（无近战）
    BowgunShotOff = 112,             -- 弩射击松开
    BowgunSpecialBullet = 113,       -- 弩特殊弹
    BowgunReload = 114,              -- 弩装填
    BowgunReloadWithoutA = 115,      -- 弩装填（无A）
    BowgunStrike = 116,              -- 弩近战
    BowgunFlyAtkX = 117,             -- 弩飞行X攻击
    BowgunContinueReload = 118,      -- 弩连续装填
    BowgunShotOnDelay = 119,         -- 弩射击按住（延迟）
    WireUpReadyHeavy = 120,          -- 翔虫向上准备（重弩）
    WireFrontReadyHeavy = 121,       -- 翔虫向前准备（重弩）
    RideDash = 122,                  -- 骑乘冲刺
    ActionStart = 123,               -- 动作开始
    ActionEnd = 124,                 -- 动作结束
    ItemTake = 125,                  -- 拾取物品
    AtkXAR1_ZR = 126,                -- X+A+R1+ZR攻击
    AtkXAorR1 = 127,                 -- X+A或R1攻击
    Gimmick_Hold = 128,              -- 机关持有
    Gimmick_HoldCancel = 129,        -- 机关持有取消
    GatlingGunShotEnd = 130,         -- 加特林射击结束
    GimmickShotTrg_AorZR = 131,      -- 机关射击触发（A或ZR）
    GimmickShotTrg_X = 132,          -- 机关射击触发（X）
    GimmickShotTrg_Y = 133,          -- 机关射击触发（Y）
    GimmickShotOn_AorZR = 134,       -- 机关射击按住（A或ZR）
    GimmickShotOn_X = 135,           -- 机关射击按住（X）
    GimmickShotOn_Y = 136,           -- 机关射击按住（Y）
    AtkXAorR1Trg = 137,              -- X+A或R1触发
    GuardTrg = 138,                  -- 防御触发
    AtkZRZL = 139,                   -- ZR+ZL攻击
    AtkXOriginal = 140,              -- X原始攻击
    AtkXOnOriginal = 141,            -- X按住原始
    AtkAOnOriginal = 142,            -- A按住原始
    PopActionOn = 143,               -- 弹出动作按住
    AtkXAR1_NoCheckZL = 144,         -- X+A+R1攻击（不检查ZL）
    CancelNoDelay = 145,             -- 取消（无延迟）
    WallRunFromMove = 146,           -- 从移动开始跑墙
    WireUtsusemi = 147,              -- 翔虫替身
    WireUp_L2Release = 148,          -- 翔虫向上（L2释放）
    WireUtsusemiOn = 149,            -- 翔虫替身按住
    WireUtsusemiGunner = 150,        -- 翔虫替身（枪手）
    HeavyBowgunFullAutoStart = 151,  -- 重弩全自动开始
    HeavyBowgunShotRelease = 152,    -- 重弩射击释放
    AtkZRZLRelease = 153,            -- ZR+ZL释放
    BowWireChangeSlashShot = 154,    -- 弓翔虫斩击射击切换
    BowWireChangeSlashEscape = 155,  -- 弓翔虫斩击回避切换
    OtomoReconSpotRelease = 156,     -- 随从侦察点释放
    ServantHelpUp = 157,             -- 随从帮助起身
    OtomoCommunicationR = 158,       -- 随从交流R
    DogRelease = 159,                -- 牙猎犬释放
    IaiRelease = 160,                -- 居合释放
    Max = 161,                       -- 最大值
}

-- ============================================================================
-- 玩家输入按钮枚举 (snow.player.PlayerInput.CommandButton2)
-- 用于 isOn 方法检测按键状态（按住检测）
-- 使用方式: constant.isOn.Atk_X, constant.isOn.Guard 等
-- ============================================================================

constant.isOn = {
    Atk_X = 0,                       -- X攻击
    Atk_A = 1,                       -- A攻击
    Atk_R1 = 2,                      -- R1攻击
    Escape = 3,                      -- 回避
    Guard = 4,                       -- 防御
    Dash = 5,                        -- 冲刺
    Item = 6,                        -- 物品
    PopAction = 7,                   -- 弹出动作
    ZL = 8,                          -- ZL
    ZR = 9,                          -- ZR
    OtomoY = 10,                     -- 随从Y
    OtomoX = 11,                     -- 随从X
    OtomoA = 12,                     -- 随从A
    Decide = 13,                     -- 确定
    Cancel = 14,                     -- 取消
    GachaButton = 15,                -- 抽奖按钮
    OtomoR = 16,                     -- 随从R
    OtomoR_Toggle = 17,              -- 随从R切换
    Move_U = 18,                     -- 移动上
    Move_D = 19,                     -- 移动下
    Move_L = 20,                     -- 移动左
    Move_R = 21,                     -- 移动右
    Marionette_X = 22,               -- 御龙X
    Marionette_A = 23,               -- 御龙A
    Marionette_B = 24,               -- 御龙B
    Marionette_FreeRun = 25,         -- 御龙自由移动
    Marionette_Separation = 26,      -- 御龙分离
    Camera_U = 27,                   -- 相机上
    Camera_D = 28,                   -- 相机下
    Camera_L = 29,                   -- 相机左
    Camera_R = 30,                   -- 相机右
    CameraReset = 31,                -- 相机重置
    TargetCamera = 32,               -- 目标相机
    Atk_X_A = 33,                    -- X+A攻击
    Atk_X_RT = 34,                   -- X+RT攻击
    Atk_A_RT = 35,                   -- A+RT攻击
    Atk_Y_RT = 36,                   -- Y+RT攻击
    Atk_X_A_RT = 37,                 -- X+A+RT攻击
    Atk_X_ZL = 38,                   -- X+ZL攻击
    Atk_A_ZL = 39,                   -- A+ZL攻击
    Atk_R_X = 40,                    -- R+X攻击
    Atk_R_A = 41,                    -- R+A攻击
    Guard_Escape = 42,               -- 防御回避
    Atk_X_A_LT = 43,                 -- X+A+LT攻击
    Atk_X_A_R = 44,                  -- X+A+R攻击
    Aim = 45,                        -- 瞄准
    DashToggle = 46,                 -- 冲刺切换
    Menu = 47,                       -- 菜单
    Drift = 48,                      -- 漂移
    DogAtk_X = 49,                   -- 牙猎犬X攻击
    DogJump = 50,                    -- 牙猎犬跳跃
    DogRelease = 51,                 -- 牙猎犬释放
    Atk_B_ZL = 52,                   -- B+ZL攻击
    OtomoB = 53,                     -- 随从B
    InstallationsUniqueShot = 54,    -- 设施特殊射击
    InstallationsGuard = 55,         -- 设施防御
}

-- ============================================================================
-- FSM命令枚举 (snow.player.fsm.FsmCommandBase.CommandFsm)
-- 用于 needIgnoreOriginalKey 字段屏蔽原始按键命令
-- 使用方式: constant.commandFsm.AtkX, constant.commandFsm.Escape 等
-- ============================================================================

constant.commandFsm = {
    None = 0,                        -- 无
    AtkA = 1,                        -- A攻击
    AtkX = 2,                        -- X攻击
    AtkXorA = 3,                     -- X或A攻击
    AtkXA = 4,                       -- X+A攻击
    AtkAR1 = 5,                      -- A+R1攻击
    AtkXR1 = 6,                      -- X+R1攻击
    AtkXAR1 = 7,                     -- X+A+R1攻击
    AtkR1 = 8,                       -- R1攻击
    AtkR2 = 9,                       -- R2攻击
    AtkR2On = 10,                    -- R2按住
    AtkR2Off = 11,                   -- R2释放
    AtkR1Release = 12,               -- R1释放
    AtkR2Release = 13,               -- R2释放
    AtkAOn = 14,                     -- A按住
    AtkXOn = 15,                     -- X按住
    AtkXAOn = 16,                    -- X+A按住
    AtkAOff = 17,                    -- A松开
    AtkXOff = 18,                    -- X松开
    AtkARelease = 19,                -- A释放
    AtkXRelease = 20,                -- X释放
    WpStart = 21,                    -- 武器开始
    WpStartXAR = 22,                 -- 武器开始XAR
    WpEnd = 23,                      -- 武器结束
    Escape = 24,                     -- 回避
    EscapeR = 25,                    -- 右回避
    EscapeL = 26,                    -- 左回避
    EscapeF = 27,                    -- 前回避
    EscapeB = 28,                    -- 后回避
    EscapeAnalogl = 29,              -- 摇杆回避
    Dash = 30,                       -- 冲刺
    Guard = 31,                      -- 防御
    Sit = 32,                        -- 坐下
    Ride = 33,                       -- 骑乘
    Tsuta = 34,                      -- 藤蔓
    TsutaEnd = 35,                   -- 藤蔓结束
    TsutaDash = 36,                  -- 藤蔓冲刺
    WireUp = 37,                     -- 翔虫向上
    WireFront = 38,                  -- 翔虫向前
    WireTarget = 39,                 -- 翔虫瞄准
    WireStopEnd = 40,                -- 翔虫停止结束
    WireEscape = 41,                 -- 翔虫回避
    WireUpGunner = 42,               -- 翔虫向上（枪手）
    WireFrontGunner = 43,            -- 翔虫向前（枪手）
    PopAction = 44,                  -- 弹出动作
    GimmickPopAction = 45,           -- 机关弹出动作
    GimmickCancel = 46,              -- 机关取消
    NpcFacilityPopAction = 47,       -- NPC设施弹出动作
    LongJump = 48,                   -- 长跳
    EnvCreaturePopAction = 49,       -- 环境生物弹出动作
    ItemPopAction = 50,              -- 物品弹出动作
    AtkR1Delay = 51,                 -- R1延迟攻击
    AtkAwithoutR1 = 52,              -- A攻击（无R1）
    AtkXwithoutR1 = 53,              -- X攻击（无R1）
    AtkXAwithoutR1 = 54,             -- X+A攻击（无R1）
    AtkAwithoutX = 55,               -- A攻击（无X）
    AtkXwithoutA = 56,               -- X攻击（无A）
    AtkAwithoutXandR1 = 57,          -- A攻击（无X和R1）
    AtkXwithoutAandR1 = 58,          -- X攻击（无A和R1）
    AtkAxislRightX = 59,             -- 轴向右X攻击
    AtkAxislLeftX = 60,              -- 轴向左X攻击
    AtkAxislFrontX = 61,             -- 轴向前X攻击
    AtkAxislBackX = 62,              -- 轴向后X攻击
    AtkAxislFrontOrNeutralX = 63,    -- 轴向前或中立X攻击
    AtkAxislLRF3WayRightX = 64,      -- 左右前三向右X攻击
    AtkAxislLRF3WayLeftX = 65,       -- 左右前三向左X攻击
    AtkAxislLRF3WayFrontX = 66,      -- 左右前三向前X攻击
    AtkAxislLRB3WayRightX = 67,      -- 左右后三向右X攻击
    AtkAxislLRB3WayLeftX = 68,       -- 左右后三向左X攻击
    AtkAxislLRB3WayBackX = 69,       -- 左右后三向后X攻击
    AtkAxislFB2WayFrontX = 70,       -- 前后二向前X攻击
    AtkAxislFB2WayBackX = 71,        -- 前后二向后X攻击
    AtkAxislLR2WayRightX = 72,       -- 左右二向右X攻击
    AtkAxislLR2WayLeftX = 73,        -- 左右二向左X攻击
    AtkAnaloglUpX = 74,              -- 摇杆上X攻击
    AtkAnaloglDownX = 75,            -- 摇杆下X攻击
    AtkAnaloglLeftX = 76,            -- 摇杆左X攻击
    AtkAnaloglRightX = 77,           -- 摇杆右X攻击
    AtkAxislRightA = 78,             -- 轴向右A攻击
    AtkAxislLeftA = 79,              -- 轴向左A攻击
    AtkAxislFrontA = 80,             -- 轴向前A攻击
    AtkAxislBackA = 81,              -- 轴向后A攻击
    AtkAxislLRF3WayRightA = 82,      -- 左右前三向右A攻击
    AtkAxislLRF3WayLeftA = 83,       -- 左右前三向左A攻击
    AtkAxislLRF3WayFrontA = 84,      -- 左右前三向前A攻击
    AtkAxislLRB3WayRightA = 85,      -- 左右后三向右A攻击
    AtkAxislLRB3WayLeftA = 86,       -- 左右后三向左A攻击
    AtkAxislLRB3WayBackA = 87,       -- 左右后三向后A攻击
    AtkAxislFB2WayFrontA = 88,       -- 前后二向前A攻击
    AtkAxislFB2WayFrontOrNeutralA = 89,  -- 前后二向前或中立A攻击
    AtkAxislFB2WayBackA = 90,        -- 前后二向后A攻击
    AtkAxislLR2WayRightA = 91,       -- 左右二向右A攻击
    AtkAxislLR2WayLeftA = 92,        -- 左右二向左A攻击
    AtkAnaloglUpA = 93,              -- 摇杆上A攻击
    AtkAnaloglDownA = 94,            -- 摇杆下A攻击
    AtkAnaloglLeftA = 95,            -- 摇杆左A攻击
    AtkAnaloglRightA = 96,           -- 摇杆右A攻击
    AtkAxislRightXA = 97,            -- 轴向右X+A攻击
    AtkAxislLeftXA = 98,             -- 轴向左X+A攻击
    AtkAxislFrontXA = 99,            -- 轴向前X+A攻击
    AtkAxislBackXA = 100,            -- 轴向后X+A攻击
    AtkAxislLRF3WayRightXA = 101,    -- 左右前三向右X+A攻击
    AtkAxislLRF3WayLeftXA = 102,     -- 左右前三向左X+A攻击
    AtkAxislLRF3WayFrontXA = 103,    -- 左右前三向前X+A攻击
    AtkAxislLRB3WayRightXA = 104,    -- 左右后三向右X+A攻击
    AtkAxislLRB3WayLeftXA = 105,     -- 左右后三向左X+A攻击
    AtkAxislLRB3WayBackXA = 106,     -- 左右后三向后X+A攻击
    AtkAxislFB2WayFrontXA = 107,     -- 前后二向前X+A攻击
    AtkAxislFB2WayBackXA = 108,      -- 前后二向后X+A攻击
    AtkAxislLR2WayRightXA = 109,     -- 左右二向右X+A攻击
    AtkAxislLR2WayLeftXA = 110,      -- 左右二向左X+A攻击
    AtkAnaloglUpXA = 111,            -- 摇杆上X+A攻击
    AtkAnaloglDownXA = 112,          -- 摇杆下X+A攻击
    AtkAnaloglLeftXA = 113,          -- 摇杆左X+A攻击
    AtkAnaloglRightXA = 114,         -- 摇杆右X+A攻击
    AtkAxislRightR1 = 115,           -- 轴向右R1攻击
    AtkAxislLeftR1 = 116,            -- 轴向左R1攻击
    AtkAxislFrontR1 = 117,           -- 轴向前R1攻击
    AtkAxislBackR1 = 118,            -- 轴向后R1攻击
    AtkAxislLRF3WayRightR1 = 119,    -- 左右前三向右R1攻击
    AtkAxislLRF3WayLeftR1 = 120,     -- 左右前三向左R1攻击
    AtkAxislLRF3WayFrontR1 = 121,    -- 左右前三向前R1攻击
    AtkAxislLRB3WayRightR1 = 122,    -- 左右后三向右R1攻击
    AtkAxislLRB3WayLeftR1 = 123,     -- 左右后三向左R1攻击
    AtkAxislLRB3WayBackR1 = 124,     -- 左右后三向后R1攻击
    AtkAxislFB2WayFrontR1 = 125,     -- 前后二向前R1攻击
    AtkAxislFB2WayBackR1 = 126,      -- 前后二向后R1攻击
    AtkAxislLR2WayRightR1 = 127,     -- 左右二向右R1攻击
    AtkAxislLR2WayLeftR1 = 128,      -- 左右二向左R1攻击
    AtkAnaloglUpR1 = 129,            -- 摇杆上R1攻击
    AtkAnaloglDownR1 = 130,          -- 摇杆下R1攻击
    AtkAnaloglLeftR1 = 131,          -- 摇杆左R1攻击
    AtkAnaloglRightR1 = 132,         -- 摇杆右R1攻击
    AtkAxislRightXR1 = 133,          -- 轴向右X+R1攻击
    AtkAxislLeftXR1 = 134,           -- 轴向左X+R1攻击
    AtkAxislFrontXR1 = 135,          -- 轴向前X+R1攻击
    AtkAxislBackXR1 = 136,           -- 轴向后X+R1攻击
    AtkAnaloglXA = 137,              -- 摇杆X+A攻击
    AtkAnaloglA = 138,               -- 摇杆A攻击
    AtkAnaloglX = 139,               -- 摇杆X攻击
    AtkAnaloglR1 = 140,              -- 摇杆R1攻击
    AtkNeutralXA = 141,              -- 中立X+A攻击
    AtkNeutralA = 142,               -- 中立A攻击
    AtkNeutralX = 143,               -- 中立X攻击
    AtkNeutralR1 = 144,              -- 中立R1攻击
    ItemY = 145,                     -- Y物品
    ItemYOn = 146,                   -- Y物品按住
    ItemYOff = 147,                  -- Y物品松开
    KunaiAimZLOn = 148,              -- 苦无瞄准ZL按住
    RideDriftOn = 149,               -- 骑乘漂移按住
    RideDriftOff = 150,              -- 骑乘漂移松开
    RideJump = 151,                  -- 骑乘跳跃
    SlidingJump = 152,               -- 滑行跳跃
    Marionette = 153,                -- 御龙
    OtomoPopAction = 154,            -- 随从弹出动作
    AtkRB = 155,                     -- RB攻击
    HagitoriPopAction = 156,         -- 剥取弹出动作
    TrapRemovePopAction = 157,       -- 陷阱移除弹出动作
    LongJumpPointRelease = 158,      -- 长跳点释放
    Fishing = 159,                   -- 钓鱼
    DropEnvCreature = 160,           -- 放下环境生物
    AnyTrigger = 161,                -- 任意触发
    OtomoCommunicationStart = 162,   -- 随从交流开始
    OtomoCommunicationA = 163,       -- 随从交流A
    OtomoCommunicationB = 164,       -- 随从交流B
    OtomoCommunicationX = 165,       -- 随从交流X
    OtomoCommunicationY = 166,       -- 随从交流Y
    AtkR1ZR = 167,                   -- R1+ZR攻击
    AtkR1Off = 168,                  -- R1松开
    LobbyWireUp = 169,               -- 大厅翔虫向上
    LobbyWireFront = 170,            -- 大厅翔虫向前
    LobbyWireTarget = 171,           -- 大厅翔虫瞄准
    Decide = 172,                    -- 确定
    Cancel = 173,                    -- 取消
    AtkR1On = 174,                   -- R1按住
    Gimmick_Hold = 175,              -- 机关持有
    Gimmick_HoldCancel = 176,        -- 机关持有取消
    ActionStart = 177,               -- 动作开始
    ActionEnd = 178,                 -- 动作结束
    ItemTake = 179,                  -- 拾取物品
    AtkXAR1_ZR = 180,                -- X+A+R1+ZR攻击
    AtkXAorR1 = 181,                 -- X+A或R1攻击
    GimmickShotTrg_AorZR = 182,      -- 机关射击触发（A或ZR）
    GimmickShotTrg_X = 183,          -- 机关射击触发（X）
    GimmickShotTrg_Y = 184,          -- 机关射击触发（Y）
    GimmickShotOn_AorZR = 185,       -- 机关射击按住（A或ZR）
    GimmickShotOn_X = 186,           -- 机关射击按住（X）
    GimmickShotOn_Y = 187,           -- 机关射击按住（Y）
    AtkXAorR1Trg = 188,              -- X+A或R1触发
    GuardTrg = 189,                  -- 防御触发
    AtkZRZL = 190,                   -- ZR+ZL攻击
    AtkXOnOriginal = 191,            -- X按住原始
    AtkAOnOriginal = 192,            -- A按住原始
    PopActionOn = 193,               -- 弹出动作按住
    ActionB = 194,                   -- B动作
    CancelNoDelay = 195,             -- 取消（无延迟）
    WireUtsusemi = 196,              -- 翔虫替身
    WireUp_L2Release = 197,          -- 翔虫向上（L2释放）
    WireUtsusemiOn = 198,            -- 翔虫替身按住
    WireUtsusemiGunner = 199,        -- 翔虫替身（枪手）
    OtomoReconSpotRelease = 200,     -- 随从侦察点释放
    ServantHelpUp = 201,             -- 随从帮助起身
    OtomoCommunicationR = 202,       -- 随从交流R
    DogRelease = 203,                -- 牙猎犬释放
    IaiRelease = 204,                -- 居合释放
}

return constant

# YUN_MODULES 模块化重构说明

## 概述

yun_modules已经被重构为模块化架构，将原来的单一大文件拆分为多个独立的子模块。**所有现有的MOD调用接口保持不变**，无需修改任何代码即可兼容。

## 模块结构

```
yunwulian/
├── yun_modules.lua          # 主入口文件（聚合器）
├── yun_modules.lua.bak      # 原文件备份
└── yun_modules/             # 子模块目录
    ├── core.lua             # 核心变量和游戏数据管理
    ├── utils.lua            # 工具函数（表格操作、深拷贝等）
    ├── player.lua           # 玩家相关功能
    ├── action.lua           # 动作和帧控制
    ├── input.lua            # 输入检测（摇杆、按键）
    ├── state.lua            # 游戏状态检测
    ├── effects.lua          # 特效和震动效果
    ├── derive.lua           # 派生系统（核心功能）
    ├── hooks.lua            # SDK钩子管理
    └── ui.lua               # 调试UI界面
```

## 模块职责

### core.lua - 核心模块
- 武器类型和方向枚举定义
- 游戏对象单例管理（GuiManager, TimeScaleManager等）
- 玩家状态变量（动作ID、帧数、攻击力等）
- 核心数据更新函数

### utils.lua - 工具模块
- `tableToString()` - 表格转字符串
- `deepCopy()` - 深拷贝函数
- `isFrameInRange()` - 帧数范围检测
- ImGui和re.msg的表格打印函数

### player.lua - 玩家模块
- 时间函数（get_time, get_delta_time）
- 玩家速度控制（timescale）
- 攻击力和暴击率控制
- 无敌时间和霸体时间
- 体力值管理
- 替换技和技能检测

### action.lua - 动作模块
- 动作ID和帧数获取
- 动作切换回调管理
- 节点控制（set_current_node）
- 动作值（Motion Value）获取
- 动作范围检测

### input.lua - 输入模块
- 摇杆推动检测
- 摇杆方向判断（相机方向/角色方向）
- 按键检测（isOn/isCmd）
- 角色转向控制

### state.lua - 状态模块
- 任务状态检测（is_in_quest）
- 暂停状态检测
- HUD显示状态
- 加载界面检测
- 任务切换回调管理

### effects.lua - 特效模块
- 特效生成（set_effect）
- 相机震动（set_camera_vibration）
- 手柄震动（set_pad_vibration）

### derive.lua - 派生模块
- 派生表管理（push_derive_table）
- 派生条件检测和执行
- 攻击倍率控制（atk/ele/stun/sta）
- 当身和命中派生
- 动作速度控制
- 翔虫消耗管理

### hooks.lua - 钩子模块
- 所有SDK钩子的初始化和管理
- 动作切换钩子
- 攻击力/暴击率钩子
- 伤害倍率钩子
- 按键评估钩子
- 命中检测钩子

### ui.lua - UI模块
- 调试界面绘制
- 武器和动作信息显示
- 震动测试工具
- 派生数据显示

## 向后兼容性

**所有现有的API调用方式完全不变！**

原来的调用方式：
```lua
local yun = require("yun_modules")

-- 所有这些调用方式都完全兼容
local action_id = yun.get_action_id()
local frame = yun.get_now_action_frame()
yun.push_derive_table(my_derive_table)
yun.set_atk(500)
-- ... 等等
```

## 优势

1. **代码组织清晰** - 每个模块职责单一，易于理解和维护
2. **易于扩展** - 需要添加新功能时只需修改对应模块
3. **便于调试** - 问题定位更准确，可以快速找到相关代码
4. **降低耦合** - 模块之间依赖关系清晰
5. **完全兼容** - 无需修改任何现有MOD代码

## 如何使用新模块开发

如果你想直接使用某个子模块（例如在新的MOD开发中）：

```lua
-- 方式1：使用主入口（推荐，保持兼容性）
local yun = require("yunwulian.yun_modules")
yun.get_action_id()

-- 方式2：直接使用子模块（高级用法）
local player = require("yunwulian.yun_modules.player")
local action = require("yunwulian.yun_modules.action")
local derive = require("yunwulian.yun_modules.derive")

player.get_atk()
action.get_action_id()
derive.push_derive_table(my_table)
```

## 恢复原文件

如果需要恢复到原始单文件版本：

```bash
# 删除新的模块化版本
rm yun_modules.lua
rm -rf yun_modules/

# 恢复备份
mv yun_modules.lua.bak yun_modules.lua
```

## 注意事项

1. 模块之间通过require导入，路径格式为 `yunwulian.yun_modules.xxx`
2. 全局变量（sdk, re, imgui）由REFramework环境提供
3. 调试UI中的某些警告（undefined-global）是正常的，不影响运行
4. 原始备份文件保存在 `yun_modules.lua.bak`

## 开发建议

- 修改功能时，找到对应的模块文件进行修改
- 添加新功能时，选择合适的模块或创建新模块
- 测试时确保现有MOD仍然正常工作
- 保持主入口文件（yun_modules.lua）简洁，只做API聚合

## 技术支持

如果遇到问题：
1. 检查是否所有模块文件都存在于yun_modules目录
2. 确认require路径格式正确（yunwulian.yun_modules.core）
3. 查看REFramework日志获取详细错误信息
4. 如有需要可恢复原始文件进行对比测试

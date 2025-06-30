# 游戏配置集中化优化

**创建时间**: 2025-06-30  
**优化类型**: 代码结构优化  
**影响范围**: 全局配置管理  
**优化状态**: ✅ 已完成

## 📋 优化概述

将游戏中分散的时间配置参数集中到统一的配置文件中，提高代码的可维护性和一致性。

## 🎯 优化目标

1. **集中管理配置**: 将所有游戏时间参数集中到一个配置文件
2. **提高可维护性**: 便于调整游戏平衡性和进行调试
3. **保持原游戏一致性**: 确保时间配置与原游戏完全一致
4. **支持调试模式**: 提供快速调试的时间配置

## 🔍 原游戏时间配置分析

### Room.js (房间模块)
```javascript
_STOKE_COOLDOWN: 10,                    // 添柴冷却时间：10秒
_FIRE_COOL_DELAY: 5 * 60 * 1000,       // 火焰冷却延迟：5分钟
_ROOM_WARM_DELAY: 30 * 1000,           // 房间温度更新：30秒
_BUILDER_STATE_DELAY: 0.5 * 60 * 1000, // 建造者状态更新：30秒
_NEED_WOOD_DELAY: 15 * 1000,           // 需要木材提示：15秒
```

### Outside.js (外部模块)
```javascript
_GATHER_DELAY: 60,    // 伐木延迟：60秒
_TRAPS_DELAY: 90,     // 查看陷阱延迟：90秒
_POP_DELAY: [0.5, 3], // 人口增长延迟：0.5-3分钟
_HUT_ROOM: 4,         // 每个小屋容纳人数：4人
```

## 🛠️ 实施方案

### 1. 创建配置文件

创建 `lib/config/game_config.dart` 文件，包含：

- **房间模块配置**: 火焰、温度、建造者相关时间
- **外部模块配置**: 伐木、陷阱、人口相关时间  
- **事件模块配置**: 事件触发、战斗相关时间
- **世界地图配置**: 移动、战斗、治疗相关参数
- **太空模块配置**: 飞船、小行星相关参数
- **UI配置**: 进度条动画时间
- **调试配置**: 快速调试模式的时间设置

### 2. 配置文件特性

```dart
class GameConfig {
  // 基础配置常量
  static const int stokeFireCooldown = 10;
  static const int fireCoolDelay = 5 * 60 * 1000;
  
  // 调试模式支持
  static const bool debugMode = false;
  static const int debugStokeCooldown = 0;
  
  // 动态配置获取
  static int getCurrentStokeCooldown() {
    return debugMode ? debugStokeCooldown : stokeFireCooldown;
  }
}
```

### 3. 模块更新

#### Room模块更新
```dart
// 原代码
static const int _fireCoolDelay = 5 * 60 * 1000;

// 更新后
static int get _fireCoolDelay => GameConfig.fireCoolDelay;
```

#### Outside模块更新
```dart
// 原代码
// static const int _gatherDelay = 60;

// 更新后
static int get _gatherDelay => GameConfig.getCurrentGatherDelay();
```

#### UI组件更新
```dart
// 原代码
progressDuration: 10000, // 10秒点火时间

// 更新后
progressDuration: GameConfig.lightFireProgressDuration,
```

## 📊 配置对照表

| 功能 | 原游戏时间 | Flutter配置 | 说明 |
|------|------------|--------------|------|
| 添柴冷却 | 10秒 | `stokeFireCooldown: 10` | 添柴按钮冷却时间 |
| 火焰冷却 | 5分钟 | `fireCoolDelay: 300000` | 火焰自动降级间隔 |
| 伐木操作 | 60秒 | `gatherWoodDelay: 60` | 伐木按钮冷却时间 |
| 查看陷阱 | 90秒 | `checkTrapsDelay: 90` | 陷阱检查冷却时间 |
| 房间温度 | 30秒 | `roomWarmDelay: 30000` | 温度调节间隔 |
| 建造者状态 | 30秒 | `builderStateDelay: 30000` | 建造者升级检查间隔 |

## 🎮 UI进度条时间配置

| 操作 | 进度条时间 | 配置名称 |
|------|------------|----------|
| 点火 | 10秒 | `lightFireProgressDuration` |
| 添柴 | 10秒 | `stokeFireProgressDuration` |
| 伐木 | 60秒 | `gatherWoodProgressDuration` |
| 查看陷阱 | 90秒 | `checkTrapsProgressDuration` |

## 🔧 调试模式支持

配置文件提供调试模式支持，可以快速测试游戏功能：

```dart
static const bool debugMode = false; // 设为true启用调试模式

// 调试模式下的快速时间
static const int debugStokeCooldown = 0;     // 无冷却
static const int debugGatherDelay = 0;       // 无延迟
static const int debugTrapsDelay = 0;        // 无延迟
```

## 📁 修改的文件

1. **新增文件**:
   - `lib/config/game_config.dart` - 游戏配置文件

2. **修改文件**:
   - `lib/modules/room.dart` - 更新时间常量获取方式
   - `lib/modules/outside.dart` - 更新时间常量获取方式
   - `lib/screens/room_screen.dart` - 更新进度条时间配置
   - `lib/screens/outside_screen.dart` - 更新进度条时间配置

## ✅ 优化效果

### 代码维护性提升
- **集中管理**: 所有时间配置集中在一个文件中
- **易于调整**: 修改游戏平衡性时只需修改配置文件
- **调试友好**: 支持快速调试模式

### 一致性保证
- **原游戏对照**: 每个配置都标注了原游戏对应值
- **文档完整**: 详细的配置说明和对照表
- **类型安全**: 使用Dart的类型系统确保配置正确性

### 扩展性增强
- **模块化设计**: 按功能模块组织配置
- **动态配置**: 支持运行时根据条件选择配置
- **版本兼容**: 便于未来添加新的配置项

## 🔄 后续优化建议

1. **配置热重载**: 考虑添加配置文件热重载功能
2. **配置验证**: 添加配置值的合法性验证
3. **配置分层**: 考虑按难度等级提供不同的配置组合
4. **配置导出**: 提供配置导出功能，便于分享和备份

## 📝 更新日志

- **2025-06-30**: 创建游戏配置集中化优化文档
- **2025-06-30**: 实现配置文件和相关模块更新
- **2025-06-30**: 完成UI组件进度条时间配置更新

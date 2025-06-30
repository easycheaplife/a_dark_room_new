# A Dark Room 游戏时间配置分析

**创建时间**: 2025-06-30  
**分析类型**: 功能性玩法分析  
**分析范围**: 原游戏与Flutter版本的时间配置对比  
**状态**: ✅ 已完成

## 📋 分析概述

本文档详细分析了A Dark Room原游戏中添柴、伐木、查看陷阱等操作的进度条时间，并在Flutter版本中实现了统一的配置管理系统。

## 🎯 分析目标

1. **确定原游戏时间**: 分析原游戏源代码中的具体时间配置
2. **实现配置集中化**: 创建统一的游戏配置文件
3. **保持游戏一致性**: 确保Flutter版本与原游戏时间完全一致
4. **提高可维护性**: 便于后续调整和优化

## 🔍 原游戏时间配置分析

### 核心操作时间

| 操作 | 原游戏配置 | 时间值 | 说明 |
|------|------------|--------|------|
| 添柴冷却 | `_STOKE_COOLDOWN: 10` | 10秒 | 添柴按钮冷却时间 |
| 火焰冷却 | `_FIRE_COOL_DELAY: 5 * 60 * 1000` | 5分钟 | 火焰自动降级间隔 |
| 伐木操作 | `_GATHER_DELAY: 60` | 60秒 | 伐木按钮冷却时间 |
| 查看陷阱 | `_TRAPS_DELAY: 90` | 90秒 | 陷阱检查冷却时间 |

### 房间系统时间

| 配置项 | 原游戏值 | 说明 |
|--------|----------|------|
| 房间温度更新 | `_ROOM_WARM_DELAY: 30 * 1000` | 30秒间隔调节温度 |
| 建造者状态 | `_BUILDER_STATE_DELAY: 0.5 * 60 * 1000` | 30秒检查建造者升级 |
| 需要木材提示 | `_NEED_WOOD_DELAY: 15 * 1000` | 15秒后显示木材不足提示 |

### 外部系统时间

| 配置项 | 原游戏值 | 说明 |
|--------|----------|------|
| 人口增长延迟 | `_POP_DELAY: [0.5, 3]` | 0.5-3分钟随机间隔 |
| 小屋容量 | `_HUT_ROOM: 4` | 每个小屋容纳4人 |

## 🛠️ 实施方案

### 1. 配置文件创建

创建 `lib/config/game_config.dart` 文件，包含：

```dart
class GameConfig {
  // 房间模块配置
  static const int stokeFireCooldown = 10;           // 添柴冷却：10秒
  static const int fireCoolDelay = 5 * 60 * 1000;    // 火焰冷却：5分钟
  static const int roomWarmDelay = 30 * 1000;        // 温度更新：30秒
  static const int builderStateDelay = 30 * 1000;    // 建造者状态：30秒
  static const int needWoodDelay = 15 * 1000;        // 木材提示：15秒
  
  // 外部模块配置
  static const int gatherWoodDelay = 60;              // 伐木延迟：60秒
  static const int checkTrapsDelay = 90;              // 陷阱检查：90秒
  static const List<double> popDelayRange = [0.5, 3.0]; // 人口增长：0.5-3分钟
  static const int hutRoom = 4;                       // 小屋容量：4人
  
  // UI进度条时间
  static const int lightFireProgressDuration = stokeFireCooldown * 1000;
  static const int stokeFireProgressDuration = stokeFireCooldown * 1000;
  static const int gatherWoodProgressDuration = gatherWoodDelay * 1000;
  static const int checkTrapsProgressDuration = checkTrapsDelay * 1000;
}
```

### 2. 模块更新

#### Room模块
- 将硬编码常量改为从GameConfig获取
- 使用getter方法支持动态配置

#### Outside模块
- 更新伐木和陷阱检查时间配置
- 保持与原游戏完全一致

#### UI组件
- 更新ProgressButton的进度条时间
- 确保视觉反馈与实际冷却时间一致

## 📊 配置对照验证

### 添柴操作
- **原游戏**: `_STOKE_COOLDOWN: 10` (10秒)
- **Flutter版**: `GameConfig.stokeFireCooldown = 10` (10秒)
- **UI进度条**: `GameConfig.stokeFireProgressDuration = 10000` (10秒)
- ✅ **验证结果**: 完全一致

### 伐木操作
- **原游戏**: `_GATHER_DELAY: 60` (60秒)
- **Flutter版**: `GameConfig.gatherWoodDelay = 60` (60秒)
- **UI进度条**: `GameConfig.gatherWoodProgressDuration = 60000` (60秒)
- ✅ **验证结果**: 完全一致

### 查看陷阱
- **原游戏**: `_TRAPS_DELAY: 90` (90秒)
- **Flutter版**: `GameConfig.checkTrapsDelay = 90` (90秒)
- **UI进度条**: `GameConfig.checkTrapsProgressDuration = 90000` (90秒)
- ✅ **验证结果**: 完全一致

## 🎮 游戏体验影响

### 节奏控制
- **添柴频率**: 10秒冷却确保玩家需要定期关注火焰状态
- **伐木效率**: 60秒间隔平衡了资源获取速度
- **陷阱检查**: 90秒间隔避免过于频繁的操作

### 平衡性设计
- **火焰管理**: 5分钟自动冷却需要玩家主动维护
- **资源收集**: 不同操作的时间差异创造了策略选择
- **人口增长**: 随机间隔增加了游戏的不确定性

## 🔧 调试支持

配置文件提供调试模式支持：

```dart
static const bool debugMode = false; // 可设为true启用快速调试

// 调试模式下的快速时间
static const int debugStokeCooldown = 0;     // 无冷却
static const int debugGatherDelay = 0;       // 无延迟
static const int debugTrapsDelay = 0;        // 无延迟
```

## 📁 相关文件

### 新增文件
- `lib/config/game_config.dart` - 游戏配置文件
- `docs/06_optimizations/game_config_centralization.md` - 优化文档

### 修改文件
- `lib/modules/room.dart` - 更新时间常量获取方式
- `lib/modules/outside.dart` - 更新时间常量获取方式
- `lib/screens/room_screen.dart` - 更新进度条时间配置
- `lib/screens/outside_screen.dart` - 更新进度条时间配置

## ✅ 测试验证

### 功能测试
- ✅ 游戏正常启动
- ✅ 配置文件正确加载
- ✅ 进度条时间与配置一致
- ✅ 操作冷却时间正确

### 一致性验证
- ✅ 添柴操作：10秒冷却
- ✅ 伐木操作：60秒冷却
- ✅ 查看陷阱：90秒冷却
- ✅ 火焰冷却：5分钟间隔

## 🔄 后续建议

1. **性能监控**: 监控配置变更对游戏性能的影响
2. **平衡调整**: 根据玩家反馈调整时间配置
3. **扩展配置**: 考虑添加更多可配置的游戏参数
4. **配置验证**: 添加配置值的合法性检查

## 📝 更新日志

- **2025-06-30**: 完成原游戏时间配置分析
- **2025-06-30**: 创建统一游戏配置文件
- **2025-06-30**: 更新所有相关模块和UI组件
- **2025-06-30**: 验证配置一致性和功能正确性

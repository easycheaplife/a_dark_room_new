# 战斗伤害参数配置优化

**最后更新**: 2025-01-27

## 🎯 优化目标

将战斗伤害相关的参数从代码中移到配置文件中，实现统一管理和调整。

## 📊 优化前状况

### 问题分析

1. **硬编码参数**: 武器伤害、敌人数据等参数直接硬编码在各个模块中
2. **分散管理**: 相关参数分散在多个文件中，难以统一调整
3. **一致性风险**: 修改参数时容易出现不一致的情况
4. **扩展性差**: 难以快速调整游戏平衡性

### 硬编码示例

**武器伤害 (lib/modules/world.dart)**:
```dart
static const Map<String, Map<String, dynamic>> weapons = {
  'fists': {'verb': 'punch', 'type': 'unarmed', 'damage': 1, 'cooldown': 2},
  'bone spear': {'verb': 'stab', 'type': 'melee', 'damage': 2, 'cooldown': 2},
  'iron sword': {'verb': 'swing', 'type': 'melee', 'damage': 4, 'cooldown': 2},
  // ... 其他武器
};
```

**敌人数据 (lib/events/world_events.dart)**:
```dart
'health': 15,
'damage': 4,
'hit': 0.6,
'attackDelay': 3.0,
```

## 🛠️ 优化方案

### 1. 创建统一配置

在 `GameConfig` 中添加战斗伤害相关的配置项：

```dart
// 武器伤害配置
static const Map<String, int> weaponDamage = {
  'fists': 1,
  'bone spear': 2,
  'iron sword': 4,
  // ... 其他武器
};

// 武器冷却时间配置
static const Map<String, int> weaponCooldown = {
  'fists': 2,
  'bone spear': 2,
  // ... 其他武器
};

// 敌人血量配置
static const Map<String, int> enemyHealth = {
  'bandit': 15,
  'bandit_group': 30,
  // ... 其他敌人
};

// 敌人伤害配置
static const Map<String, int> enemyDamage = {
  'bandit': 4,
  'bandit_group': 5,
  // ... 其他敌人
};

// 敌人命中率配置
static const Map<String, double> enemyHitChance = {
  'bandit': 0.6,
  'bandit_group': 0.7,
  // ... 其他敌人
};

// 敌人攻击延迟配置
static const Map<String, double> enemyAttackDelay = {
  'bandit': 3.0,
  'bandit_group': 2.5,
  // ... 其他敌人
};
```

### 2. 修改武器配置使用

将 `World.weapons` 从静态常量改为 getter 方法，从配置获取数值：

```dart
static Map<String, Map<String, dynamic>> get weapons => {
  'fists': {
    'verb': 'punch', 
    'type': 'unarmed', 
    'damage': GameConfig.weaponDamage['fists'] ?? 1, 
    'cooldown': GameConfig.weaponCooldown['fists'] ?? 2
  },
  'bone spear': {
    'verb': 'stab',
    'type': 'melee',
    'damage': GameConfig.weaponDamage['bone spear'] ?? 2,
    'cooldown': GameConfig.weaponCooldown['bone spear'] ?? 2
  },
  // ... 其他武器
};
```

### 3. 修改敌人数据使用

更新敌人事件配置，从 `GameConfig` 获取数值：

```dart
'health': GameConfig.enemyHealth['bandit'] ?? 15,
'damage': GameConfig.enemyDamage['bandit'] ?? 4,
'hit': GameConfig.enemyHitChance['bandit'] ?? 0.6,
'attackDelay': GameConfig.enemyAttackDelay['bandit'] ?? 3.0,
```

## ✅ 优化结果

### 修改的文件

1. **lib/config/game_config.dart** - 添加战斗伤害相关配置
2. **lib/modules/world.dart** - 修改武器配置使用方式
3. **lib/events/world_events.dart** - 修改敌人数据使用方式
4. **test/combat_damage_config_test.dart** - 新增验证测试
5. **test/all_tests.dart** - 添加新测试到测试套件

### 优化效果

#### 1. 统一配置管理
- ✅ 所有战斗伤害参数集中在 `GameConfig` 中管理
- ✅ 修改参数只需要在一个地方进行
- ✅ 保持所有模块使用相同的配置值

#### 2. 提高可维护性
- ✅ 清晰的参数分类和命名
- ✅ 使用 Map 结构组织相关参数
- ✅ 提供默认值作为备选

#### 3. 增强扩展性
- ✅ 可以快速调整游戏平衡性
- ✅ 支持未来添加更多武器和敌人类型
- ✅ 为后续添加难度系统做准备

#### 4. 提高代码质量
- ✅ 减少重复代码
- ✅ 提高代码可读性
- ✅ 更容易进行单元测试

### 测试验证

创建了专门的测试文件 `test/combat_damage_config_test.dart` 来验证配置项是否生效：

#### 测试覆盖范围
1. **武器伤害配置验证** - 验证武器伤害和冷却时间
2. **敌人数据配置验证** - 验证敌人血量、伤害、命中率和攻击延迟
3. **配置一致性验证** - 验证配置的完整性和合理性

#### 测试结果
```
⚔️ 战斗伤害配置测试
  🗡️ 武器伤害配置验证
    ✅ 武器伤害数值应该从GameConfig获取
    ✅ 武器冷却时间应该从GameConfig获取
    ✅ 特殊武器配置应该正确
    ✅ 所有武器都应该有配置
  👹 敌人数据配置验证
    ✅ 土匪事件应该使用GameConfig配置
    ✅ 土匪团伙事件应该使用GameConfig配置
    ✅ 士兵事件应该使用GameConfig配置
    ✅ 外星人事件应该使用GameConfig配置
    ✅ 战团事件应该使用GameConfig配置
  🔧 配置一致性验证
    ✅ GameConfig中的武器配置应该完整
    ✅ GameConfig中的敌人配置应该完整
    ✅ 配置数值应该在合理范围内

All tests passed! (12/12)
```

## 🔄 后续建议

1. **配置文件扩展**: 考虑将配置移到外部JSON文件，支持不重新编译就能调整参数
2. **难度系统**: 基于当前配置结构，可以轻松实现多难度级别
3. **平衡性调整**: 利用集中配置进行游戏平衡性调整
4. **调试模式**: 添加调试模式下的配置修改功能，方便测试不同参数

## 📝 技术细节

### 配置项组织结构

```
GameConfig
├── weaponDamage       // 武器伤害值
├── weaponCooldown     // 武器冷却时间
├── enemyHealth        // 敌人血量
├── enemyDamage        // 敌人伤害
├── enemyHitChance     // 敌人命中率
└── enemyAttackDelay   // 敌人攻击延迟
```

### 特殊武器处理

对于特殊武器（如缠绕武器bolas），保留了原有的特殊处理逻辑：

```dart
'bolas': {
  'verb': 'tangle',
  'type': 'ranged',
  'damage': 'stun',  // 特殊伤害类型，不从配置获取
  'cooldown': GameConfig.weaponCooldown['bolas'] ?? 15,
  'cost': {'bolas': 1}
},
```

### 默认值机制

所有从配置获取的值都提供了默认值作为备选，确保即使配置缺失也能正常运行：

```dart
'damage': GameConfig.weaponDamage['rifle'] ?? 5,
'cooldown': GameConfig.weaponCooldown['rifle'] ?? 1,
```

---

**优化完成**: 2025-01-27  
**测试状态**: ✅ 全部通过 (12/12)  
**影响模块**: GameConfig, World, WorldEvents  
**配置项数量**: 50+ 个配置项现在统一管理

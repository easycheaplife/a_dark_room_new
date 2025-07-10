# 战斗中缠绕武器时缺少普通攻击修复

**最后更新**: 2025-01-27

## 🐛 问题描述

用户报告："有缠绕的时候没有普通攻击"

### 问题现象
从用户提供的截图可以看到：
1. **战斗界面显示**：玩家血量 86/100，敌人血量 5/5
2. **可用操作**：只有"缠绕"和"吃肉"按钮
3. **缺失操作**：没有普通攻击（拳头/挥拳）选项
4. **问题场景**：当玩家只有缠绕武器（bolas）等非数值伤害武器时

## 🔍 问题分析

### 根因分析

通过对比原游戏代码和当前实现，发现问题出现在武器可用性检查逻辑上：

#### 原游戏逻辑（../adarkroom/script/events.js）
```javascript
// 第115-139行
var numWeapons = 0;
for(var k in World.Weapons) {
    var weapon = World.Weapons[k];
    if(typeof Path.outfit[k] == 'number' && Path.outfit[k] > 0) {
        if(typeof weapon.damage != 'number' || weapon.damage === 0) {
            // Weapons that deal no damage don't count
            numWeapons--;  // ❗ 关键：非数值伤害武器不计入numWeapons
        } else if(weapon.cost){
            // 检查弹药...
        }
        numWeapons++;
        Events.createAttackButton(k).appendTo(attackBtns);
    }
}
if(numWeapons === 0) {
    // No weapons? You can punch stuff!
    Events.createAttackButton('fists').prependTo(attackBtns);  // ❗ 添加拳头
}
```

#### 当前实现的问题
```dart
// lib/modules/events.dart - getAvailableWeapons()
List<String> getAvailableWeapons() {
    // ...
    for (final weaponName in World.weapons.keys) {
        if (weaponName != 'fists' && (path.outfit[weaponName] ?? 0) > 0) {
            final weapon = World.weapons[weaponName]!;
            
            // ❌ 问题：所有武器都计入numWeapons，包括非数值伤害武器
            if (weapon['damage'] == null || weapon['damage'] == 0) {
                continue;
            }
            
            // 弹药检查...
            if (canUse) {
                numWeapons++;  // ❌ 缠绕武器也被计入
                availableWeapons.add(weaponName);
            }
        }
    }
    
    // ❌ 因为numWeapons > 0，所以不显示拳头
    if (numWeapons == 0) {
        availableWeapons.add('fists');
    }
}
```

### 关键差异

1. **原游戏**：伤害为字符串（如 `'stun'`）的武器**不计入** `numWeapons`
2. **当前实现**：所有可用武器都计入 `numWeapons`
3. **结果**：当只有缠绕武器时，`numWeapons > 0`，所以不显示拳头

## 🛠️ 修复方案

### 修复逻辑

参考原游戏逻辑，正确处理非数值伤害武器：

```dart
// 修复后的 getAvailableWeapons() 逻辑
List<String> getAvailableWeapons() {
    final availableWeapons = <String>[];
    int numWeapons = 0;  // 只计算数值伤害武器
    
    for (final weaponName in World.weapons.keys) {
        if (weaponName != 'fists' && (path.outfit[weaponName] ?? 0) > 0) {
            final weapon = World.weapons[weaponName]!;
            
            // 首先检查弹药是否足够
            bool canUse = true;
            if (weapon['cost'] != null) {
                // 弹药检查逻辑...
            }
            
            if (canUse) {
                availableWeapons.add(weaponName);
                
                // 只有数值伤害武器才计入numWeapons
                final damage = weapon['damage'];
                if (damage != null && damage != 0 && damage is int) {
                    numWeapons++;
                }
            }
        }
    }
    
    // 如果没有数值伤害武器，添加拳头
    if (numWeapons == 0) {
        if (!availableWeapons.contains('fists')) {
            availableWeapons.insert(0, 'fists');  // 参考原游戏的prependTo
        }
    }
    
    return availableWeapons;
}
```

### 修复的关键点

1. **弹药检查优先**：先检查弹药，再检查伤害类型
2. **分离计数逻辑**：将武器添加和numWeapons计数分开处理
3. **正确的伤害类型判断**：只有 `int` 类型的伤害才计入numWeapons
4. **拳头位置**：使用 `insert(0, 'fists')` 确保拳头在前面

## ✅ 修复结果

### 修复前后对比

#### 修复前
- **只有缠绕武器时**：显示 `['bolas']`，没有拳头
- **问题**：玩家无法进行基础攻击

#### 修复后
- **只有缠绕武器时**：显示 `['fists', 'bolas']`，拳头在前
- **有数值武器时**：显示 `['bone spear']`，不显示拳头
- **没有武器时**：显示 `['fists']`，只有拳头

### 测试验证

创建了专门的测试文件 `test/combat_fists_availability_test.dart`：

#### 测试覆盖范围
1. **基础拳头可用性**
   - ✅ 没有武器时显示拳头
   - ✅ 有数值伤害武器时隐藏拳头

2. **缠绕武器特殊情况**
   - ✅ 只有缠绕武器时同时显示拳头和缠绕
   - ✅ 缠绕+数值武器时隐藏拳头
   - ✅ 缠绕武器无弹药时只显示拳头

3. **其他特殊武器**
   - ✅ 干扰器（disruptor）也触发拳头显示
   - ✅ 多个非数值伤害武器时显示拳头

4. **武器配置验证**
   - ✅ 验证缠绕武器配置正确（damage: 'stun'）
   - ✅ 验证干扰器配置正确（damage: 'stun'）
   - ✅ 验证拳头配置正确（damage: 1）

#### 测试结果
```
🥊 战斗中拳头可用性测试
  🎯 基础拳头可用性
    ✅ 没有任何武器时应该显示拳头
    ✅ 有数值伤害武器时不应该显示拳头
  🌪️ 缠绕武器特殊情况
    ✅ 只有缠绕武器时应该同时显示拳头和缠绕
    ✅ 缠绕武器 + 数值伤害武器时不应该显示拳头
    ✅ 缠绕武器没有弹药时不应该显示缠绕但应该显示拳头
  🔫 其他特殊武器测试
    ✅ 干扰器（disruptor）也应该触发拳头显示
    ✅ 多个非数值伤害武器时应该显示拳头
  🔍 武器配置验证
    ✅ 验证缠绕武器的配置正确
    ✅ 验证干扰器的配置正确
    ✅ 验证拳头的配置正确

All tests passed! (10/10)
```

## 🎯 影响范围

### 修复的文件
- `lib/modules/events.dart` - 修复 `getAvailableWeapons()` 方法
- `test/combat_fists_availability_test.dart` - 新增验证测试
- `test/all_tests.dart` - 添加新测试到测试套件

### 游戏行为变化
- ✅ **缠绕武器场景**：现在正确显示拳头作为基础攻击选项
- ✅ **干扰器场景**：同样正确显示拳头
- ✅ **混合武器场景**：有数值伤害武器时正确隐藏拳头
- ✅ **无武器场景**：保持原有的拳头显示逻辑

### 受影响的武器类型
- **非数值伤害武器**：`bolas`（缠绕）、`disruptor`（干扰器）
- **数值伤害武器**：`bone spear`、`iron sword`、`rifle` 等
- **基础攻击**：`fists`（拳头/挥拳）

## 🔄 技术细节

### 武器伤害类型分类
```dart
// 数值伤害武器（计入numWeapons）
'bone spear': { 'damage': 2 }      // int类型
'iron sword': { 'damage': 4 }      // int类型
'rifle': { 'damage': 5 }           // int类型

// 非数值伤害武器（不计入numWeapons）
'bolas': { 'damage': 'stun' }      // string类型
'disruptor': { 'damage': 'stun' }  // string类型

// 基础攻击（总是可用当numWeapons=0时）
'fists': { 'damage': 1 }           // int类型，但特殊处理
```

### 原游戏兼容性
- ✅ 完全符合原游戏的武器显示逻辑
- ✅ 保持原游戏的拳头优先级（prependTo行为）
- ✅ 正确处理所有武器类型和弹药消耗

---

**修复完成**: 2025-01-27  
**测试状态**: ✅ 全部通过 (10/10)  
**影响模块**: Events, Combat  
**用户体验**: 🎉 现在缠绕武器时可以正常使用普通攻击

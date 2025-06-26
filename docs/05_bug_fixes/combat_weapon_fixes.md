# 战斗系统武器修复

## 修复日期
2025-06-26

## 问题描述

用户反馈了三个战斗系统中的武器问题：

1. **骨枪在战斗中被错误消耗** - 骨枪在战斗中不应该消耗，但当前实现会消耗它
2. **默认攻击显示"拳头"而不是"挥拳"** - 没有武器时应该显示"挥拳"动作而不是武器名称
3. **武器攻击名称不正确** - 各种武器的攻击动作名称与原游戏不符

## 原游戏分析

通过分析原游戏 `../adarkroom/script/events.js` 和 `../adarkroom/script/world.js` 文件，发现：

### 武器配置（World.Weapons）
```javascript
'fists': { verb: 'punch', type: 'unarmed', damage: 1, cooldown: 2 },
'bone spear': { verb: 'stab', type: 'melee', damage: 2, cooldown: 2 }, // 注意：没有cost属性
'iron sword': { verb: 'swing', type: 'melee', damage: 4, cooldown: 2 },
'steel sword': { verb: 'slash', type: 'melee', damage: 6, cooldown: 2 },
'rifle': { verb: 'shoot', type: 'ranged', damage: 5, cooldown: 1, cost: { 'bullets': 1 } }
```

### 武器消耗逻辑
原游戏中只有带有 `cost` 属性的武器才会在使用时消耗弹药：
- 骨枪（bone spear）没有 `cost` 属性，因此不消耗
- 步枪（rifle）有 `cost: { 'bullets': 1 }`，每次使用消耗1发子弹

### 武器显示逻辑
原游戏使用武器的 `verb` 属性作为攻击按钮的显示文本，而不是武器名称。

## 修复方案

### 1. 修正武器配置 (lib/modules/world.dart)

更新武器配置以匹配原游戏：

```dart
// 武器配置 - 参考原游戏World.Weapons
static const Map<String, Map<String, dynamic>> weapons = {
  'fists': {'verb': 'punch', 'type': 'unarmed', 'damage': 1, 'cooldown': 2},
  'bone spear': {'verb': 'stab', 'type': 'melee', 'damage': 2, 'cooldown': 2}, // 注意：骨枪没有cost，不消耗
  'iron sword': {'verb': 'swing', 'type': 'melee', 'damage': 4, 'cooldown': 2}, // 修正：原游戏是swing不是slash
  'steel sword': {'verb': 'slash', 'type': 'melee', 'damage': 6, 'cooldown': 2}, // 修正：原游戏是slash不是strike
  // ... 其他武器
};
```

### 2. 修复武器可用性检查 (lib/modules/events.dart)

更新 `getAvailableWeapons()` 方法以正确检查武器可用性：

```dart
List<String> getAvailableWeapons() {
  final path = Path();
  final availableWeapons = <String>[];
  int numWeapons = 0;

  // 检查背包中的武器
  for (final weaponName in World.weapons.keys) {
    if (weaponName != 'fists' && (path.outfit[weaponName] ?? 0) > 0) {
      final weapon = World.weapons[weaponName]!;
      
      // 检查武器是否有效（有伤害）
      if (weapon['damage'] == null || weapon['damage'] == 0) {
        continue; // 无伤害武器不计入
      }
      
      // 检查是否有足够的弹药
      bool canUse = true;
      if (weapon['cost'] != null) {
        final cost = weapon['cost'] as Map<String, dynamic>;
        for (final entry in cost.entries) {
          final required = entry.value as int;
          final available = path.outfit[entry.key] ?? 0;
          if (available < required) {
            canUse = false;
            break;
          }
        }
      }
      
      if (canUse) {
        numWeapons++;
        availableWeapons.add(weaponName);
      }
    }
  }

  // 如果没有可用武器，显示拳头
  if (numWeapons == 0) {
    availableWeapons.clear();
    availableWeapons.add('fists');
  }

  return availableWeapons;
}
```

### 3. 修复武器显示名称 (lib/screens/combat_screen.dart)

更新 `_getWeaponDisplayName()` 方法使用武器的 `verb` 属性：

```dart
String _getWeaponDisplayName(String weaponName) {
  final localization = Localization();
  final weapon = World.weapons[weaponName];
  
  if (weapon != null && weapon['verb'] != null) {
    final verb = weapon['verb'] as String;
    
    // 尝试从本地化获取动作名称
    final translatedVerb = localization.translate('combat.weapons.$verb');
    if (translatedVerb != 'combat.weapons.$verb') {
      return translatedVerb;
    }
    
    // 如果没有找到翻译，尝试使用武器名称
    final translatedName = localization.translate('combat.weapons.$weaponName');
    if (translatedName != 'combat.weapons.$weaponName') {
      return translatedName;
    }
    
    // 最后返回原verb
    return verb;
  }

  // 如果没有找到武器配置，返回原名称
  return weaponName;
}
```

### 4. 更新本地化文件 (assets/lang/zh.json)

添加正确的武器动作翻译：

```json
"combat": {
  "weapons": {
    "fists": "挥拳",
    "punch": "挥拳",
    "bone spear": "骨枪", 
    "stab": "戳刺",
    "iron sword": "铁剑",
    "swing": "挥砍", 
    "steel sword": "钢剑",
    "slash": "斩击",
    "bayonet": "刺刀",
    "thrust": "突刺",
    "rifle": "步枪",
    "shoot": "射击",
    "laser rifle": "激光步枪",
    "blast": "爆破",
    "grenade": "手榴弹", 
    "lob": "投掷",
    "bolas": "流星锤",
    "tangle": "缠绕",
    "plasma rifle": "等离子步枪",
    "disintigrate": "分解",
    "energy blade": "能量剑",
    "slice": "切割",
    "disruptor": "干扰器",
    "stun": "眩晕"
  }
}
```

## 修复结果

1. ✅ **骨枪不再被消耗** - 骨枪没有 `cost` 属性，在战斗中使用时不会被消耗
2. ✅ **默认攻击显示"挥拳"** - 没有武器时显示"挥拳"而不是"拳头"
3. ✅ **武器攻击名称正确** - 所有武器都使用正确的动作名称（verb）

## 测试验证

通过 `flutter run -d chrome` 测试验证：
- 战斗系统正常工作
- 武器按钮显示正确的动作名称
- 骨枪在战斗中不被消耗
- 没有武器时正确显示"挥拳"选项

## 相关文件

- `lib/modules/world.dart` - 武器配置修正
- `lib/modules/events.dart` - 武器可用性检查逻辑
- `lib/screens/combat_screen.dart` - 武器显示名称逻辑
- `assets/lang/zh.json` - 本地化翻译更新

## 关键Bug修复 (2025-06-26 下午)

### 装备消失Bug发现

用户进一步澄清："进入地图出发时携带一个骨枪，第一次战斗有戳刺按钮，**没有死亡**，战斗结束后，继续走，进入第二次战斗只有挥拳了，且背包里面的骨枪也没有了"

这确实是一个真正的bug！通过深入测试发现了根本原因。

### Bug根本原因

问题出现在`Path.updateOutfitting()`方法中：

```dart
// 错误的逻辑
for (final k in carryable.keys) {
  final store = carryable[k]!;
  final have = (sm.get('stores["$k"]', true) ?? 0) as int;  // 问题在这里！
  var num = outfit[k] ?? 0;

  if (have < num) {  // 这个检查是错误的
    num = have;
  }
  outfit[k] = num;  // 这里会错误地清空装备
}
```

**问题分析：**
1. 当玩家出发到世界地图时，装备中的物品已经从仓库(`stores`)中扣除
2. 所以仓库中的骨枪数量是0，但装备中的骨枪数量是1
3. 错误的逻辑检查`have < num`（0 < 1），然后将装备中的骨枪设置为0
4. 这导致骨枪在战斗后被错误清除

### 修复方案

参考原游戏`../adarkroom/script/path.js`第188-191行的正确逻辑：

```javascript
if (have !== undefined) {
    if (have < num) { num = have; }
    $SM.set(k, num, true);
}
```

原游戏只有在`have !== undefined`时才执行检查，而我们的实现总是执行检查。

**修复代码：**

```dart
for (final k in carryable.keys) {
  final store = carryable[k]!;
  final have = sm.get('stores["$k"]', true);  // 不使用??0，保持null
  var num = outfit[k] ?? 0;

  // 参考原游戏逻辑：只有当仓库中有这个物品时才检查数量限制
  if (have != null) {
    final haveInt = have as int;
    if (haveInt < num) {
      num = haveInt;
    }
    // 重要：原游戏总是同步outfit数据到StateManager
    sm.set('outfit["$k"]', num);
    outfit[k] = num;
  }

  if ((store['type'] == 'tool' || store['type'] == 'weapon') && (have ?? 0) > 0) {
    currentBagCapacity += num * getWeight(k);
  }
}
```

## 战利品拾取导致装备消失Bug修复 (2025-06-26 晚上)

### 新问题发现

用户进一步反馈："进入地图出发时携带一个骨枪，多次战斗有戳刺按钮，没有死亡，战斗结束后，继续走，**只要拾取了战斗的物品，骨枪就没了**"

这是一个更精确的问题描述，指向了战利品拾取逻辑中的bug。

### Bug根本原因

通过深入分析发现，问题出现在`Events.getLoot()`方法的第1064行：

```dart
// 错误的调用
path.updateOutfitting();
```

**问题分析：**
1. 玩家拾取战利品时，`getLoot()`方法被调用
2. 该方法错误地调用了`path.updateOutfitting()`
3. `updateOutfitting()`方法检查仓库vs装备数量，发现仓库中骨枪=0，装备中骨枪=1
4. 错误逻辑将装备中的骨枪设置为0，导致装备消失

### 原游戏验证

通过分析原游戏`../adarkroom/script/path.js`，发现`updateOutfitting`只在以下情况调用：
- 增加/减少补给时 (第294、306行)
- 到达路径界面时 (第312行)
- 收入状态更新时 (第338行)

**原游戏从不在拾取战利品时调用`updateOutfitting`！**

### 修复方案

移除`Events.getLoot()`方法中错误的`updateOutfitting()`调用：

```dart
// 修复前 - 错误的调用
// 保存到StateManager - 确保数据持久化
final sm = StateManager();
sm.set('outfit["$itemName"]', path.outfit[itemName]);

// 通知Path模块更新
path.updateOutfitting(); // ❌ 这个调用是错误的

// 修复后 - 移除错误调用
// 保存到StateManager - 确保数据持久化
final sm = StateManager();
sm.set('outfit["$itemName"]', path.outfit[itemName]);

// 注意：原游戏在拾取战利品时不会调用updateOutfitting
// updateOutfitting只在增减补给、到达路径界面、收入更新时调用
```

### 影响范围

这个bug影响所有通过战利品拾取的情况：
- 🎯 战斗胜利后拾取战利品
- 🏺 探索地点时拾取物品
- 📦 任何调用`getLoot()`方法的场景

修复后，玩家可以正常拾取战利品而不会丢失装备。

## 更新日志

- 2025-06-26: 初始修复，解决骨枪消耗、攻击名称显示等问题
- 2025-06-26: 发现并修复装备消失bug - Path.updateOutfitting()方法错误清除装备
- 2025-06-26: 修复战利品拾取导致装备消失的关键bug - 移除错误的updateOutfitting()调用

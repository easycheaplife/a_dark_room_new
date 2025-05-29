import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import 'path.dart';
import 'world.dart';

/// 事件模块 - 处理随机事件系统
/// 包括战斗、故事事件、战利品系统等功能
class Events extends ChangeNotifier {
  static final Events _instance = Events._internal();

  factory Events() {
    return _instance;
  }

  static Events get instance => _instance;

  Events._internal();

  // 模块名称
  final String name = "事件";

  // 常量
  static const List<int> eventTimeRange = [3, 6]; // 分钟范围
  static const int panelFade = 200;
  static const int fightSpeed = 100;
  static const int eatCooldown = 5;
  static const int medsCooldown = 7;
  static const int hypoCooldown = 7;
  static const int shieldCooldown = 10;
  static const int stimCooldown = 10;
  static const int leaveCooldown = 1;
  static const int stunDuration = 4000;
  static const int energiseMultiplier = 4;
  static const int explosionDuration = 3000;
  static const int enrageDuration = 4000;
  static const int meditateDuration = 5000;
  static const int boostDuration = 3000;
  static const int boostDamage = 10;
  static const int dotTick = 1000;

  // 状态变量
  Map<String, dynamic> options = {};
  String delayState = 'wait';
  String? activeScene;
  List<Map<String, dynamic>> eventStack = [];
  List<Map<String, dynamic>> eventPool = [];
  bool fought = false;
  bool won = false;
  bool paused = false;
  Timer? nextEventTimer;
  Timer? enemyAttackTimer;
  List<Timer> specialTimers = [];
  Timer? dotTimer;
  int meditateDmg = 0;

  /// 初始化事件模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    // 构建事件池
    eventPool = [
      ...globalEvents,
      ...roomEvents,
      ...outsideEvents,
      ...marketingEvents,
    ];

    eventStack = [];
    scheduleNextEvent();

    // 检查存储的延迟事件
    initDelay();

    notifyListeners();
  }

  /// 全局事件
  List<Map<String, dynamic>> get globalEvents => [
    // 这里将包含全局事件定义
  ];

  /// 房间事件
  List<Map<String, dynamic>> get roomEvents => [
    // 这里将包含房间事件定义
  ];

  /// 外部事件
  List<Map<String, dynamic>> get outsideEvents => [
    // 这里将包含外部事件定义
  ];

  /// 营销事件
  List<Map<String, dynamic>> get marketingEvents => [
    // 这里将包含营销事件定义
  ];

  /// 加载场景
  void loadScene(String sceneName) {
    // Engine().log('加载场景: $sceneName'); // 暂时注释掉
    activeScene = sceneName;
    final event = activeEvent();
    if (event == null) return;

    final scene = event['scenes'][sceneName];
    if (scene == null) return;

    // onLoad 回调
    if (scene['onLoad'] != null) {
      scene['onLoad']();
    }

    // 场景通知
    if (scene['notification'] != null) {
      NotificationManager().notify(name, scene['notification']);
    }

    // 场景奖励
    if (scene['reward'] != null) {
      final sm = StateManager();
      final reward = scene['reward'] as Map<String, dynamic>;
      for (final entry in reward.entries) {
        sm.add('stores["${entry.key}"]', entry.value);
      }
    }

    if (scene['combat'] == true) {
      startCombat(scene);
    } else {
      startStory(scene);
    }

    notifyListeners();
  }

  /// 开始战斗
  void startCombat(Map<String, dynamic> scene) {
    Engine().event('game event', 'combat');
    fought = false;
    won = false;

    // 创建战斗者（暂时不使用这些变量，但保留逻辑）
    // final wandererHealth = World().health;
    // final wandererMaxHealth = World().getMaxHealth();
    // final enemyHealth = scene['health'] ?? 10;

    // 设置敌人攻击定时器
    startEnemyAttacks(scene['attackDelay'] ?? 2.0);

    // 设置特殊技能定时器
    final specials = scene['specials'] as List<Map<String, dynamic>>? ?? [];
    for (final special in specials) {
      final timer = Timer.periodic(
        Duration(milliseconds: ((special['delay'] ?? 5.0) * 1000).round()),
        (timer) {
          // 执行特殊技能
          if (special['action'] != null) {
            special['action']();
          }
        },
      );
      specialTimers.add(timer);
    }

    notifyListeners();
  }

  /// 开始故事
  void startStory(Map<String, dynamic> scene) {
    // 故事场景处理
    notifyListeners();
  }

  /// 开始敌人攻击
  void startEnemyAttacks([double? delay]) {
    enemyAttackTimer?.cancel();
    final event = activeEvent();
    if (event == null) return;

    final scene = event['scenes'][activeScene];
    if (scene == null) return;

    final attackDelay = delay ?? (scene['attackDelay'] ?? 2.0);
    enemyAttackTimer = Timer.periodic(
      Duration(milliseconds: (attackDelay * 1000).round()),
      (timer) => enemyAttack(),
    );
  }

  /// 敌人攻击
  void enemyAttack() {
    final event = activeEvent();
    if (event == null) return;

    final scene = event['scenes'][activeScene];
    if (scene == null) return;

    final toHit = scene['hit'] ?? 0.8;
    // toHit *= sm.hasPerk('evasive') ? 0.8 : 1; // 暂时注释掉技能系统

    int dmg = -1;
    if (meditateDmg > 0) {
      dmg = meditateDmg;
      meditateDmg = 0;
    } else if (Random().nextDouble() <= toHit) {
      dmg = scene['damage'] ?? 1;
    }

    final isRanged = scene['ranged'] ?? false;
    if (isRanged) {
      animateRanged('enemy', dmg, checkPlayerDeath);
    } else {
      animateMelee('enemy', dmg, checkPlayerDeath);
    }
  }

  /// 近战动画
  void animateMelee(String fighterId, int dmg, VoidCallback? callback) {
    final enemy = fighterId == 'wanderer' ? 'enemy' : 'wanderer';
    damage(fighterId, enemy, dmg, 'melee');
    callback?.call();
  }

  /// 远程动画
  void animateRanged(String fighterId, int dmg, VoidCallback? callback) {
    final enemy = fighterId == 'wanderer' ? 'enemy' : 'wanderer';
    damage(fighterId, enemy, dmg, 'ranged');
    callback?.call();
  }

  /// 造成伤害
  void damage(String fighterId, String enemyId, int dmg, String type) {
    if (enemyId == 'wanderer') {
      // 对玩家造成伤害
      final newHp = max(0, World().health - dmg);
      World().setHp(newHp);
    } else {
      // 对敌人造成伤害
      // 这里需要实现敌人血量管理
    }

    // 播放音效（暂时注释掉）
    // final r = Random().nextInt(2) + 1;
    // switch (type) {
    //   case 'unarmed':
    //     AudioEngine().playSound('weapon_unarmed_$r');
    //     break;
    //   case 'melee':
    //     AudioEngine().playSound('weapon_melee_$r');
    //     break;
    //   case 'ranged':
    //     AudioEngine().playSound('weapon_ranged_$r');
    //     break;
    // }

    notifyListeners();
  }

  /// 检查玩家死亡
  bool checkPlayerDeath() {
    if (World().health <= 0) {
      clearTimeouts();
      endEvent();
      World().die();
      return true;
    }
    return false;
  }

  /// 清除定时器
  void clearTimeouts() {
    enemyAttackTimer?.cancel();
    for (final timer in specialTimers) {
      timer.cancel();
    }
    specialTimers.clear();
    dotTimer?.cancel();
  }

  /// 获取当前活动事件
  Map<String, dynamic>? activeEvent() {
    return eventStack.isNotEmpty ? eventStack.last : null;
  }

  /// 安排下一个事件
  void scheduleNextEvent() {
    final random = Random();
    final delay = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) + eventTimeRange[0];

    nextEventTimer = Timer(Duration(minutes: delay), () {
      triggerEvent();
    });
  }

  /// 触发事件
  void triggerEvent() {
    if (eventPool.isNotEmpty) {
      final random = Random();
      final event = eventPool[random.nextInt(eventPool.length)];
      startEvent(event);
    }
    scheduleNextEvent();
  }

  /// 开始事件
  void startEvent(Map<String, dynamic> event) {
    eventStack.add(event);
    final firstScene = event['scenes'].keys.first;
    loadScene(firstScene);
  }

  /// 结束事件
  void endEvent() {
    clearTimeouts();
    if (eventStack.isNotEmpty) {
      eventStack.removeLast();
    }
    activeScene = null;
    fought = false;
    won = false;
    paused = false;
    notifyListeners();
  }

  /// 初始化延迟
  void initDelay() {
    // 检查存储的延迟事件
    final sm = StateManager();
    final delayedEvents = sm.get('game.delayedEvents');
    if (delayedEvents != null) {
      // 处理延迟事件
    }
  }

  /// 使用武器
  void useWeapon(String weaponName) {
    final weapon = World.weapons[weaponName];
    if (weapon == null) return;

    final path = Path();

    // 检查弹药消耗
    if (weapon['cost'] != null) {
      final cost = weapon['cost'] as Map<String, dynamic>;
      for (final entry in cost.entries) {
        final required = entry.value as int;
        final available = path.outfit[entry.key] ?? 0;
        if (available < required) {
          return; // 弹药不足
        }
      }

      // 消耗弹药
      for (final entry in cost.entries) {
        final required = entry.value as int;
        path.outfit[entry.key] = (path.outfit[entry.key] ?? 0) - required;
      }
    }

    // 计算伤害
    int dmg = -1;
    if (Random().nextDouble() <= World().getHitChance()) {
      dmg = weapon['damage'] ?? 1;

      // 技能加成（暂时注释掉）
      // if (weapon['type'] == 'unarmed' && sm.hasPerk('boxer')) {
      //   dmg *= 2;
      // }
    }

    // 执行攻击
    final attackType = weapon['type'] == 'ranged' ? 'ranged' : 'melee';
    if (attackType == 'ranged') {
      animateRanged('wanderer', dmg, () {
        checkEnemyDeath(dmg);
      });
    } else {
      animateMelee('wanderer', dmg, () {
        checkEnemyDeath(dmg);
      });
    }

    notifyListeners();
  }

  /// 检查敌人死亡
  void checkEnemyDeath(int dmg) {
    final event = activeEvent();
    if (event == null) return;

    final scene = event['scenes'][activeScene];
    if (scene == null) return;

    // 这里需要实现敌人血量管理
    // 暂时简化处理
    if (dmg > 0 && !won) {
      won = true;
      winFight();
    }
  }

  /// 胜利战斗
  void winFight() {
    if (fought) return;

    endFight();

    Timer(Duration(milliseconds: fightSpeed), () {
      final event = activeEvent();
      if (event == null) return;

      final scene = event['scenes'][activeScene];
      if (scene == null) return;

      // 显示战利品
      final loot = scene['loot'] as Map<String, dynamic>? ?? {};
      drawLoot(loot);

      notifyListeners();
    });
  }

  /// 结束战斗
  void endFight() {
    fought = true;
    clearTimeouts();
  }

  /// 绘制战利品
  void drawLoot(Map<String, dynamic> lootList) {
    final availableLoot = <String, int>{};

    for (final entry in lootList.entries) {
      final loot = entry.value as Map<String, dynamic>;
      final chance = (loot['chance'] ?? 1.0) as double;

      if (Random().nextDouble() < chance) {
        final min = (loot['min'] ?? 1) as int;
        final max = (loot['max'] ?? 1) as int;
        final num = Random().nextInt(max - min + 1) + min;
        availableLoot[entry.key] = num;
      }
    }

    // 在Flutter中，战利品显示将通过UI组件处理
    notifyListeners();
  }

  /// 获取战利品
  void getLoot(String itemName, int amount) {
    final path = Path();
    final weight = path.getWeight(itemName);
    final freeSpace = path.getFreeSpace();

    final canTake = min(amount, (freeSpace / weight).floor());
    if (canTake > 0) {
      final sm = StateManager();
      sm.add('stores["$itemName"]', canTake);

      // 更新装备
      if (path.outfit.containsKey(itemName)) {
        path.outfit[itemName] = (path.outfit[itemName] ?? 0) + canTake;
      }
    }

    notifyListeners();
  }

  /// 吃肉
  void eatMeat() {
    final path = Path();
    if ((path.outfit['cured meat'] ?? 0) > 0) {
      path.outfit['cured meat'] = (path.outfit['cured meat'] ?? 0) - 1;
      final healing = World().meatHealAmount();
      final newHp = min(World().getMaxHealth(), World().health + healing);
      World().setHp(newHp);

      // AudioEngine().playSound('eat_meat'); // 暂时注释掉
      notifyListeners();
    }
  }

  /// 使用药物
  void useMeds() {
    final path = Path();
    if ((path.outfit['medicine'] ?? 0) > 0) {
      path.outfit['medicine'] = (path.outfit['medicine'] ?? 0) - 1;
      final healing = World().medsHealAmount();
      final newHp = min(World().getMaxHealth(), World().health + healing);
      World().setHp(newHp);

      // AudioEngine().playSound('use_meds'); // 暂时注释掉
      notifyListeners();
    }
  }

  /// 使用注射器
  void useHypo() {
    final path = Path();
    if ((path.outfit['hypo'] ?? 0) > 0) {
      path.outfit['hypo'] = (path.outfit['hypo'] ?? 0) - 1;
      final healing = World().hypoHealAmount();
      final newHp = min(World().getMaxHealth(), World().health + healing);
      World().setHp(newHp);

      // AudioEngine().playSound('use_meds'); // 暂时注释掉
      notifyListeners();
    }
  }

  /// 触发战斗
  void triggerFight() {
    // 创建一个简单的战斗事件
    final fightEvent = {
      'title': '遭遇敌人',
      'scenes': {
        'start': {
          'combat': true,
          'notification': '一个敌对生物出现了！',
          'chara': 'E',
          'health': 10,
          'damage': 2,
          'hit': 0.8,
          'attackDelay': 2,
          'deathMessage': '敌人被击败了',
          'loot': {
            'fur': {'min': 1, 'max': 3, 'chance': 0.8},
            'meat': {'min': 1, 'max': 2, 'chance': 0.6}
          }
        }
      }
    };

    startEvent(fightEvent);
  }

  /// 获取可用武器
  List<String> getAvailableWeapons() {
    final path = Path();
    final weapons = <String>[];

    for (final weaponName in World.weapons.keys) {
      final weapon = World.weapons[weaponName]!;
      final hasWeapon = (path.outfit[weaponName] ?? 0) > 0;

      if (hasWeapon || weaponName == 'fists') {
        // 检查弹药
        bool hasAmmo = true;
        if (weapon['cost'] != null) {
          final cost = weapon['cost'] as Map<String, dynamic>;
          for (final entry in cost.entries) {
            final required = entry.value as int;
            final available = path.outfit[entry.key] ?? 0;
            if (available < required) {
              hasAmmo = false;
              break;
            }
          }
        }

        if (hasAmmo) {
          weapons.add(weaponName);
        }
      }
    }

    return weapons;
  }

  /// 获取当前战斗状态
  Map<String, dynamic> getCombatStatus() {
    return {
      'inCombat': activeScene != null && activeEvent()?['scenes'][activeScene]?['combat'] == true,
      'playerHealth': World().health,
      'playerMaxHealth': World().getMaxHealth(),
      'availableWeapons': getAvailableWeapons(),
      'canHeal': World().health < World().getMaxHealth(),
      'fought': fought,
      'won': won,
    };
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    // 在Flutter中，状态更新将通过状态管理自动处理
    notifyListeners();
  }

  @override
  void dispose() {
    clearTimeouts();
    nextEventTimer?.cancel();
    super.dispose();
  }
}

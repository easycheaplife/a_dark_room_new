import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import 'path.dart';
import 'world.dart';
import 'setpieces.dart';
import '../core/logger.dart';

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

  // 动画状态
  String?
      currentAnimation; // 'melee_wanderer', 'melee_enemy', 'ranged_wanderer', 'ranged_enemy'
  int currentAnimationDamage = 0;

  // 敌人血量管理
  int currentEnemyHealth = 0;
  int maxEnemyHealth = 0;

  // 战斗胜利状态
  bool showingLoot = false;
  Map<String, int> currentLoot = {};

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

  /// 战斗遭遇事件列表 - 完整翻译自原游戏encounters.js
  List<Map<String, dynamic>> get encounters => [
        // Tier 1 - 距离 <= 10
        {
          'title': '咆哮的野兽',
          'isAvailable': () {
            final world = World();
            return world.getDistance() <= 10 && world.getTerrain() == ';'; // 森林
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'snarling beast',
              'enemyName': '咆哮的野兽',
              'deathMessage': '咆哮的野兽死了',
              'chara': 'R',
              'damage': 1,
              'hit': 0.8,
              'attackDelay': 1,
              'health': 5,
              'loot': {
                'fur': {'min': 1, 'max': 3, 'chance': 1.0},
                'meat': {'min': 1, 'max': 3, 'chance': 1.0},
                'teeth': {'min': 1, 'max': 3, 'chance': 0.8}
              },
              'notification': '一只咆哮的野兽从灌木丛中跳了出来'
            }
          }
        },
        {
          'title': '憔悴的人',
          'isAvailable': () {
            final world = World();
            return world.getDistance() <= 10 && world.getTerrain() == '.'; // 荒地
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'gaunt man',
              'enemyName': '憔悴的人',
              'deathMessage': '憔悴的人死了',
              'chara': 'E',
              'damage': 2,
              'hit': 0.8,
              'attackDelay': 2,
              'health': 6,
              'loot': {
                'cloth': {'min': 1, 'max': 3, 'chance': 0.8},
                'teeth': {'min': 1, 'max': 2, 'chance': 0.8},
                'leather': {'min': 1, 'max': 2, 'chance': 0.5}
              },
              'notification': '一个憔悴的人走近，眼中带着疯狂的神色'
            }
          }
        },
        {
          'title': '奇怪的鸟',
          'isAvailable': () {
            final world = World();
            return world.getDistance() <= 10 && world.getTerrain() == ','; // 田野
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'strange bird',
              'enemyName': '奇怪的鸟',
              'deathMessage': '奇怪的鸟死了',
              'chara': 'R',
              'damage': 3,
              'hit': 0.8,
              'attackDelay': 2,
              'health': 4,
              'loot': {
                'scales': {'min': 1, 'max': 3, 'chance': 0.8},
                'teeth': {'min': 1, 'max': 2, 'chance': 0.5},
                'meat': {'min': 1, 'max': 3, 'chance': 0.8}
              },
              'notification': '一只奇怪的鸟在平原上快速穿过'
            }
          }
        },
        // Tier 2 - 距离 10-20
        {
          'title': '颤抖的人',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 10 &&
                world.getDistance() <= 20 &&
                world.getTerrain() == '.'; // 荒地
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'shivering man',
              'enemyName': '颤抖的人',
              'deathMessage': '颤抖的人死了',
              'chara': 'E',
              'damage': 5,
              'hit': 0.5,
              'attackDelay': 1,
              'health': 20,
              'loot': {
                'cloth': {'min': 1, 'max': 1, 'chance': 0.2},
                'teeth': {'min': 1, 'max': 2, 'chance': 0.8},
                'leather': {'min': 1, 'max': 1, 'chance': 0.2},
                'medicine': {'min': 1, 'max': 3, 'chance': 0.7}
              },
              'notification': '一个颤抖的人走近，以惊人的力量发起攻击'
            }
          }
        },
        {
          'title': '食人者',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 10 &&
                world.getDistance() <= 20 &&
                world.getTerrain() == ';'; // 森林
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'man-eater',
              'enemyName': '食人者',
              'deathMessage': '食人者死了',
              'chara': 'T',
              'damage': 3,
              'hit': 0.8,
              'attackDelay': 1,
              'health': 25,
              'loot': {
                'fur': {'min': 5, 'max': 10, 'chance': 1.0},
                'meat': {'min': 5, 'max': 10, 'chance': 1.0},
                'teeth': {'min': 5, 'max': 10, 'chance': 0.8}
              },
              'notification': '一只大型生物发起攻击，爪子上还沾着新鲜的血迹'
            }
          }
        },
        {
          'title': '拾荒者',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 10 &&
                world.getDistance() <= 20 &&
                world.getTerrain() == '.'; // 荒地
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'scavenger',
              'enemyName': '拾荒者',
              'deathMessage': '拾荒者死了',
              'chara': 'E',
              'damage': 4,
              'hit': 0.8,
              'attackDelay': 2,
              'health': 30,
              'loot': {
                'cloth': {'min': 5, 'max': 10, 'chance': 0.8},
                'leather': {'min': 5, 'max': 10, 'chance': 0.8},
                'iron': {'min': 1, 'max': 5, 'chance': 0.5},
                'medicine': {'min': 1, 'max': 2, 'chance': 0.1}
              },
              'notification': '一个拾荒者靠近，希望能轻松得手'
            }
          }
        },
        {
          'title': '巨大蜥蜴',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 10 &&
                world.getDistance() <= 20 &&
                world.getTerrain() == ','; // 田野
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'lizard',
              'enemyName': '蜥蜴',
              'deathMessage': '蜥蜴死了',
              'chara': 'T',
              'damage': 5,
              'hit': 0.8,
              'attackDelay': 2,
              'health': 20,
              'loot': {
                'scales': {'min': 5, 'max': 10, 'chance': 0.8},
                'teeth': {'min': 5, 'max': 10, 'chance': 0.5},
                'meat': {'min': 5, 'max': 10, 'chance': 0.8}
              },
              'notification': '草丛剧烈摇摆，一只巨大的蜥蜴冲了出来'
            }
          }
        },
        // Tier 3 - 距离 > 20
        {
          'title': '野性恐兽',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 20 && world.getTerrain() == ';'; // 森林
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'feral terror',
              'enemyName': '野性恐兽',
              'deathMessage': '野性恐兽死了',
              'chara': 'T',
              'damage': 6,
              'hit': 0.8,
              'attackDelay': 1,
              'health': 45,
              'loot': {
                'fur': {'min': 5, 'max': 10, 'chance': 1.0},
                'meat': {'min': 5, 'max': 10, 'chance': 1.0},
                'teeth': {'min': 5, 'max': 10, 'chance': 0.8}
              },
              'notification': '一只比想象中更野性的野兽从树叶中爆发而出'
            }
          }
        },
        {
          'title': '士兵',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 20 && world.getTerrain() == '.'; // 荒地
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'soldier',
              'enemyName': '士兵',
              'deathMessage': '士兵死了',
              'ranged': true,
              'chara': 'D',
              'damage': 8,
              'hit': 0.8,
              'attackDelay': 2,
              'health': 50,
              'loot': {
                'cloth': {'min': 5, 'max': 10, 'chance': 0.8},
                'bullets': {'min': 1, 'max': 5, 'chance': 0.5},
                'rifle': {'min': 1, 'max': 1, 'chance': 0.2},
                'medicine': {'min': 1, 'max': 2, 'chance': 0.1}
              },
              'notification': '一名士兵从沙漠对面开火'
            }
          }
        },
        {
          'title': '狙击手',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 20 && world.getTerrain() == ','; // 田野
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'sniper',
              'enemyName': '狙击手',
              'deathMessage': '狙击手死了',
              'chara': 'D',
              'damage': 15,
              'hit': 0.8,
              'attackDelay': 4,
              'health': 30,
              'ranged': true,
              'loot': {
                'cloth': {'min': 5, 'max': 10, 'chance': 0.8},
                'bullets': {'min': 1, 'max': 5, 'chance': 0.5},
                'rifle': {'min': 1, 'max': 1, 'chance': 0.2},
                'medicine': {'min': 1, 'max': 2, 'chance': 0.1}
              },
              'notification': '枪声响起，来自长草丛中的某个地方'
            }
          }
        },
      ];

  /// 加载场景
  void loadScene(String sceneName) {
    // Engine().log('加载场景: $sceneName'); // 暂时注释掉
    activeScene = sceneName;
    final event = activeEvent();
    if (event == null) return;

    final scene = event['scenes'][sceneName];
    if (scene == null) return;

    // onLoad 回调 - 支持函数和字符串形式
    if (scene['onLoad'] != null) {
      final onLoad = scene['onLoad'];
      if (onLoad is Function) {
        onLoad();
      } else if (onLoad is String) {
        // 处理字符串形式的回调
        _handleOnLoadCallback(onLoad);
      }
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

    // 初始化敌人血量
    currentEnemyHealth = scene['health'] ?? 10;
    maxEnemyHealth = scene['health'] ?? 10;

    // 设置敌人攻击定时器
    final attackDelay = scene['attackDelay'];
    startEnemyAttacks(attackDelay != null ? attackDelay.toDouble() : 2.0);

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
    // 如果场景有战利品，生成战利品
    if (scene['loot'] != null) {
      showingLoot = true;
      final loot = scene['loot'] as Map<String, dynamic>;
      drawLoot(loot);
    }

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

    final sceneDelay = scene['attackDelay'];
    final attackDelay =
        delay ?? (sceneDelay != null ? sceneDelay.toDouble() : 2.0);
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

  /// 近战动画 - 参考原游戏的animateMelee函数
  void animateMelee(String fighterId, int dmg, VoidCallback? callback) {
    Logger.info('🎬 执行近战动画: $fighterId 造成 $dmg 伤害');

    // 设置动画状态
    currentAnimation = 'melee_$fighterId';
    currentAnimationDamage = dmg;
    notifyListeners(); // 触发UI更新以显示动画

    // 延迟模拟动画时间
    Timer(Duration(milliseconds: fightSpeed), () {
      final enemy = fighterId == 'wanderer' ? 'enemy' : 'wanderer';
      damage(fighterId, enemy, dmg, 'melee');

      // 动画结束后的回调
      Timer(Duration(milliseconds: fightSpeed), () {
        currentAnimation = null;
        currentAnimationDamage = 0;
        notifyListeners();
        callback?.call();
      });
    });
  }

  /// 远程动画 - 参考原游戏的animateRanged函数
  void animateRanged(String fighterId, int dmg, VoidCallback? callback) {
    Logger.info('🎬 执行远程动画: $fighterId 造成 $dmg 伤害');

    // 设置动画状态
    currentAnimation = 'ranged_$fighterId';
    currentAnimationDamage = dmg;
    notifyListeners(); // 触发UI更新以显示动画

    // 延迟模拟子弹飞行时间
    Timer(Duration(milliseconds: fightSpeed * 2), () {
      final enemy = fighterId == 'wanderer' ? 'enemy' : 'wanderer';
      damage(fighterId, enemy, dmg, 'ranged');

      currentAnimation = null;
      currentAnimationDamage = 0;
      notifyListeners();
      callback?.call();
    });
  }

  /// 造成伤害
  void damage(String fighterId, String enemyId, int dmg, String type) {
    if (dmg <= 0) return; // 未命中

    if (enemyId == 'wanderer') {
      // 对玩家造成伤害
      final newHp = max(0, World().health - dmg);
      World().setHp(newHp);
    } else {
      // 对敌人造成伤害
      currentEnemyHealth = max(0, currentEnemyHealth - dmg);
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

  /// 获取战斗状态
  Map<String, dynamic> getCombatStatus() {
    final event = activeEvent();
    if (event == null) {
      return {'inCombat': false};
    }

    final scene = event['scenes']?[activeScene];
    final inCombat = scene?['combat'] == true;

    return {
      'inCombat': inCombat,
      'enemy': scene?['enemy'],
      'enemyName': scene?['enemyName'],
      'enemyHealth': scene?['health'],
      'enemyMaxHealth': scene?['health'],
    };
  }

  /// 安排下一个事件
  void scheduleNextEvent() {
    final random = Random();
    final delay = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
        eventTimeRange[0];

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

    // 重置战斗相关状态
    showingLoot = false;
    currentLoot.clear();
    currentEnemyHealth = 0;
    maxEnemyHealth = 0;
    currentAnimation = null;
    currentAnimationDamage = 0;

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

      // 消耗弹药并同步到StateManager
      final sm = StateManager();
      for (final entry in cost.entries) {
        final required = entry.value as int;
        final newAmount = (path.outfit[entry.key] ?? 0) - required;
        path.outfit[entry.key] = newAmount;
        // 同步保存到StateManager
        sm.set('outfit["${entry.key}"]', newAmount);
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
    if (currentEnemyHealth <= 0 && !won) {
      won = true;
      winFight();
    }
  }

  /// 胜利战斗 - 参考原游戏的winFight函数
  void winFight() {
    if (fought) return;

    Timer(Duration(milliseconds: fightSpeed), () {
      if (fought) return;

      endFight();

      // 播放胜利音效（暂时注释掉）
      // AudioEngine().playSound(AudioLibrary.WIN_FIGHT);

      // 敌人消失动画延迟
      Timer(const Duration(milliseconds: 1000), () {
        final event = activeEvent();
        if (event == null) return;

        final scene = event['scenes'][activeScene];
        if (scene == null) return;

        // 显示死亡消息和战利品 - 参考原游戏逻辑
        showingLoot = true;
        final loot = scene['loot'] as Map<String, dynamic>? ?? {};
        drawLoot(loot);

        // 注意：原游戏的winFight不会自动回到小黑屋
        // 只是显示战利品界面，玩家可以选择离开
        // 只有loseFight才会调用World.die()回到小黑屋

        notifyListeners();
      });
    });
  }

  /// 结束战斗
  void endFight() {
    fought = true;
    clearTimeouts();
  }

  /// 绘制战利品 - 参考原游戏的drawLoot函数
  void drawLoot(Map<String, dynamic> lootList) {
    Logger.info('🎁 开始生成战利品，战利品列表: $lootList');
    currentLoot.clear();

    for (final entry in lootList.entries) {
      final loot = entry.value as Map<String, dynamic>;
      final chance = (loot['chance'] ?? 1.0) as double;
      final randomValue = Random().nextDouble();

      Logger.info('🎁 物品: ${entry.key}, 概率: $chance, 随机值: $randomValue');

      if (randomValue < chance) {
        final min = (loot['min'] ?? 1) as int;
        final max = (loot['max'] ?? 1) as int;
        final num = Random().nextInt(max - min + 1) + min;
        currentLoot[entry.key] = num;
        Logger.info('🎁 生成战利品: ${entry.key} x$num');
      } else {
        Logger.info('🎁 未生成战利品: ${entry.key} (概率不足)');
      }
    }

    Logger.info('🎁 最终战利品: $currentLoot');
    notifyListeners();
  }

  /// 获取战利品 - 参考原游戏的getLoot函数
  void getLoot(String itemName, int amount) {
    Logger.info('🎒 获取战利品: $itemName x$amount');

    final path = Path();
    final weight = path.getWeight(itemName);
    final freeSpace = path.getFreeSpace();

    Logger.info('🎒 物品重量: $weight, 剩余空间: $freeSpace');

    final canTake = min(amount, (freeSpace / weight).floor());
    Logger.info('🎒 可以拿取: $canTake');

    if (canTake > 0) {
      // 更新装备 - 同时更新Path.outfit和StateManager
      final oldAmount = path.outfit[itemName] ?? 0;
      path.outfit[itemName] = oldAmount + canTake;

      Logger.info(
          '🎒 更新装备: $itemName 从 $oldAmount 增加到 ${path.outfit[itemName]}');

      // 从当前战利品中移除已拾取的数量
      if (currentLoot.containsKey(itemName)) {
        final oldLootAmount = currentLoot[itemName] ?? 0;
        currentLoot[itemName] = oldLootAmount - canTake;
        Logger.info(
            '🎒 战利品剩余: $itemName 从 $oldLootAmount 减少到 ${currentLoot[itemName]}');

        if (currentLoot[itemName]! <= 0) {
          currentLoot.remove(itemName);
          Logger.info('🎒 战利品已全部拾取: $itemName');
        }
      }

      // 保存到StateManager - 确保数据持久化
      final sm = StateManager();
      sm.set('outfit["$itemName"]', path.outfit[itemName]);

      // 通知Path模块更新
      path.updateOutfitting();

      // 显示获取通知
      NotificationManager()
          .notify(name, '获得了 ${_getItemDisplayName(itemName)} x$canTake');
    } else {
      Logger.info('🎒 背包空间不足，无法拾取');
      NotificationManager().notify(name, '背包空间不足');
    }

    notifyListeners();
  }

  /// 获取物品显示名称 - 用于通知
  String _getItemDisplayName(String itemName) {
    switch (itemName) {
      case 'fur':
        return '毛皮';
      case 'meat':
        return '肉';
      case 'scales':
        return '鳞片';
      case 'teeth':
        return '牙齿';
      case 'cloth':
        return '布料';
      case 'leather':
        return '皮革';
      case 'iron':
        return '铁';
      case 'coal':
        return '煤炭';
      case 'steel':
        return '钢铁';
      case 'sulphur':
        return '硫磺';
      case 'energy cell':
        return '能量电池';
      case 'bullets':
        return '子弹';
      case 'medicine':
        return '药物';
      case 'cured meat':
        return '熏肉';
      case 'rifle':
        return '步枪';
      default:
        return itemName;
    }
  }

  /// 吃肉
  void eatMeat() {
    final path = Path();
    if ((path.outfit['cured meat'] ?? 0) > 0) {
      final newAmount = (path.outfit['cured meat'] ?? 0) - 1;
      path.outfit['cured meat'] = newAmount;

      // 同步保存到StateManager
      final sm = StateManager();
      sm.set('outfit["cured meat"]', newAmount);

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
      final newAmount = (path.outfit['medicine'] ?? 0) - 1;
      path.outfit['medicine'] = newAmount;

      // 同步保存到StateManager
      final sm = StateManager();
      sm.set('outfit["medicine"]', newAmount);

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
      final newAmount = (path.outfit['hypo'] ?? 0) - 1;
      path.outfit['hypo'] = newAmount;

      // 同步保存到StateManager
      final sm = StateManager();
      sm.set('outfit["hypo"]', newAmount);

      final healing = World().hypoHealAmount();
      final newHp = min(World().getMaxHealth(), World().health + healing);
      World().setHp(newHp);

      // AudioEngine().playSound('use_meds'); // 暂时注释掉
      notifyListeners();
    }
  }

  /// 获取可用武器列表
  List<String> getAvailableWeapons() {
    final path = Path();
    final availableWeapons = <String>[];

    // 总是可用的拳头
    availableWeapons.add('fists');

    // 检查背包中的武器
    for (final weaponName in World.weapons.keys) {
      if (weaponName != 'fists' && (path.outfit[weaponName] ?? 0) > 0) {
        availableWeapons.add(weaponName);
      }
    }

    return availableWeapons;
  }

  /// 获取当前敌人血量
  int getCurrentEnemyHealth() {
    return currentEnemyHealth;
  }

  /// 触发战斗
  void triggerFight() {
    Logger.info('🎯 Events.triggerFight() 被调用');

    final possibleFights = <Map<String, dynamic>>[];

    // 检查所有可用的战斗事件
    for (final fight in encounters) {
      if (fight['isAvailable']()) {
        possibleFights.add(fight);
      }
    }

    Logger.info('🎯 可用战斗事件数量: ${possibleFights.length}');

    if (possibleFights.isNotEmpty) {
      // 随机选择一个战斗事件
      final r = Random().nextInt(possibleFights.length);
      final selectedFight = possibleFights[r];

      Logger.info('🎯 选择的战斗事件: ${selectedFight['title']}');

      // 触发战斗事件
      startEvent(selectedFight);

      // 播放战斗音乐（根据距离选择不同层级）
      final world = World();
      final distance = world.getDistance();

      if (distance > 20) {
        // Tier 3
        Logger.info('🎵 播放Tier 3战斗音乐');
      } else if (distance > 10) {
        // Tier 2
        Logger.info('🎵 播放Tier 2战斗音乐');
      } else {
        // Tier 1
        Logger.info('🎵 播放Tier 1战斗音乐');
      }
    } else {
      Logger.info('⚠️ 没有可用的战斗事件');
    }
  }

  /// 触发地标事件
  void triggerSetpiece(String setpieceName) {
    Logger.info('🏛️ Events.triggerSetpiece() 被调用: $setpieceName');
    final setpiece = Setpieces.setpieces[setpieceName];
    if (setpiece != null) {
      startEvent(setpiece);
    } else {
      Logger.info('⚠️ 未找到地标事件: $setpieceName');
    }
  }

  /// 处理onLoad回调 - 根据字符串名称调用相应的方法
  void _handleOnLoadCallback(String callbackName) {
    switch (callbackName) {
      case 'useOutpost':
        Setpieces().useOutpost();
        break;
      case 'addGastronomePerk':
        Setpieces().addGastronomePerk();
        break;
      case 'clearDungeon':
        Setpieces().clearDungeon();
        break;
      case 'markVisited':
        Setpieces().markVisited();
        break;
      case 'replenishWater':
        Setpieces().replenishWater();
        break;
      case 'clearIronMine':
        Setpieces().clearIronMine();
        break;
      case 'clearCoalMine':
        Setpieces().clearCoalMine();
        break;
      case 'clearSulphurMine':
        Setpieces().clearSulphurMine();
        break;
      default:
        Logger.info('⚠️ 未知的onLoad回调: $callbackName');
        break;
    }
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

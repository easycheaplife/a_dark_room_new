import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import '../core/localization.dart';
import '../core/visibility_manager.dart';
import 'path.dart';
import 'world.dart';
import 'setpieces.dart';
import '../core/logger.dart';
import '../config/game_config.dart';
import '../events/global_events.dart';
import '../events/room_events.dart';
import '../events/outside_events.dart';
import '../events/world_events.dart';
import '../events/executioner_events.dart';

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
  String get name {
    final localization = Localization();
    return localization.translate('events.name');
  }

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
  bool enemyStunned = false; // 敌人眩晕状态

  // 敌人状态管理
  String? enemyStatus; // 当前敌人状态：shield, enraged, meditation等
  String? lastSpecialStatus; // 上次使用的特殊状态，用于避免重复

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
      ...GlobalEvents.events,
      ...RoomEvents.events,
      ...OutsideEvents.events,
      ...WorldEvents.events,
      ...encounters, // 保留原有的战斗遭遇事件
    ];

    eventStack = [];
    scheduleNextEvent();

    // 检查存储的延迟事件
    initDelay();

    notifyListeners();
  }

  /// 战斗遭遇事件列表 - 完整翻译自原游戏encounters.js
  List<Map<String, dynamic>> get encounters => [
        // Tier 1 - 距离 <= 10
        {
          'title': 'outside_events.encounters.snarling_beast.title',
          'isAvailable': () {
            final world = World();
            return world.getDistance() <= 10 && world.getTerrain() == ';'; // 森林
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'snarling beast',
              'enemyName':
                  'outside_events.encounters.snarling_beast.enemy_name',
              'deathMessage':
                  'outside_events.encounters.snarling_beast.death_message',
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
              'notification':
                  'outside_events.encounters.snarling_beast.notification'
            }
          }
        },
        {
          'title': 'outside_events.encounters.gaunt_man.title',
          'isAvailable': () {
            final world = World();
            return world.getDistance() <= 10 && world.getTerrain() == '.'; // 荒地
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'gaunt man',
              'enemyName': 'outside_events.encounters.gaunt_man.enemy_name',
              'deathMessage':
                  'outside_events.encounters.gaunt_man.death_message',
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
              'notification': 'outside_events.encounters.gaunt_man.notification'
            }
          }
        },
        {
          'title': 'outside_events.encounters.strange_bird.title',
          'isAvailable': () {
            final world = World();
            return world.getDistance() <= 10 && world.getTerrain() == ','; // 田野
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'strange bird',
              'enemyName': 'outside_events.encounters.strange_bird.enemy_name',
              'deathMessage':
                  'outside_events.encounters.strange_bird.death_message',
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
              'notification':
                  'outside_events.encounters.strange_bird.notification'
            }
          }
        },
        // Tier 2 - 距离 10-20
        {
          'title': 'outside_events.encounters.shivering_man.title',
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
              'enemyName': 'outside_events.encounters.shivering_man.enemy_name',
              'deathMessage':
                  'outside_events.encounters.shivering_man.death_message',
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
              'notification':
                  'outside_events.encounters.shivering_man.notification'
            }
          }
        },
        {
          'title': 'outside_events.encounters.man_eater.title',
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
              'enemyName': 'outside_events.encounters.man_eater.enemy_name',
              'deathMessage':
                  'outside_events.encounters.man_eater.death_message',
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'outside_events.encounters.man_eater.notification');
              }()
            }
          }
        },
        {
          'title': 'outside_events.encounters.scavenger.title',
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
              'enemyName': 'outside_events.encounters.scavenger.enemy_name',
              'deathMessage':
                  'outside_events.encounters.scavenger.death_message',
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'outside_events.encounters.scavenger.notification');
              }()
            }
          }
        },
        {
          'title': 'outside_events.encounters.lizard.title',
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
              'enemyName': 'outside_events.encounters.lizard.enemy_name',
              'deathMessage': 'outside_events.encounters.lizard.death_message',
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('outside_events.encounters.lizard.notification');
              }()
            }
          }
        },
        // Tier 3 - 距离 > 20
        {
          'title': 'outside_events.encounters.feral_terror.title',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 20 && world.getTerrain() == ';'; // 森林
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'feral terror',
              'enemyName': 'outside_events.encounters.feral_terror.enemy_name',
              'deathMessage':
                  'outside_events.encounters.feral_terror.death_message',
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'outside_events.encounters.feral_terror.notification');
              }()
            }
          }
        },
        {
          'title': 'outside_events.encounters.soldier.title',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 20 && world.getTerrain() == '.'; // 荒地
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'soldier',
              'enemyName': 'outside_events.encounters.soldier.enemy_name',
              'deathMessage': 'outside_events.encounters.soldier.death_message',
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
              'notification': () {
                final localization = Localization();
                return localization.translate(
                    'outside_events.encounters.soldier.notification');
              }()
            }
          }
        },
        {
          'title': 'outside_events.encounters.sniper.title',
          'isAvailable': () {
            final world = World();
            return world.getDistance() > 20 && world.getTerrain() == ','; // 田野
          },
          'scenes': {
            'start': {
              'combat': true,
              'enemy': 'sniper',
              'enemyName': 'outside_events.encounters.sniper.enemy_name',
              'deathMessage': 'outside_events.encounters.sniper.death_message',
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
              'notification': () {
                final localization = Localization();
                return localization
                    .translate('outside_events.encounters.sniper.notification');
              }()
            }
          }
        },
      ];

  /// 加载场景
  void loadScene(String sceneName) {
    Logger.info('🎬 Events.loadScene() 被调用: $sceneName');
    activeScene = sceneName;
    final event = activeEvent();
    if (event == null) {
      Logger.info('⚠️ 没有活动事件');
      return;
    }

    final scene = event['scenes'][sceneName];
    if (scene == null) {
      Logger.error('⚠️ 场景不存在: $sceneName');
      Logger.error('⚠️ 可用场景: ${event['scenes'].keys.toList()}');
      endEvent(); // 场景不存在时结束事件
      return;
    }

    Logger.info('🎬 成功加载场景: $sceneName');

    // onLoad 回调 - 支持函数和字符串形式
    if (scene['onLoad'] != null) {
      final onLoad = scene['onLoad'];
      Logger.info('🔧 场景有onLoad回调: $onLoad');
      if (onLoad is Function) {
        Logger.info('🔧 执行函数形式的onLoad回调');
        onLoad();
      } else if (onLoad is String) {
        Logger.info('🔧 执行字符串形式的onLoad回调: $onLoad');
        // 处理字符串形式的回调
        _handleOnLoadCallback(onLoad);
      }
    } else {
      Logger.info('🔧 场景没有onLoad回调');
    }

    // 场景通知
    if (scene['notification'] != null) {
      NotificationManager().notify(name, scene['notification']);
    }

    // 场景奖励
    if (scene['reward'] != null) {
      final sm = StateManager();
      final reward = scene['reward'] as Map<String, dynamic>;
      final localization = Localization();
      for (final entry in reward.entries) {
        sm.add('stores["${entry.key}"]', entry.value);

        // 显示获得奖励的通知
        final itemDisplayName =
            localization.translate('resources.${entry.key}');
        final displayName = itemDisplayName != 'resources.${entry.key}'
            ? itemDisplayName
            : entry.key;
        NotificationManager().notify(
            name,
            localization.translate('world.notifications.found_item',
                [displayName, entry.value.toString()]));

        Logger.info('🎁 场景奖励: ${entry.key} +${entry.value}');
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
    Logger.info('⚔️ 开始战斗: ${scene['enemy']}');
    Engine().event('game event', 'combat');

    // 重置战斗状态
    fought = false;
    won = false;
    showingLoot = false;
    currentLoot.clear();
    currentAnimation = null;
    currentAnimationDamage = 0;
    enemyStunned = false; // 重置眩晕状态

    // 初始化敌人血量
    currentEnemyHealth = scene['health'] ?? 10;
    maxEnemyHealth = scene['health'] ?? 10;
    Logger.info('⚔️ 敌人血量初始化: $currentEnemyHealth/$maxEnemyHealth');

    // 设置敌人攻击定时器
    final attackDelay = scene['attackDelay'];
    startEnemyAttacks(attackDelay != null ? attackDelay.toDouble() : 2.0);

    // 设置特殊技能定时器
    final specials = scene['specials'] as List<Map<String, dynamic>>? ?? [];
    for (final special in specials) {
      final timer = VisibilityManager().createPeriodicTimer(
          Duration(
              milliseconds:
                  ((special['delay'] ?? GameConfig.specialSkillDelay / 1000) *
                          1000)
                      .round()), () {
        // 执行特殊技能
        if (special['action'] != null) {
          special['action']();
        }
      }, 'Events.specialTimer');
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
    final attackDelay = delay ??
        (sceneDelay != null
            ? sceneDelay.toDouble()
            : GameConfig.defaultAttackDelay / 1000);
    enemyAttackTimer = VisibilityManager().createPeriodicTimer(
        Duration(milliseconds: (attackDelay * 1000).round()),
        () => enemyAttack(),
        'Events.enemyAttackTimer');
  }

  /// 敌人攻击
  void enemyAttack() {
    // 检查战斗是否已经结束或敌人是否已死亡
    if (fought || won || currentEnemyHealth <= 0) {
      Logger.info(
          '⚔️ 敌人攻击被阻止: fought=$fought, won=$won, enemyHealth=$currentEnemyHealth');
      return;
    }

    // 检查敌人是否被眩晕
    if (enemyStunned) {
      Logger.info('😵 敌人被眩晕，跳过攻击');
      return;
    }

    final event = activeEvent();
    if (event == null) return;

    final scene = event['scenes'][activeScene];
    if (scene == null) return;

    double toHit = (scene['hit'] ?? 0.8).toDouble();
    // 闪避技能：减少20%被击中概率
    if (StateManager().hasPerk('evasive')) {
      toHit *= 0.8;
    }

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
    animateMeleeWithType(fighterId, dmg, 'melee', callback);
  }

  /// 近战动画（支持自定义伤害类型）
  void animateMeleeWithType(
      String fighterId, int dmg, String damageType, VoidCallback? callback) {
    Logger.info('🎬 执行近战动画: $fighterId 造成 $dmg 伤害 (类型: $damageType)');

    // 设置动画状态
    currentAnimation = 'melee_$fighterId';
    currentAnimationDamage = dmg;
    notifyListeners(); // 触发UI更新以显示动画

    // 延迟模拟动画时间
    VisibilityManager().createTimer(Duration(milliseconds: fightSpeed), () {
      final enemy = fighterId == 'wanderer' ? 'enemy' : 'wanderer';
      damage(fighterId, enemy, dmg, damageType);

      // 动画结束后的回调
      VisibilityManager().createTimer(Duration(milliseconds: fightSpeed), () {
        currentAnimation = null;
        currentAnimationDamage = 0;
        notifyListeners();
        callback?.call();
      }, 'Events.meleeAnimationEnd');
    }, 'Events.meleeAnimation');
  }

  /// 远程动画 - 参考原游戏的animateRanged函数
  void animateRanged(String fighterId, int dmg, VoidCallback? callback) {
    animateRangedWithType(fighterId, dmg, 'ranged', callback);
  }

  /// 远程动画（支持自定义伤害类型）
  void animateRangedWithType(
      String fighterId, int dmg, String damageType, VoidCallback? callback) {
    Logger.info('🎬 执行远程动画: $fighterId 造成 $dmg 伤害 (类型: $damageType)');

    // 设置动画状态
    currentAnimation = 'ranged_$fighterId';
    currentAnimationDamage = dmg;
    notifyListeners(); // 触发UI更新以显示动画

    // 延迟模拟子弹飞行时间
    VisibilityManager()
        .createTimer(Duration(milliseconds: GameConfig.rangedAttackDelay), () {
      final enemy = fighterId == 'wanderer' ? 'enemy' : 'wanderer';
      damage(fighterId, enemy, dmg, damageType);

      currentAnimation = null;
      currentAnimationDamage = 0;
      notifyListeners();
      callback?.call();
    }, 'Events.rangedAnimation');
  }

  /// 造成伤害
  void damage(String fighterId, String enemyId, int dmg, String type) {
    Logger.info('⚔️ damage() 被调用: $fighterId -> $enemyId, 伤害=$dmg, 类型=$type');

    // 检查战斗是否已经结束
    if (fought || won || World().dead) {
      Logger.info(
          '⚔️ 战斗已结束或玩家已死亡，跳过伤害处理: fought=$fought, won=$won, dead=${World().dead}');
      return;
    }

    if (dmg < 0) {
      Logger.info('⚔️ 伤害为负数，未命中');
      return; // 未命中
    }

    if (enemyId == 'wanderer') {
      // 对玩家造成伤害
      final oldHp = World().health;
      final newHp = max(0, oldHp - dmg);
      Logger.info('⚔️ 玩家受到伤害: $oldHp -> $newHp (伤害=$dmg)');
      World().setHp(newHp);
    } else {
      // 对敌人造成伤害
      if (dmg == 0 && type == 'stun') {
        // 眩晕效果：不造成伤害但使敌人眩晕
        enemyStunned = true;
        Logger.info('😵 敌人被眩晕，持续$stunDuration毫秒');

        // 设置眩晕持续时间
        VisibilityManager().createTimer(Duration(milliseconds: stunDuration),
            () {
          enemyStunned = false;
          Logger.info('😵 敌人眩晕效果结束');
          notifyListeners();
        }, 'Events.stunEffect');
      } else {
        // 普通伤害
        currentEnemyHealth = max(0, currentEnemyHealth - dmg);
      }
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
    final currentHealth = World().health;
    final isDead = World().dead;
    Logger.info(
        '💀 checkPlayerDeath() 被调用 - 当前血量: $currentHealth, 已死亡: $isDead');
    Logger.info('💀 checkPlayerDeath() 调用栈: ${StackTrace.current}');

    // 如果已经死亡，避免重复处理
    if (isDead) {
      Logger.info('💀 玩家已经死亡，跳过重复处理');
      return true;
    }

    if (currentHealth <= 0) {
      Logger.info('💀 血量<=0，触发死亡流程');
      clearTimeouts();
      endEvent();
      World().die();
      return true;
    }
    Logger.info('💀 血量>0，玩家存活');
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
  void scheduleNextEvent([double scale = 1.0]) {
    final random = Random();
    var delay = random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1) +
        eventTimeRange[0];

    // 应用时间缩放（用于重试机制）
    if (scale != 1.0) {
      delay = (delay * scale).round();
      Logger.info('🎭 应用时间缩放 $scale x，下次事件安排在 $delay 分钟后');
    } else {
      Logger.info('🎭 下次事件安排在 $delay 分钟后');
    }

    nextEventTimer = VisibilityManager().createTimer(Duration(minutes: delay),
        () => triggerEvent(), 'Events.nextEventTimer');
  }

  /// 触发事件
  void triggerEvent() {
    // 如果当前有活动事件，跳过触发
    if (activeEvent() != null) {
      Logger.info('🎭 当前有活动事件，跳过触发');
      scheduleNextEvent();
      return;
    }

    // 使用全局事件池，参考原游戏逻辑
    final allEvents = [
      ...GlobalEvents.events,
      ...RoomEvents.events,
      ...OutsideEvents.events,
      // 世界事件在世界模块中单独处理
    ];

    Logger.info('🎭 开始事件触发检查，总事件数量: ${allEvents.length}');

    // 筛选可用的事件
    final availableEvents = <Map<String, dynamic>>[];
    for (final event in allEvents) {
      if (isEventAvailable(event)) {
        availableEvents.add(event);
      }
    }

    Logger.info('🎭 可用事件数量: ${availableEvents.length}/${allEvents.length}');

    if (availableEvents.isEmpty) {
      // 实现原游戏的重试机制：无可用事件时0.5倍时间后重试
      Logger.info('🎭 没有可用事件，将在较短时间后重试');
      scheduleNextEvent(0.5);
      return;
    }

    // 随机选择一个可用事件
    final random = Random();
    final event = availableEvents[random.nextInt(availableEvents.length)];
    Logger.info('🎭 触发事件: ${event['title']}');

    startEvent(event);
    scheduleNextEvent();
  }

  /// 检查事件是否可用
  bool isEventAvailable(Map<String, dynamic> event) {
    final isAvailable = event['isAvailable'];
    if (isAvailable is Function) {
      try {
        return isAvailable();
      } catch (e) {
        Logger.error('🎭 检查事件可用性时出错: ${event['title']} - $e');
        return false;
      }
    }
    return true; // 如果没有可用性检查函数，默认可用
  }

  /// 开始事件
  void startEvent(Map<String, dynamic> event) {
    eventStack.add(event);
    final firstScene = event['scenes'].keys.first;
    loadScene(firstScene);
  }

  /// 根据事件名称开始事件
  void startEventByName(String eventName) {
    Logger.info('🎭 尝试启动事件: $eventName');

    // 检查executioner事件
    if (ExecutionerEvents.events.containsKey(eventName)) {
      final event = ExecutionerEvents.events[eventName]!;
      Logger.info('🔮 启动执行者事件: $eventName');
      startEvent(event);
      return;
    }

    Logger.info('⚠️ 未找到事件: $eventName');
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
    enemyStunned = false; // 重置眩晕状态

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
    double hitChance = World().getHitChance();

    // 精准技能：增加10%命中率
    if (StateManager().hasPerk('precise')) {
      hitChance += 0.1;
    }

    if (Random().nextDouble() <= hitChance) {
      final weaponDamage = weapon['damage'];

      // 处理特殊伤害类型（如stun）
      if (weaponDamage == 'stun') {
        dmg = 0; // stun不造成数值伤害，但会产生眩晕效果
      } else {
        dmg = weaponDamage ?? 1;
      }

      // 技能加成
      final weaponType = weapon['type'] ?? 'unarmed';

      // 拳击手技能：徒手伤害翻倍
      if (weaponType == 'unarmed' && StateManager().hasPerk('boxer')) {
        dmg *= 2;
      }

      // 武术家技能：徒手伤害额外加成
      if (weaponType == 'unarmed' && StateManager().hasPerk('martial artist')) {
        dmg = (dmg * 1.5).round();
      }

      // 徒手大师技能：徒手伤害更大加成
      if (weaponType == 'unarmed' && StateManager().hasPerk('unarmed master')) {
        dmg *= 2;
      }

      // 野蛮人技能：近战武器伤害加成
      if (weaponType == 'melee' && StateManager().hasPerk('barbarian')) {
        dmg = (dmg * 1.5).round();
      }
    }

    // 执行攻击
    final attackType = weapon['type'] == 'ranged' ? 'ranged' : 'melee';
    final weaponDamage = weapon['damage'];
    final damageType = weaponDamage == 'stun' ? 'stun' : attackType;

    if (attackType == 'ranged') {
      animateRangedWithType('wanderer', dmg, damageType, () {
        checkEnemyDeath(dmg);
      });
    } else {
      animateMeleeWithType('wanderer', dmg, damageType, () {
        checkEnemyDeath(dmg);
      });
    }

    notifyListeners();
  }

  /// 检查敌人死亡
  void checkEnemyDeath(int dmg) {
    Logger.info('🩸 检查敌人死亡: 当前血量=$currentEnemyHealth, 伤害=$dmg, 已胜利=$won');
    if (currentEnemyHealth <= 0 && !won) {
      Logger.info('🏆 敌人死亡，触发胜利');
      won = true;
      winFight();
    }
  }

  /// 胜利战斗 - 参考原游戏的winFight函数
  void winFight() {
    Logger.info('🏆 winFight() 被调用, fought=$fought');
    if (fought) return;

    VisibilityManager().createTimer(Duration(milliseconds: fightSpeed), () {
      Logger.info('🏆 winFight() 第一个定时器执行, fought=$fought');
      if (fought) return;

      endFight();

      // 播放胜利音效（暂时注释掉）
      // AudioEngine().playSound(AudioLibrary.WIN_FIGHT);

      // 敌人消失动画延迟
      VisibilityManager().createTimer(
          Duration(milliseconds: GameConfig.enemyDisappearDelay), () {
        Logger.info('🏆 winFight() 第二个定时器执行，准备显示战利品');
        final event = activeEvent();
        if (event == null) {
          Logger.info('⚠️ winFight() 没有活动事件');
          return;
        }

        final scene = event['scenes'][activeScene];
        if (scene == null) {
          Logger.info('⚠️ winFight() 没有活动场景');
          return;
        }

        // 显示死亡消息和战利品 - 参考原游戏逻辑
        showingLoot = true;
        final loot = scene['loot'] as Map<String, dynamic>? ?? {};
        Logger.info('🏆 显示战利品界面，战利品: $loot');
        drawLoot(loot);

        // 注意：原游戏的winFight不会自动回到小黑屋
        // 只是显示战利品界面，玩家可以选择离开
        // 只有loseFight才会调用World.die()回到小黑屋

        notifyListeners();
      }, 'Events.winFightLoot');
    }, 'Events.winFight');
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
      final lootData = entry.value;

      // 支持两种格式：数组格式 [min, max] 和对象格式 {min: x, max: y, chance: z}
      if (lootData is List<int>) {
        // 数组格式：[min, max]
        final min = lootData[0];
        final max = lootData[1];
        final num = Random().nextInt(max - min + 1) + min;
        if (num > 0) {
          currentLoot[entry.key] = num;
          Logger.info('🎁 生成战利品: ${entry.key} x$num');
        }
      } else if (lootData is Map<String, dynamic>) {
        // 对象格式：{min: x, max: y, chance: z}
        final chance = (lootData['chance'] ?? 1.0) as double;
        final randomValue = Random().nextDouble();

        Logger.info('🎁 物品: ${entry.key}, 概率: $chance, 随机值: $randomValue');

        if (randomValue < chance) {
          final min = (lootData['min'] ?? 1) as int;
          final max = (lootData['max'] ?? 1) as int;
          final num = Random().nextInt(max - min + 1) + min;
          currentLoot[entry.key] = num;
          Logger.info('🎁 生成战利品: ${entry.key} x$num');
        } else {
          Logger.info('🎁 未生成战利品: ${entry.key} (概率不足)');
        }
      }
    }

    Logger.info('🎁 最终战利品: $currentLoot');
    notifyListeners();
  }

  /// 获取战利品 - 参考原游戏的getLoot函数
  void getLoot(String itemName, int amount, {Function? onBagFull}) {
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

      // 通知Path模块更新UI - 修复战利品获取后背包不实时更新的问题
      path.notifyListeners();

      // 显示获取通知
      final localization = Localization();
      NotificationManager().notify(name,
          '${localization.translate('messages.gained')} ${_getItemDisplayName(itemName)} x$canTake');
    } else {
      Logger.info('🎒 背包空间不足，无法拾取');
      final localization = Localization();
      NotificationManager()
          .notify(name, localization.translate('messages.backpack_full'));

      // 如果提供了背包满回调，则调用它
      if (onBagFull != null) {
        onBagFull();
      }
    }

    notifyListeners();
  }

  /// 获取物品显示名称 - 用于通知
  String _getItemDisplayName(String itemName) {
    final localization = Localization();
    // 使用新的翻译逻辑，它会自动尝试所有类别
    final translatedName = localization.translate(itemName);

    // 如果翻译存在且不等于原键名，返回翻译
    if (translatedName != itemName) {
      return translatedName;
    }

    // 否则返回原名称
    return itemName;
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

      // 通知Path模块更新
      path.notifyListeners();
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

  /// 获取可用武器列表 - 参考原游戏events.js的武器显示逻辑
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

  /// 获取当前敌人血量
  int getCurrentEnemyHealth() {
    return currentEnemyHealth;
  }

  /// 获取敌人眩晕状态
  bool get isEnemyStunned => enemyStunned;

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
    Logger.info('🔧 _handleOnLoadCallback() 被调用: $callbackName');
    switch (callbackName) {
      case 'useOutpost':
        Logger.info('🔧 调用 Setpieces().useOutpost()');
        Setpieces().useOutpost();
        break;
      case 'addGastronomePerk':
        Logger.info('🔧 调用 Setpieces().addGastronomePerk()');
        Setpieces().addGastronomePerk();
        break;
      case 'clearDungeon':
        Logger.info('🔧 调用 Setpieces().clearDungeon()');
        Setpieces().clearDungeon();
        break;
      case 'markVisited':
        Logger.info('🔧 调用 Setpieces().markVisited()');
        Setpieces().markVisited();
        break;
      case 'replenishWater':
        Logger.info('🔧 调用 Setpieces().replenishWater()');
        Setpieces().replenishWater();
        break;
      case 'clearIronMine':
        Logger.info('🔧 调用 Setpieces().clearIronMine()');
        Setpieces().clearIronMine();
        break;
      case 'clearCoalMine':
        Logger.info('🔧 调用 Setpieces().clearCoalMine()');
        Setpieces().clearCoalMine();
        break;
      case 'clearSulphurMine':
        Logger.info('🔧 调用 Setpieces().clearSulphurMine()');
        Setpieces().clearSulphurMine();
        break;
      case 'clearCity':
        Logger.info('🔧 调用 Setpieces().clearCity()');
        Setpieces().clearCity();
        break;
      case 'activateShip':
        Logger.info('🔧 调用 Setpieces().activateShip()');
        Setpieces().activateShip();
        break;
      case 'activateExecutioner':
        Logger.info('🔧 调用 Setpieces().activateExecutioner()');
        Setpieces().activateExecutioner();
        break;
      case 'endEvent':
        Logger.info('🔧 调用 endEvent()');
        endEvent();
        break;
      default:
        Logger.info('⚠️ 未知的onLoad回调: $callbackName');
        break;
    }
    Logger.info('🔧 _handleOnLoadCallback() 完成: $callbackName');
  }

  /// 检查是否有足够的背包资源（专门用于火把等工具）
  bool canAffordBackpackCost(Map<String, dynamic> costs) {
    final path = Path();

    for (final entry in costs.entries) {
      final key = entry.key;
      final cost = entry.value as int;

      // 对于火把等工具，只检查背包
      if (_isToolItem(key)) {
        final outfitAmount = path.outfit[key] ?? 0;
        if (outfitAmount < cost) {
          Logger.info('🎒 背包中$key不足: 需要$cost, 拥有$outfitAmount');
          return false;
        }
      } else {
        // 非工具物品，检查库存
        final sm = StateManager();
        final current = sm.get('stores.$key', true) ?? 0;
        if (current < cost) {
          return false;
        }
      }
    }
    return true;
  }

  /// 检查是否是工具类物品（需要从背包消耗）
  bool _isToolItem(String itemName) {
    return itemName == 'torch' ||
        itemName == 'cured meat' ||
        itemName == 'bullets' ||
        itemName == 'hypo' ||
        itemName == 'stim' ||
        itemName == 'energy cell' ||
        itemName == 'charm';
    // 注意：medicine在房间事件中从库存消耗，不是从背包消耗
  }

  /// 消耗背包资源（专门用于火把等工具）
  void consumeBackpackCost(Map<String, dynamic> costs) {
    final path = Path();
    final sm = StateManager();

    for (final entry in costs.entries) {
      final key = entry.key;
      final cost = entry.value as int;

      if (_isToolItem(key)) {
        // 从背包消耗
        final outfitAmount = path.outfit[key] ?? 0;
        path.outfit[key] = outfitAmount - cost;
        sm.set('outfit["$key"]', path.outfit[key]);
        Logger.info('💰 从背包消耗: $key -$cost (剩余: ${path.outfit[key]})');
      } else {
        // 非工具物品，从库存消耗
        final current = sm.get('stores.$key', true) ?? 0;
        sm.set('stores.$key', current - cost);
        Logger.info('💰 从库存消耗: $key -$cost (剩余: ${current - cost})');
      }
    }
  }

  /// 处理按钮点击
  void handleButtonClick(String buttonKey, Map<String, dynamic> buttonConfig) {
    try {
      Logger.info('🔘 handleButtonClick() 被调用: $buttonKey');
      Logger.info('🔘 按钮配置: $buttonConfig');

      // 检查成本
      if (buttonConfig['cost'] != null) {
        final costs = buttonConfig['cost'] as Map<String, dynamic>;

        if (!canAffordBackpackCost(costs)) {
          final localization = Localization();
          NotificationManager().notify(
              name, localization.translate('messages.insufficient_resources'));
          return;
        }

        // 扣除成本
        consumeBackpackCost(costs);
      }

      // 给予奖励
      if (buttonConfig['reward'] != null) {
        final rewards = buttonConfig['reward'] as Map<String, dynamic>;
        final localization = Localization();
        final sm = StateManager();
        for (final entry in rewards.entries) {
          final key = entry.key;
          final value = entry.value as int;
          final current = sm.get('stores.$key', true) ?? 0;
          sm.set('stores.$key', current + value);

          // 显示获得奖励的通知
          final itemDisplayName = localization.translate('resources.$key');
          final displayName =
              itemDisplayName != 'resources.$key' ? itemDisplayName : key;
          NotificationManager().notify(
              name,
              localization.translate('world.notifications.found_item',
                  [displayName, value.toString()]));

          Logger.info('🎁 获得奖励: $key +$value');
        }
      }

      // 执行onChoose回调（优先级高于onLoad）
      if (buttonConfig['onChoose'] != null) {
        final onChoose = buttonConfig['onChoose'];
        if (onChoose is Function) {
          Logger.info('🔘 执行onChoose回调函数');
          onChoose();
        } else if (onChoose is String) {
          Logger.info('🔘 执行onChoose回调字符串: $onChoose');
          _handleOnLoadCallback(onChoose);
        }
      }
      // 执行onLoad回调（如果没有onChoose）
      else if (buttonConfig['onLoad'] != null) {
        final onLoad = buttonConfig['onLoad'];
        if (onLoad is Function) {
          onLoad();
        } else if (onLoad is String) {
          _handleOnLoadCallback(onLoad);
        }
      }

      // 检查是否有nextEvent（跳转到其他事件）
      if (buttonConfig['nextEvent'] != null) {
        final nextEventName = buttonConfig['nextEvent'] as String;
        Logger.info('🔘 跳转到下一个事件: $nextEventName');
        endEvent(); // 结束当前事件
        startEventByName(nextEventName); // 启动新事件
        return;
      }

      // 跳转到下一个场景
      if (buttonConfig['nextScene'] != null) {
        final nextSceneConfig = buttonConfig['nextScene'];
        Logger.info('🔘 nextScene配置: $nextSceneConfig');
        String nextScene;

        if (nextSceneConfig is String) {
          // 固定场景跳转
          nextScene = nextSceneConfig;
          Logger.info('🔘 固定场景跳转: $nextScene');
        } else if (nextSceneConfig is Map<String, dynamic>) {
          // 概率性场景跳转
          nextScene = _selectRandomScene(nextSceneConfig);
          Logger.info('🔘 概率性场景跳转: $nextScene');
        } else {
          Logger.error('❌ 无效的nextScene配置: $nextSceneConfig');
          endEvent();
          return;
        }

        if (nextScene == 'finish') {
          Logger.info('🔘 结束事件');
          endEvent();
        } else {
          Logger.info('🔘 加载下一个场景: $nextScene');
          loadScene(nextScene);
        }
      } else {
        Logger.info('🔘 没有nextScene配置，结束事件');
        endEvent();
      }
    } catch (e, stackTrace) {
      Logger.error('❌ handleButtonClick异常: $e');
      Logger.error('❌ 堆栈跟踪: $stackTrace');

      // 错误恢复：直接结束事件
      endEvent();
    }
  }

  /// 根据概率选择场景
  String _selectRandomScene(Map<String, dynamic> sceneConfig) {
    final random = Random().nextDouble();

    // 将概率键转换为数字并排序
    final probabilities = <double, String>{};
    for (final entry in sceneConfig.entries) {
      final prob = double.tryParse(entry.key);
      if (prob != null) {
        probabilities[prob] = entry.value as String;
      }
    }

    // 按概率升序排序
    final sortedProbs = probabilities.keys.toList()..sort();

    // 选择第一个大于等于随机数的概率
    for (final prob in sortedProbs) {
      if (random <= prob) {
        final selectedScene = probabilities[prob]!;
        Logger.info('🎲 概率性场景选择: $random <= $prob -> $selectedScene');
        return selectedScene;
      }
    }

    // 如果没有匹配，返回最后一个场景
    final fallbackScene = probabilities[sortedProbs.last]!;
    Logger.info('🎲 概率性场景选择(fallback): -> $fallbackScene');
    return fallbackScene;
  }

  /// 延迟奖励系统
  final Map<String, Timer> _delayedRewards = {};

  /// 保存延迟奖励
  void saveDelayedReward(String key, VoidCallback action, int delaySeconds) {
    // 取消现有的延迟奖励（如果有）
    _delayedRewards[key]?.cancel();

    // 创建新的延迟奖励
    _delayedRewards[key] =
        VisibilityManager().createTimer(Duration(seconds: delaySeconds), () {
      action();
      _delayedRewards.remove(key);
      Logger.info('🎁 延迟奖励执行: $key');
    }, 'Events.delayedReward.$key');

    Logger.info('⏰ 延迟奖励已设置: $key ($delaySeconds秒后执行)');
  }

  /// 取消延迟奖励
  void cancelDelayedReward(String key) {
    _delayedRewards[key]?.cancel();
    _delayedRewards.remove(key);
  }

  /// 清理所有延迟奖励
  void clearAllDelayedRewards() {
    for (final timer in _delayedRewards.values) {
      timer.cancel();
    }
    _delayedRewards.clear();
  }

  /// 设置战斗状态 - 参考原游戏Events.setStatus
  void setStatus(String fighter, String status) {
    Logger.info('🔮 设置状态: $fighter -> $status');

    if (fighter == 'enemy') {
      enemyStatus = status;

      // 根据状态类型设置效果
      switch (status) {
        case 'shield':
          Logger.info('🛡️ 敌人获得护盾状态');
          break;
        case 'enraged':
          Logger.info('😡 敌人进入狂暴状态');
          break;
        case 'meditation':
          Logger.info('🧘 敌人进入冥想状态');
          break;
        case 'energised':
          Logger.info('⚡ 敌人获得充能状态');
          break;
        case 'venomous':
          Logger.info('☠️ 敌人获得毒性状态');
          break;
        default:
          Logger.info('❓ 未知状态: $status');
      }
    } else if (fighter == 'wanderer') {
      // 玩家状态处理
      Logger.info('👤 玩家获得状态: $status');
    }

    notifyListeners();
  }

  /// 获取敌人当前状态
  String? getEnemyStatus() {
    return enemyStatus;
  }

  /// 清除敌人状态
  void clearEnemyStatus() {
    enemyStatus = null;
    notifyListeners();
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

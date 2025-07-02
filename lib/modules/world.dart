import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import '../core/logger.dart';
import '../core/localization.dart';
import 'path.dart';
import 'events.dart';
import 'setpieces.dart';
import 'room.dart';
import 'fabricator.dart';
import 'ship.dart';

/// 世界模块 - 处理世界地图探索
/// 包括地图生成、移动、战斗、资源消耗等功能
class World extends ChangeNotifier {
  static final World _instance = World._internal();

  factory World() {
    return _instance;
  }

  static World get instance => _instance;

  World._internal();

  // 模块名称
  String get name => Localization().translate('world.title');

  // 常量
  static const int radius = 30;
  static const List<int> villagePos = [30, 30];
  static const double stickiness = 0.5; // 0 <= x <= 1
  static const int lightRadius = 2;
  static const int baseWater = 10;
  static const int movesPerFood = 2;
  static const int movesPerWater = 1;
  static const int deathCooldown = 120;
  static const double fightChance = 0.20;
  static const int baseHealth = 10;
  static const double baseHitChance = 0.8;
  static const int meatHeal = 8;
  static const int medsHeal = 20;
  static const int hypoHeal = 30;
  static const int fightDelay = 3; // 战斗之间至少三次移动

  // 方向常量 (与原游戏完全一致)
  static const List<int> north = [0, -1];
  static const List<int> south = [0, 1];
  static const List<int> west = [-1, 0];
  static const List<int> east = [1, 0];

  // 地形类型
  static const Map<String, String> tile = {
    'village': 'A',
    'ironMine': 'I',
    'coalMine': 'C',
    'sulphurMine': 'S',
    'forest': ';',
    'field': ',',
    'barrens': '.',
    'road': '#',
    'house': 'H',
    'cave': 'V', // 确保洞穴使用V
    'town': 'O',
    'city': 'Y',
    'outpost': 'P',
    'ship': 'W',
    'borehole': 'B',
    'battlefield': 'F',
    'swamp': 'M',
    'cache': 'U',
    'executioner': 'X'
  };

  // 地形概率
  Map<String, double> tileProbs = {};

  // 地标配置
  Map<String, Map<String, dynamic>> landmarks = {};

  // 武器配置 - 参考原游戏World.Weapons
  static const Map<String, Map<String, dynamic>> weapons = {
    'fists': {'verb': 'punch', 'type': 'unarmed', 'damage': 1, 'cooldown': 2},
    'bone spear': {
      'verb': 'stab',
      'type': 'melee',
      'damage': 2,
      'cooldown': 2
    }, // 注意：骨枪没有cost，不消耗
    'iron sword': {
      'verb': 'swing', // 修正：原游戏是swing不是slash
      'type': 'melee',
      'damage': 4,
      'cooldown': 2
    },
    'steel sword': {
      'verb': 'slash', // 修正：原游戏是slash不是strike
      'type': 'melee',
      'damage': 6,
      'cooldown': 2
    },
    'bayonet': {'verb': 'thrust', 'type': 'melee', 'damage': 8, 'cooldown': 2},
    'rifle': {
      'verb': 'shoot',
      'type': 'ranged',
      'damage': 5,
      'cooldown': 1,
      'cost': {'bullets': 1}
    },
    'laser rifle': {
      'verb': 'blast', // 修正：原游戏是blast不是laser
      'type': 'ranged',
      'damage': 8,
      'cooldown': 1,
      'cost': {'energy cell': 1}
    },
    'grenade': {
      'verb': 'lob', // 修正：原游戏是lob不是throw
      'type': 'ranged',
      'damage': 15,
      'cooldown': 5,
      'cost': {'grenade': 1}
    },
    'bolas': {
      'verb': 'tangle', // 修正：原游戏是tangle不是entangle
      'type': 'ranged',
      'damage': 'stun',
      'cooldown': 15,
      'cost': {'bolas': 1}
    },
    'plasma rifle': {
      'verb': 'disintigrate', // 修正：原游戏是disintigrate不是disintegrate
      'type': 'ranged',
      'damage': 12,
      'cooldown': 1,
      'cost': {'energy cell': 1}
    },
    'energy blade': {
      'verb': 'slice',
      'type': 'melee',
      'damage': 10,
      'cooldown': 2
    },
    'disruptor': {
      'verb': 'stun',
      'type': 'ranged',
      'damage': 'stun',
      'cooldown': 15
    }
  };

  // 状态变量
  Map<String, dynamic> options = {};
  Map<String, dynamic>? state;
  List<int> curPos = [30, 30];
  int water = 10;
  int health = 10;
  int foodMove = 0;
  int waterMove = 0;
  int fightMove = 0;
  bool starvation = false;
  bool thirst = false;
  bool dead = false;
  bool danger = false;
  bool seenAll = false;
  Map<String, bool> usedOutposts = {};
  List<Map<String, int>> ship = [];
  String dir = 'east';

  /// 初始化世界模块
  void init([Map<String, dynamic>? options]) {
    final localization = Localization();
    Logger.info('World.init() ${localization.translateLog('start')}');
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    final sm = StateManager();

    Logger.info(localization.translateLog('setting_terrain_probabilities'));
    // 设置地形概率，总和必须等于1
    tileProbs[tile['forest']!] = 0.15;
    tileProbs[tile['field']!] = 0.35;
    tileProbs[tile['barrens']!] = 0.5;
    Logger.info(localization.translateLog('terrain_probabilities_set'));

    // 地标定义
    landmarks[tile['outpost']!] = {
      'num': 0,
      'minRadius': 0,
      'maxRadius': 0,
      'scene': 'outpost',
      'label': localization.translate('world.terrain.outpost')
    };
    landmarks[tile['ironMine']!] = {
      'num': 1,
      'minRadius': 5,
      'maxRadius': 5,
      'scene': 'ironmine',
      'label': localization.translate('world.terrain.iron_mine')
    };
    landmarks[tile['coalMine']!] = {
      'num': 1,
      'minRadius': 10,
      'maxRadius': 10,
      'scene': 'coalmine',
      'label': localization.translate('world.terrain.coal_mine')
    };
    landmarks[tile['sulphurMine']!] = {
      'num': 1,
      'minRadius': 20,
      'maxRadius': 20,
      'scene': 'sulphurmine',
      'label': localization.translate('world.terrain.sulphur_mine')
    };
    landmarks[tile['house']!] = {
      'num': 10,
      'minRadius': 0,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'house',
      'label': localization.translate('world.terrain.old_house')
    };
    landmarks[tile['cave']!] = {
      'num': 5,
      'minRadius': 3,
      'maxRadius': 10,
      'scene': 'cave',
      'label': localization.translate('world.terrain.damp_cave')
    };
    landmarks[tile['town']!] = {
      'num': 10,
      'minRadius': 10,
      'maxRadius': 20,
      'scene': 'town',
      'label': localization.translate('world.terrain.abandoned_town')
    };
    landmarks[tile['city']!] = {
      'num': 20,
      'minRadius': 20,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'city',
      'label': localization.translate('world.terrain.ruined_city')
    };
    landmarks[tile['ship']!] = {
      'num': 1,
      'minRadius': 28,
      'maxRadius': 28,
      'scene': 'ship',
      'label': localization.translate('world.terrain.crashed_starship')
    };
    landmarks[tile['borehole']!] = {
      'num': 10,
      'minRadius': 15,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'borehole',
      'label': localization.translate('world.terrain.borehole')
    };
    landmarks[tile['battlefield']!] = {
      'num': 5,
      'minRadius': 18,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'battlefield',
      'label': localization.translate('world.terrain.battlefield')
    };
    landmarks[tile['swamp']!] = {
      'num': 1,
      'minRadius': 15,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'swamp',
      'label': localization.translate('world.terrain.dark_swamp')
    };
    landmarks[tile['executioner']!] = {
      'num': 1,
      'minRadius': 28,
      'maxRadius': 28,
      'scene': 'executioner',
      'label': localization.translate('world.terrain.destroyed_starship')
    };

    // 只有在有声望数据时才添加缓存 - 与原游戏逻辑一致
    final previousStores = sm.get('previous.stores');
    if (previousStores != null &&
        previousStores is List &&
        previousStores.isNotEmpty) {
      landmarks[tile['cache']!] = {
        'num': 1,
        'minRadius': 10,
        'maxRadius': (radius * 1.5).round(),
        'scene': 'cache',
        'label': localization.translate('world.terrain.destroyed_village')
      };
    }

    Logger.info(
        '🌍 ${localization.translateLog('initializing_world_state')}...');
    // 初始化世界状态
    final worldFeature = sm.get('features.location.world', true);
    final worldData = sm.get('game.world', true);
    Logger.info(
        '🌍 ${localization.translateLog('checking_world_function_status')}: $worldFeature');
    Logger.info(
        '🌍 ${localization.translateLog('checking_world_data_status')}: $worldData');

    // 如果世界功能未解锁或者世界数据不存在，则生成新地图
    if (worldFeature == null || worldData == null || worldData is! Map) {
      Logger.info('🌍 Generating new world map...');
      sm.set('features.location.world', true);
      sm.set('features.executioner', true);
      sm.setM('game.world', {'map': generateMap(), 'mask': newMask()});
      Logger.info('🌍 New world map generation completed');
    } else if (sm.get('features.executioner', true) != true) {
      Logger.info('🌍 Placing executioner in existing map...');
      // 在之前生成的地图中放置执行者
      final map = sm.get('game.world.map');
      if (map != null && map is List && map.isNotEmpty && map[0] is List) {
        try {
          // 安全地转换为正确的类型
          final mapList =
              List<List<String>>.from(map.map((row) => List<String>.from(row)));
          final landmark = landmarks[tile['executioner']!]!;
          for (int l = 0; l < landmark['num']; l++) {
            placeLandmark(landmark['minRadius'], landmark['maxRadius'],
                tile['executioner']!, mapList);
          }
          sm.set('game.world.map', mapList);
          sm.set('features.executioner', true);
          Logger.info('🌍 执行者放置完成');
        } catch (e) {
          Logger.info('⚠️ 执行者放置失败: $e');
          sm.set('features.executioner', true);
        }
      } else {
        Logger.info('⚠️ 地图数据无效，跳过执行者放置');
        sm.set('features.executioner', true);
      }
    }

    Logger.info('🌍 映射飞船...');
    // 映射飞船并显示指南针提示
    final worldMap = sm.get('game.world.map');
    if (worldMap != null &&
        worldMap is List &&
        worldMap.isNotEmpty &&
        worldMap[0] is List) {
      try {
        // 安全地转换为正确的类型
        final mapList = List<List<String>>.from(
            worldMap.map((row) => List<String>.from(row)));
        ship = mapSearch(tile['ship']!, mapList, 1);
        if (ship.isNotEmpty) {
          dir = compassDir(ship[0]);
        }
      } catch (e) {
        Logger.info('⚠️ 飞船映射失败: $e');
        ship = [];
        dir = '';
      }
    } else {
      Logger.info('⚠️ 世界地图数据无效，跳过飞船映射');
      ship = [];
      dir = '';
    }
    Logger.info('🌍 飞船映射完成');

    Logger.info('🌍 检查地图可见性...');
    // 检查是否所有地方都已被看到
    testMap();
    Logger.info('🌍 地图可见性检查完成');

    Logger.info('🏛️ 初始化前哨站使用状态...');
    // 前哨站使用状态是临时的，每次出发时重置（参考原游戏逻辑）
    usedOutposts = {};
    Logger.info('🏛️ 前哨站使用状态初始化完成');

    Logger.info('🌍 World.init() 完成');
    notifyListeners();
  }

  /// 生成新的地图
  List<List<String>> generateMap() {
    final map = List.generate(
        radius * 2 + 1, (i) => List<String>.filled(radius * 2 + 1, ''));

    // 村庄总是在正中心
    // 从那里螺旋向外
    map[radius][radius] = tile['village']!;

    for (int r = 1; r <= radius; r++) {
      for (int t = 0; t < r * 8; t++) {
        int x, y;
        if (t < 2 * r) {
          x = radius - r + t;
          y = radius - r;
        } else if (t < 4 * r) {
          x = radius + r;
          y = radius - (3 * r) + t;
        } else if (t < 6 * r) {
          x = radius + (5 * r) - t;
          y = radius + r;
        } else {
          x = radius - r;
          y = radius + (7 * r) - t;
        }

        map[x][y] = chooseTile(x, y, map);
      }
    }

    // 放置地标
    for (final k in landmarks.keys) {
      final landmark = landmarks[k]!;
      for (int l = 0; l < landmark['num']; l++) {
        placeLandmark(landmark['minRadius'], landmark['maxRadius'], k, map);
      }
    }

    return map;
  }

  /// 生成新的遮罩
  List<List<bool>> newMask() {
    final mask = List.generate(
        radius * 2 + 1, (i) => List<bool>.filled(radius * 2 + 1, false));
    lightMap(radius, radius, mask);
    return mask;
  }

  /// 照亮地图
  List<List<bool>> lightMap(int x, int y, List<List<bool>> mask) {
    int r = lightRadius;
    // final sm = StateManager();
    // r *= sm.hasPerk('scout') ? 2 : 1; // 暂时注释掉技能系统
    uncoverMap(x, y, r, mask);
    return mask;
  }

  /// 揭开地图
  void uncoverMap(int x, int y, int r, List<List<bool>> mask) {
    mask[x][y] = true;
    for (int i = -r; i <= r; i++) {
      for (int j = -r + i.abs(); j <= r - i.abs(); j++) {
        if (y + j >= 0 &&
            y + j <= radius * 2 &&
            x + i <= radius * 2 &&
            x + i >= 0) {
          mask[x + i][y + j] = true;
        }
      }
    }
  }

  /// 选择地形
  String chooseTile(int x, int y, List<List<String>> map) {
    final adjacent = [
      y > 0 ? map[x][y - 1] : '',
      y < radius * 2 ? map[x][y + 1] : '',
      x < radius * 2 ? map[x + 1][y] : '',
      x > 0 ? map[x - 1][y] : ''
    ];

    final chances = <String, double>{};
    double nonSticky = 1;

    for (final adj in adjacent) {
      if (adj == tile['village']) {
        // 村庄必须在森林中以保持主题一致性
        return tile['forest']!;
      } else if (adj.isNotEmpty) {
        final cur = chances[adj] ?? 0;
        chances[adj] = cur + stickiness;
        nonSticky -= stickiness;
      }
    }

    for (final t in tile.values) {
      if (isTerrain(t)) {
        final cur = chances[t] ?? 0;
        chances[t] = cur + (tileProbs[t] ?? 0) * nonSticky;
      }
    }

    final list = <String>[];
    for (final entry in chances.entries) {
      list.add('${entry.value}${entry.key}');
    }

    list.sort((a, b) {
      final n1 = double.parse(a.substring(0, a.length - 1));
      final n2 = double.parse(b.substring(0, b.length - 1));
      return n2.compareTo(n1);
    });

    double c = 0;
    final r = Random().nextDouble();
    for (final prob in list) {
      c += double.parse(prob.substring(0, prob.length - 1));
      if (r < c) {
        return prob[prob.length - 1];
      }
    }

    return tile['barrens']!;
  }

  /// 放置地标
  List<int> placeLandmark(
      int minRadius, int maxRadius, String landmark, List<List<String>> map) {
    int x = radius, y = radius;
    final random = Random();

    while (!isTerrain(map[x][y])) {
      final r = random.nextInt(maxRadius - minRadius + 1) + minRadius;
      int xDist = random.nextInt(r + 1);
      int yDist = r - xDist;
      if (random.nextBool()) xDist = -xDist;
      if (random.nextBool()) yDist = -yDist;

      x = radius + xDist;
      if (x < 0) x = 0;
      if (x > radius * 2) x = radius * 2;

      y = radius + yDist;
      if (y < 0) y = 0;
      if (y > radius * 2) y = radius * 2;
    }

    map[x][y] = landmark;
    return [x, y];
  }

  /// 检查是否为地形
  bool isTerrain(String tileType) {
    return tileType == tile['forest'] ||
        tileType == tile['field'] ||
        tileType == tile['barrens'];
  }

  /// 搜索地图
  List<Map<String, int>> mapSearch(String target, dynamic map, int required) {
    final landmark = landmarks[target];
    if (landmark == null) {
      return [];
    }

    // 检查地图数据类型
    if (map == null || map is! List) {
      Logger.info('⚠️ mapSearch: 地图数据无效 (map=$map)');
      return [];
    }

    int max = landmark['num'];
    max = required < max ? required : max;

    int index = 0;
    final targets = <Map<String, int>>[];

    try {
      for (int i = 0; i <= radius * 2; i++) {
        if (i >= map.length) break;
        if (map[i] is! List) continue;

        for (int j = 0; j <= radius * 2; j++) {
          if (j >= map[i].length) break;

          if (map[i][j].toString().startsWith(target)) {
            targets.add({
              'x': i - radius,
              'y': j - radius,
            });
            index++;
            if (index == max) {
              return targets;
            }
          }
        }
      }
    } catch (e) {
      Logger.info('⚠️ mapSearch错误: $e');
    }

    return targets;
  }

  /// 指南针方向
  String compassDir(Map<String, int> pos) {
    String dir = '';
    final localization = Localization();
    final horz = pos['x']! < 0
        ? localization.translate('world.directions.west')
        : localization.translate('world.directions.east');
    final vert = pos['y']! < 0
        ? localization.translate('world.directions.north')
        : localization.translate('world.directions.south');

    if (pos['x']!.abs() / 2 > pos['y']!.abs()) {
      dir = horz;
    } else if (pos['y']!.abs() / 2 > pos['x']!.abs()) {
      dir = vert;
    } else {
      dir = vert + horz;
    }
    return dir;
  }

  /// 测试地图是否全部可见
  void testMap() {
    if (!seenAll) {
      bool dark = false;
      final sm = StateManager();
      final mask = sm.get('game.world.mask');

      if (mask != null && mask is List) {
        try {
          for (int i = 0; i < mask.length; i++) {
            if (mask[i] is List) {
              for (int j = 0; j < mask[i].length; j++) {
                if (!mask[i][j]) {
                  dark = true;
                  break;
                }
              }
            }
            if (dark) break;
          }
        } catch (e) {
          Logger.info('⚠️ testMap错误: $e');
          // 如果出错，假设还有未探索的区域
          dark = true;
        }
      } else {
        Logger.info('⚠️ 地图遮罩数据无效，跳过可见性检查');
        dark = true; // 假设还有未探索的区域
      }
      seenAll = !dark;
    }
  }

  /// 应用地图 - 揭示世界的一部分（侦察兵购买地图功能）
  void applyMap() {
    if (!seenAll) {
      final sm = StateManager();
      final mask = sm.get('game.world.mask');

      if (mask != null && mask is List && mask.isNotEmpty && mask[0] is List) {
        try {
          // 转换为正确的类型
          final maskList =
              List<List<bool>>.from(mask.map((row) => List<bool>.from(row)));

          int x, y;
          final random = Random();

          // 找到一个未探索的区域
          do {
            x = random.nextInt(radius * 2 + 1);
            y = random.nextInt(radius * 2 + 1);
          } while (maskList[x][y]);

          // 揭示该区域周围5格范围
          uncoverMap(x, y, 5, maskList);

          // 保存更新的遮罩
          sm.set('game.world.mask', maskList);

          Logger.info('🗺️ 地图已应用，揭示了位置 [$x, $y] 周围的区域');
        } catch (e) {
          Logger.info('⚠️ applyMap错误: $e');
        }
      }
    }

    // 重新检查是否全部可见
    testMap();
  }

  /// 移动方法
  void moveNorth() {
    // Engine().log('北'); // 暂时注释掉
    if (curPos[1] > 0) move(north);
  }

  void moveSouth() {
    // Engine().log('南'); // 暂时注释掉
    if (curPos[1] < radius * 2) move(south);
  }

  void moveWest() {
    // Engine().log('西'); // 暂时注释掉
    if (curPos[0] > 0) move(west);
  }

  void moveEast() {
    // Engine().log('东'); // 暂时注释掉
    if (curPos[0] < radius * 2) move(east);
  }

  /// 移动
  void move(List<int> direction) {
    if (state == null) {
      Logger.error('move() - state为null，无法移动');
      return;
    }

    // 检查是否死亡，死亡状态下不能移动
    if (dead) {
      final localization = Localization();
      NotificationManager().notify(
          name, localization.translate('world.notifications.you_are_dead'));
      Logger.error('move() - 玩家已死亡，无法移动');
      return;
    }

    final oldPos = [curPos[0], curPos[1]];
    final oldTile = state!['map'][curPos[0]][curPos[1]];
    curPos[0] += direction[0];
    curPos[1] += direction[1];
    final newTile = state!['map'][curPos[0]][curPos[1]];

    Logger.info(
        'Moving: [${oldPos[0]}, ${oldPos[1]}] -> [${curPos[0]}, ${curPos[1]}], $oldTile -> $newTile');
    Logger.info('About to call doSpace()...');

    narrateMove(oldTile, newTile);

    // 更新遮罩（仅在临时状态中）
    final mask = List<List<bool>>.from(
        state!['mask'].map((row) => List<bool>.from(row)));
    lightMap(curPos[0], curPos[1], mask);
    state!['mask'] = mask;

    // 注意：不立即保存到StateManager，只有回到村庄时才保存

    // drawMap(); // 在Flutter中由UI自动更新
    doSpace();

    Logger.info('🚶 doSpace()调用完成，即将调用notifyListeners()...');

    // 播放随机脚步声（暂时注释掉）
    // final randomFootstep = Random().nextInt(5) + 1;
    // AudioEngine().playSound('footsteps_$randomFootstep');

    if (checkDanger()) {
      final localization = Localization();
      if (danger) {
        NotificationManager().notify(
            name,
            localization
                .translate('world.notifications.dangerous_far_from_village'));
      } else {
        NotificationManager().notify(
            name, localization.translate('world.notifications.safer_here'));
      }
    }

    notifyListeners();
  }

  /// 叙述移动
  void narrateMove(String oldTile, String newTile) {
    String? msg;
    final localization = Localization();

    switch (oldTile) {
      case ';': // 森林
        switch (newTile) {
          case ',': // 田野
            msg = localization.translate('world.movement.forest_to_field');
            break;
          case '.': // 荒地
            msg = localization.translate('world.movement.forest_to_barrens');
            break;
        }
        break;
      case ',': // 田野
        switch (newTile) {
          case ';': // 森林
            msg = localization.translate('world.movement.field_to_forest');
            break;
          case '.': // 荒地
            msg = localization.translate('world.movement.field_to_barrens');
            break;
        }
        break;
      case '.': // 荒地
        switch (newTile) {
          case ',': // 田野
            msg = localization.translate('world.movement.barrens_to_field');
            break;
          case ';': // 森林
            msg = localization.translate('world.movement.barrens_to_forest');
            break;
        }
        break;
    }

    if (msg != null) {
      NotificationManager().notify(name, msg);
    }
  }

  /// 检查危险
  bool checkDanger() {
    final sm = StateManager();

    if (!danger) {
      if ((sm.get('stores["i armour"]', true) ?? 0) == 0 &&
          getDistance() >= 8) {
        danger = true;
        return true;
      }
      if ((sm.get('stores["s armour"]', true) ?? 0) == 0 &&
          getDistance() >= 18) {
        danger = true;
        return true;
      }
    } else {
      if (getDistance() < 8) {
        danger = false;
        return true;
      }
      if (getDistance() < 18 && (sm.get('stores["i armour"]', true) ?? 0) > 0) {
        danger = false;
        return true;
      }
    }
    return false;
  }

  /// 获取距离
  int getDistance([List<int>? from, List<int>? to]) {
    from ??= curPos;
    to ??= villagePos;
    return (from[0] - to[0]).abs() + (from[1] - to[1]).abs();
  }

  /// 获取地形
  String getTerrain() {
    if (state == null) return '';
    return state!['map'][curPos[0]][curPos[1]];
  }

  /// 获取伤害
  dynamic getDamage(String thing) {
    return weapons[thing]?['damage'];
  }

  /// 获取本地化的武器动词
  String getWeaponVerb(String weaponName) {
    final verbKey = weapons[weaponName]?['verb'];
    if (verbKey != null) {
      final localization = Localization();
      return localization.translate('world.weapons.$verbKey');
    }
    return weaponName;
  }

  /// 处理空间事件 - 参考原游戏的doSpace函数
  void doSpace() {
    if (state == null) return;

    // 获取当前地形
    final curTile = state!['map'][curPos[0]][curPos[1]];
    // 获取原始地形字符（去掉可能的'!'标记）
    final originalTile = curTile.length > 1 && curTile.endsWith('!')
        ? curTile.substring(0, curTile.length - 1)
        : curTile;
    final isVisited = curTile.length > 1 && curTile.endsWith('!');

    Logger.info(
        '🗺️ doSpace() - 当前位置: [${curPos[0]}, ${curPos[1]}], 地形: $curTile');
    Logger.info('🗺️ 原始地形: $originalTile, 已访问: $isVisited');

    if (curTile == tile['village']) {
      Logger.info('🏠 触发村庄事件 - 回到小黑屋');
      goHome();
    } else if (originalTile == tile['executioner']) {
      // 执行者场景 - 参考原游戏的两阶段访问逻辑
      Logger.info('🔮 发现执行者装置');

      // 检查执行者状态，决定触发哪个事件
      final executionerCompleted = state!['executioner'] == true;

      if (executionerCompleted) {
        // 第二阶段：触发executioner-antechamber事件
        Logger.info('🔮 执行者已完成intro，触发antechamber事件');
        final events = Events();
        events.startEventByName('executioner-antechamber');
      } else {
        // 第一阶段：触发executioner-intro事件
        Logger.info('🔮 首次访问执行者，触发intro事件');
        final events = Events();
        events.startEventByName('executioner-intro');
      }
    } else if (originalTile == tile['outpost']) {
      // 前哨站特殊处理 - 参考原游戏逻辑：if(curTile != World.TILE.OUTPOST || !World.outpostUsed())
      final isUsed = outpostUsed();
      final key = '${curPos[0]},${curPos[1]}';
      Logger.info('🏛️ 到达前哨站: $originalTile (已使用: $isUsed, 已访问: $isVisited)');
      Logger.info('🏛️ 前哨站位置: [${curPos[0]}, ${curPos[1]}], 键: $key');
      Logger.info('🏛️ 当前地形: $curTile, 原始地形: $originalTile');

      // 修复：前哨站访问条件应该同时检查使用状态和访问状态
      // 只有未访问且未使用的前哨站才能触发事件
      if (!isVisited && !isUsed) {
        // 前哨站未使用，触发前哨站事件
        final landmarkInfo = landmarks[originalTile];
        if (landmarkInfo != null && landmarkInfo['scene'] != null) {
          final setpieces = Setpieces();
          final sceneName = landmarkInfo['scene'];

          // 检查场景是否存在
          if (setpieces.isSetpieceAvailable(sceneName)) {
            Logger.info('🏛️ 启动前哨站Setpiece场景: $sceneName');
            setpieces.startSetpiece(sceneName);
          } else {
            // 为缺失的场景提供默认处理 - 直接使用前哨站
            Logger.info('🏛️ 前哨站场景不存在，直接使用前哨站');
            useOutpost();
          }
        } else {
          Logger.info('🏛️ 前哨站地标信息无效，直接使用前哨站');
          useOutpost();
        }
      } else {
        if (isVisited) {
          Logger.info('🏛️ 前哨站已访问，跳过事件');
        } else if (isUsed) {
          Logger.info('🏛️ 前哨站已使用，跳过事件');
        }
        // 已访问或已使用的前哨站不再触发事件
      }
      // 注意：前哨站事件不消耗补给！
    } else if (landmarks.containsKey(originalTile)) {
      // 检查是否是其他地标（使用原始字符检查）
      Logger.info('🏛️ 触发地标事件: $originalTile (visited: $isVisited)');
      // 只有未访问的地标才触发事件
      if (!isVisited) {
        // 触发地标建筑事件
        final landmarkInfo = landmarks[originalTile];
        if (landmarkInfo != null && landmarkInfo['scene'] != null) {
          final setpieces = Setpieces();
          final sceneName = landmarkInfo['scene'];

          // 检查场景是否存在
          if (setpieces.isSetpieceAvailable(sceneName)) {
            Logger.info('🏛️ 启动Setpiece场景: $sceneName');
            setpieces.startSetpiece(sceneName);
            // 对于某些特殊场景（如洞穴、房子、矿物、城镇），不立即标记为已访问
            // 只有在场景完成时才标记
            if (sceneName != 'cave' &&
                sceneName != 'house' &&
                sceneName != 'ironmine' &&
                sceneName != 'coalmine' &&
                sceneName != 'sulphurmine' &&
                sceneName != 'town' &&
                sceneName != 'city') {
              // 立即标记为已访问，防止重复访问
              markVisited(curPos[0], curPos[1]);
            }
          } else {
            // 为缺失的场景提供默认处理
            Logger.info('🏛️ 场景不存在，使用默认处理: $sceneName');
            _handleMissingSetpiece(originalTile, landmarkInfo);
          }
        } else {
          Logger.info('🏛️ 地标信息无效: $landmarkInfo');
          final localization = Localization();
          _handleMissingSetpiece(originalTile, {
            'label':
                localization.translate('world.notifications.unknown_landmark')
          });
        }
      } else {
        Logger.info('🏛️ 地标已访问，跳过事件');
      }
      // 注意：地标事件不消耗补给！
    } else {
      Logger.info('🚶 普通移动 - 使用补给和检查战斗');
      // 只有在普通地形移动时才消耗补给
      if (useSupplies()) {
        checkFight();
      }
    }
  }

  /// 处理缺失的场景事件
  void _handleMissingSetpiece(
      String curTile, Map<String, dynamic> landmarkInfo) {
    final localization = Localization();
    final label = landmarkInfo['label'] ??
        localization.translate('world.notifications.unknown_location');

    switch (curTile) {
      case 'I': // 铁矿
        // 触发铁矿事件
        Events().triggerSetpiece('ironmine');
        // 立即标记为已访问，防止重复访问
        markVisited(curPos[0], curPos[1]);
        break;

      case 'C': // 煤矿
        // 触发煤矿事件
        Events().triggerSetpiece('coalmine');
        // 立即标记为已访问，防止重复访问
        markVisited(curPos[0], curPos[1]);
        break;

      case 'S': // 硫磺矿
        // 触发硫磺矿事件
        Events().triggerSetpiece('sulphurmine');
        // 注意：硫磺矿不立即标记为已访问，只有完成setpiece事件后才标记
        // 这与原游戏行为一致，允许玩家重复访问直到完成事件
        break;

      case 'H': // 旧房子
        NotificationManager().notify(
            name, localization.translate('world.notifications.old_house'));
        // 随机奖励
        final random = Random();
        if (random.nextDouble() < 0.5) {
          _addToOutfit('wood', random.nextInt(3) + 1);
        }
        if (random.nextDouble() < 0.3) {
          _addToOutfit('cloth', random.nextInt(2) + 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'B': // 钻孔
        NotificationManager().notify(
            name, localization.translate('world.notifications.deep_borehole'));
        markVisited(curPos[0], curPos[1]);
        break;

      case 'F': // 战场
        NotificationManager().notify(
            name, localization.translate('world.notifications.battlefield'));
        final random = Random();
        if (random.nextDouble() < 0.4) {
          _addToOutfit('bullets', random.nextInt(5) + 1);
        }
        if (random.nextDouble() < 0.2) {
          _addToOutfit('rifle', 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'Y': // 废墟城市
        NotificationManager().notify(
            name, localization.translate('world.notifications.ruined_city'));
        // 注意：废墟城市不在这里标记为已访问
        // 只有完成完整探索后才会在clearCity中转换为前哨站
        break;

      case 'W': // 坠毁星舰
        NotificationManager().notify(name,
            localization.translate('world.notifications.crashed_starship'));
        markVisited(curPos[0], curPos[1]);
        break;

      case 'O': // 废弃小镇
        NotificationManager().notify(
            name, localization.translate('world.notifications.abandoned_town'));
        final random = Random();
        // 小镇可能有各种物品
        if (random.nextDouble() < 0.4) {
          _addToOutfit('cloth', random.nextInt(3) + 1);
        }
        if (random.nextDouble() < 0.3) {
          _addToOutfit('leather', random.nextInt(2) + 1);
        }
        if (random.nextDouble() < 0.2) {
          _addToOutfit('medicine', 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'V': // 潮湿洞穴
        // 注意：潮湿洞穴应该有完整的Setpiece场景，不应该使用这个默认处理
        // 如果到达这里，说明'cave' Setpiece场景有问题
        Logger.info('⚠️ 潮湿洞穴的Setpiece场景缺失，使用默认处理');
        NotificationManager().notify(
            name, localization.translate('world.notifications.damp_cave'));
        final random2 = Random();
        if (random2.nextDouble() < 0.3) {
          _addToOutfit('fur', random2.nextInt(2) + 1);
        }
        if (random2.nextDouble() < 0.2) {
          _addToOutfit('teeth', random2.nextInt(3) + 1);
        }
        // 对于洞穴，不立即标记为已访问，允许重复访问
        // 只有完成洞穴探索后才会通过clearDungeon转换为前哨站
        Logger.info('🏛️ 潮湿洞穴未标记为已访问，允许重复探索');
        break;

      case 'M': // 阴暗沼泽
        NotificationManager().notify(
            name, localization.translate('world.notifications.dark_swamp'));
        final random3 = Random();
        // 沼泽可能有特殊的物品
        if (random3.nextDouble() < 0.3) {
          _addToOutfit('scales', random3.nextInt(2) + 1);
        }
        if (random3.nextDouble() < 0.2) {
          _addToOutfit('teeth', random3.nextInt(3) + 1);
        }
        if (random3.nextDouble() < 0.1) {
          _addToOutfit('alien alloy', 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'U': // 被摧毁的村庄
        NotificationManager().notify(name,
            localization.translate('world.notifications.destroyed_village'));
        markVisited(curPos[0], curPos[1]);
        break;

      case 'X': // 执行者
        // 注意：执行者应该有完整的Setpiece场景，不应该使用这个默认处理
        // 如果到达这里，说明'executioner' Setpiece场景有问题
        Logger.info('⚠️ 执行者的Setpiece场景缺失，使用默认处理');
        NotificationManager().notify(name,
            localization.translate('world.notifications.executioner_appears'));
        // 执行者是最终Boss，应该通过完整的Setpiece事件处理
        // 暂时不标记为已访问，等待Setpiece事件实现
        Logger.info('🏛️ 执行者未标记为已访问，等待Setpiece事件实现');
        break;

      default:
        NotificationManager().notify(
            name,
            localization
                .translate('world.notifications.discovered_location', [label]));
        markVisited(curPos[0], curPos[1]);
        break;
    }
  }

  /// 使用补给
  bool useSupplies() {
    final sm = StateManager();
    final path = Path();

    foodMove++;
    waterMove++;

    Logger.info(
        '🍖 useSupplies() - foodMove: $foodMove/$movesPerFood, waterMove: $waterMove/$movesPerWater');
    Logger.info('🍖 当前状态 - 饥饿: $starvation, 口渴: $thirst, 水: $water');

    // 详细诊断背包状态
    Logger.info('🎒 背包状态诊断:');
    Logger.info('🎒 path.outfit: ${path.outfit}');
    Logger.info('🎒 熏肉数量: ${path.outfit['cured meat'] ?? 0}');
    Logger.info('🎒 库存熏肉: ${sm.get('stores["cured meat"]', true) ?? 0}');
    Logger.info(
        '🎒 StateManager中的outfit熏肉: ${sm.get('outfit["cured meat"]', true) ?? 0}');

    // 食物
    int currentMovesPerFood = movesPerFood;
    // 缓慢新陈代谢技能：食物消耗减半
    if (StateManager().hasPerk('slow metabolism')) {
      currentMovesPerFood *= 2;
    }

    if (foodMove >= currentMovesPerFood) {
      foodMove = 0;

      // 安全地访问Path().outfit，避免null错误
      try {
        var num = path.outfit['cured meat'] ?? 0;
        Logger.info('🍖 需要消耗食物 - 熏肉数量: $num');
        num--;

        if (num == 0) {
          final localization = Localization();
          NotificationManager().notify(
              name, localization.translate('world.notifications.out_of_meat'));
          Logger.info('⚠️ Out of meat');
        } else if (num < 0) {
          // 饥饿！
          num = 0;
          if (!starvation) {
            final localization = Localization();
            NotificationManager().notify(
                name,
                localization
                    .translate('world.notifications.starvation_begins'));
            starvation = true;
            Logger.info('⚠️ Starvation begins');
          } else {
            sm.set('character.starved',
                (sm.get('character.starved', true) ?? 0) + 1);
            // if (sm.get('character.starved') >= 10 && !sm.hasPerk('slow metabolism')) {
            //   sm.addPerk('slow metabolism');
            // }
            Logger.info('💀 饥饿死亡！已经处于饥饿状态，熏肉不足');
            Logger.info('💀 死亡原因：背包熏肉数量 = ${path.outfit['cured meat'] ?? 0}');
            die();
            return false;
          }
        } else {
          starvation = false;
          final healAmount = meatHealAmount();
          final oldHealth = health;
          final newHealth = health + healAmount;
          Logger.info(
              '🍖 消耗熏肉治疗: 当前血量=$oldHealth, 治疗量=$healAmount, 目标血量=$newHealth');
          setHp(newHealth);
          Logger.info('🍖 消耗了熏肉，剩余: $num，恢复生命值');
        }

        // 安全地更新outfit
        path.outfit['cured meat'] = num;

        // 同步到StateManager
        sm.set('outfit["cured meat"]', num);
      } catch (e) {
        Logger.info('⚠️ 访问Path().outfit时出错: $e');
        // 如果访问失败，跳过食物消耗
      }
    }

    // 水
    int currentMovesPerWater = movesPerWater;
    // 沙漠鼠技能：水消耗减半
    if (StateManager().hasPerk('desert rat')) {
      currentMovesPerWater *= 2;
    }

    if (waterMove >= currentMovesPerWater) {
      waterMove = 0;
      var waterAmount = water;
      Logger.info('💧 需要消耗水 - 当前水量: $waterAmount');
      waterAmount--;

      if (waterAmount == 0) {
        final localization = Localization();
        NotificationManager().notify(
            name, localization.translate('world.notifications.no_more_water'));
        Logger.info('⚠️ No more water');
      } else if (waterAmount < 0) {
        waterAmount = 0;
        if (!thirst) {
          final localization = Localization();
          NotificationManager().notify(name,
              localization.translate('world.notifications.thirst_unbearable'));
          thirst = true;
          Logger.info('⚠️ Thirst begins');
        } else {
          sm.set('character.dehydrated',
              (sm.get('character.dehydrated', true) ?? 0) + 1);
          // if (sm.get('character.dehydrated') >= 10 && !sm.hasPerk('desert rat')) {
          //   sm.addPerk('desert rat');
          // }
          Logger.info('💀 口渴死亡！已经处于口渴状态，水不足');
          Logger.info('💀 死亡原因：当前水量 = $water');
          die();
          return false;
        }
      } else {
        thirst = false;
        Logger.info('💧 消耗了水，剩余: $waterAmount');
      }
      setWater(waterAmount);
      // updateSupplies(); // 在Flutter中由状态管理自动更新
    }
    return true;
  }

  /// 检查战斗
  void checkFight() {
    fightMove++;
    Logger.info(
        '🎯 World.checkFight() - fightMove: $fightMove, fightDelay: $fightDelay');

    if (fightMove > fightDelay) {
      double chance = fightChance;
      // 潜行技能：减少50%战斗概率
      if (StateManager().hasPerk('stealthy')) {
        chance *= 0.5;
      }
      final randomValue = Random().nextDouble();
      Logger.info('🎯 战斗检查 - chance: $chance, random: $randomValue');

      if (randomValue < chance) {
        fightMove = 0;
        Logger.info('🎯 触发战斗！');
        Events().triggerFight(); // 启用战斗事件
      }
    }
  }

  /// 设置水量
  void setWater(int w) {
    water = w;
    if (water > getMaxWater()) {
      water = getMaxWater();
    }
    // updateSupplies(); // 在Flutter中由状态管理自动更新
    notifyListeners();
  }

  /// 设置生命值
  void setHp(int hp) {
    final oldHealth = health;
    Logger.info('🩸 setHp() 被调用: $oldHealth -> $hp');

    if (hp.isFinite && !hp.isNaN) {
      health = hp;
      if (health > getMaxHealth()) {
        health = getMaxHealth();
      }
      Logger.info('🩸 血量更新完成: 最终血量=$health, 最大血量=${getMaxHealth()}');
      notifyListeners();
    } else {
      Logger.info(
          '⚠️ setHp() 收到无效血量值: $hp (isFinite=${hp.isFinite}, isNaN=${hp.isNaN})');
    }
  }

  /// 获取肉类治疗量
  int meatHealAmount() {
    int healAmount = meatHeal;
    // 美食家技能：食物治疗效果翻倍
    if (StateManager().hasPerk('gastronome')) {
      healAmount *= 2;
    }
    return healAmount;
  }

  /// 获取药物治疗量
  int medsHealAmount() {
    return medsHeal;
  }

  /// 获取注射器治疗量
  int hypoHealAmount() {
    return hypoHeal;
  }

  /// 获取最大生命值
  int getMaxHealth() {
    final sm = StateManager();

    if ((sm.get('stores["kinetic armour"]', true) ?? 0) > 0) {
      return baseHealth + 75;
    } else if ((sm.get('stores["s armour"]', true) ?? 0) > 0) {
      return baseHealth + 35;
    } else if ((sm.get('stores["i armour"]', true) ?? 0) > 0) {
      return baseHealth + 15;
    } else if ((sm.get('stores["l armour"]', true) ?? 0) > 0) {
      return baseHealth + 5;
    }
    return baseHealth;
  }

  /// 获取命中率
  double getHitChance() {
    double hitChance = baseHitChance;
    // 精准技能：增加10%命中率
    if (StateManager().hasPerk('precise')) {
      hitChance += 0.1;
    }
    return hitChance;
  }

  /// 获取最大水量
  int getMaxWater() {
    final sm = StateManager();

    if ((sm.get('stores["fluid recycler"]', true) ?? 0) > 0) {
      return baseWater + 100;
    } else if ((sm.get('stores["water tank"]', true) ?? 0) > 0) {
      return baseWater + 50;
    } else if ((sm.get('stores.cask', true) ?? 0) > 0) {
      return baseWater + 20;
    } else if ((sm.get('stores.waterskin', true) ?? 0) > 0) {
      return baseWater + 10;
    }
    return baseWater;
  }

  /// 回家 - 参考原游戏的goHome函数
  void goHome() {
    Logger.info('🏠 World.goHome() 开始');

    // 重新启用页签导航 - 参考原游戏 Engine.restoreNavigation = true
    final engine = Engine();
    engine.restoreNavigation = true;
    Logger.info('🌍 页签导航将在下次按键时恢复');

    // 保存世界状态到StateManager - 参考原游戏逻辑
    if (state != null) {
      final sm = StateManager();
      sm.setM('game.world', state!);
      Logger.info('🏠 保存世界状态完成');

      // 参考原游戏：前哨站使用状态是临时的，不保存到持久化存储
      // 每次出发时会重置usedOutposts = {}
      Logger.info('🏛️ 前哨站使用状态不持久化（参考原游戏逻辑）');

      // 检查并解锁建筑 - 参考原游戏的建筑解锁逻辑
      if (state!['sulphurmine'] == true &&
          (sm.get('game.buildings["sulphur mine"]', true) ?? 0) == 0) {
        sm.add('game.buildings["sulphur mine"]', 1);
        Logger.info('🏠 解锁硫磺矿');
      }
      if (state!['ironmine'] == true &&
          (sm.get('game.buildings["iron mine"]', true) ?? 0) == 0) {
        sm.add('game.buildings["iron mine"]', 1);
        Logger.info('🏠 解锁铁矿');
      }
      if (state!['coalmine'] == true &&
          (sm.get('game.buildings["coal mine"]', true) ?? 0) == 0) {
        sm.add('game.buildings["coal mine"]', 1);
        Logger.info('🏠 解锁煤矿');
      }
      if (state!['ship'] == true &&
          (sm.get('features.location.spaceShip', true) != true)) {
        Logger.info('🚀 检测到ship状态为true，开始初始化Ship模块');
        Ship().init(); // 启用Ship模块初始化 - 参考原游戏 Ship.init()
        sm.set('features.location.spaceShip', true);
        Logger.info('🏠 解锁星舰页签完成');
      }
      // 检查制造器解锁条件 - 需要完成command deck
      if (state!['command'] == true &&
          (sm.get('features.location.fabricator', true) != true)) {
        // 初始化制造器模块
        final fabricator = Fabricator();
        fabricator.init();
        sm.set('features.location.fabricator', true);
        final localization = Localization();
        NotificationManager().notify(name,
            localization.translate('world.notifications.builder_takes_device'));
        Logger.info('🏠 解锁制造器');
      }

      // 清空世界状态
      state = null;
    }

    // 返回装备到仓库 - 参考原游戏的returnOutfit函数
    returnOutfit();

    // 回到小黑屋模块
    final room = Room();
    engine.travelTo(room);

    final localization = Localization();
    NotificationManager().notify(
        name, localization.translate('world.notifications.safely_returned'));
    Logger.info('🏠 World.goHome() 完成');
    notifyListeners();
  }

  /// 返回装备到仓库 - 参考原游戏的returnOutfit函数
  void returnOutfit() {
    final path = Path();
    final sm = StateManager();

    try {
      for (final entry in path.outfit.entries) {
        final itemName = entry.key;
        final amount = entry.value;

        if (amount > 0) {
          // 将装备中的物品添加到仓库
          sm.add('stores["$itemName"]', amount);

          // 检查是否应该留在家里（不带走的物品）
          if (leaveItAtHome(itemName)) {
            path.outfit[itemName] = 0;
            // 同步到StateManager
            sm.set('outfit["$itemName"]', 0);
          }
        }
      }

      Logger.info('🎒 装备已返回仓库');
    } catch (e) {
      Logger.info('⚠️ 返回装备时出错: $e');
    }
  }

  /// 检查物品是否应该留在家里 - 参考原游戏的leaveItAtHome函数
  bool leaveItAtHome(String thing) {
    // 这些物品可以带走：食物、弹药、能量电池、符咒、药物、武器、工具（包括火把）
    return thing != 'cured meat' &&
        thing != 'bullets' &&
        thing != 'energy cell' &&
        thing != 'charm' &&
        thing != 'medicine' &&
        thing != 'stim' &&
        thing != 'hypo' &&
        thing != 'torch' && // 火把可以带走
        !weapons.containsKey(thing) && // 武器可以带走
        !_isRoomCraftable(thing); // Room中的可制作物品可以带走
  }

  /// 检查是否是房间中的可制作物品
  bool _isRoomCraftable(String thing) {
    final room = Room();
    return room.craftables.containsKey(thing);
  }

  /// 检查前哨站是否已使用（仅检查当次探索的临时状态）
  bool outpostUsed([int? x, int? y]) {
    x ??= curPos[0];
    y ??= curPos[1];
    final key = '$x,$y';

    // 只检查内存中的临时状态（参考原游戏：使用状态不持久化）
    return usedOutposts[key] == true;
  }

  /// 标记前哨站为已使用（临时状态，每次出发重置）
  void markOutpostUsed([int? x, int? y]) {
    x ??= curPos[0];
    y ??= curPos[1];
    final key = '$x,$y';

    // 只更新内存状态（参考原游戏：使用状态是临时的，不持久化）
    usedOutposts[key] = true;

    Logger.info('🏛️ 前哨站 ($x, $y) 已标记为已使用（临时状态）');
  }

  /// 死亡 - 参考原游戏的World.die函数
  void die() {
    Logger.info('💀 die() 被调用 - 当前状态: dead=$dead, health=$health');
    Logger.info('💀 调用栈: ${StackTrace.current}');

    if (!dead) {
      dead = true;
      final oldHealth = health;
      health = 0;
      Logger.info('💀 玩家死亡 - 血量变化: $oldHealth -> $health');

      // 重新启用页签导航 - 参考原游戏 Engine.tabNavigation = true
      final engine = Engine();
      engine.tabNavigation = true;
      Logger.info('🌍 页签导航已重新启用');

      // 显示死亡通知
      final localization = Localization();
      NotificationManager().notify(
          name, localization.translate('world.notifications.world_fades'));

      // 清空世界状态和装备 - 参考原游戏逻辑
      state = null;
      final path = Path();
      try {
        path.outfit.clear();
      } catch (e) {
        Logger.info('⚠️ 清空装备时出错: $e');
      }

      // 清除StateManager中的装备数据
      final sm = StateManager();
      sm.remove('outfit');

      // 设置出发冷却时间 - 参考原游戏 Button.cooldown($('#embarkButton'))
      path.setEmbarkCooldown();
      Logger.info('🕐 已设置出发冷却时间');

      // 播放死亡音效（暂时注释掉）
      // AudioEngine().playSound(AudioLibrary.death);

      // 立即切换到小黑屋 - 参考原游戏逻辑（避免显示"地图未初始化"过渡页面）
      // 使用单例实例确保APK版本兼容性
      final room = Room();
      engine.travelTo(room);
      Logger.info('🏠 立即切换到小黑屋（避免过渡页面）');

      // 延迟重置死亡状态 - 保持原游戏的2秒延迟效果
      Timer(const Duration(milliseconds: 2000), () {
        // 重置死亡状态
        dead = false;
        Logger.info('🏠 死亡状态已重置');
      });

      notifyListeners();
    }
  }

  /// 重生
  void respawn() {
    Logger.info('🔄 World.respawn() 被调用');
    dead = false;
    health = getMaxHealth();
    water = getMaxWater();
    curPos = [villagePos[0], villagePos[1]];
    starvation = false;
    thirst = false;
    foodMove = 0;
    waterMove = 0;

    // 重置装备中的食物和水
    final path = Path();
    try {
      path.outfit['cured meat'] = 1; // 给一些基本补给

      // 同步到StateManager
      final sm = StateManager();
      sm.set('outfit["cured meat"]', 1);
    } catch (e) {
      Logger.info('⚠️ 重置装备时出错: $e');
    }

    final localization = Localization();
    NotificationManager()
        .notify(name, localization.translate('world.notifications.respawned'));
    Logger.info('✅ 重生完成 - 生命值: $health, 水: $water');
    notifyListeners();
  }

  /// 手动重生（用于测试）
  void forceRespawn() {
    Logger.info('🔄 强制重生被调用');
    respawn();
  }

  /// 到达时调用 - 参考原游戏的onArrival函数
  void onArrival([int transitionDiff = 0]) {
    final sm = StateManager();

    // 禁用页签导航 - 参考原游戏 Engine.tabNavigation = false
    final engine = Engine();
    engine.tabNavigation = false;
    Logger.info('🌍 页签导航已禁用');

    // 创建临时世界状态副本 - 参考原游戏的逻辑
    // World.state = $.extend(true, {}, $SM.get('game.world'));
    final savedWorldState = sm.get('game.world', true);

    if (savedWorldState != null) {
      // 深拷贝世界状态，创建临时副本
      state = _deepCopyWorldState(savedWorldState);
      Logger.info('✅ 创建临时世界状态副本');
    } else {
      Logger.info('⚠️ 世界数据无效，重新初始化');
      // 如果没有世界数据，重新初始化
      init();
      final newWorldState = sm.get('game.world', true);

      if (newWorldState != null) {
        // 深拷贝新生成的世界状态
        state = _deepCopyWorldState(newWorldState);
        Logger.info('✅ 重新生成世界数据成功');
      } else {
        Logger.info('❌ 无法生成世界数据');
        state = null;
      }
    }

    // 设置初始位置和状态
    curPos = [villagePos[0], villagePos[1]];
    health = getMaxHealth();
    water = getMaxWater();

    // 重置前哨站使用状态（参考原游戏逻辑：每次出发都重置）
    // 前哨站的永久状态通过地图上的访问标记(!)保存，使用状态是临时的
    usedOutposts = {};
    Logger.info('🏛️ 重置前哨站使用状态（每次出发都重置）');

    // 如果有有效的地图数据，点亮当前位置
    if (state != null && state!['mask'] != null) {
      try {
        final mask = List<List<bool>>.from(
            state!['mask'].map((row) => List<bool>.from(row)));
        lightMap(curPos[0], curPos[1], mask);
        // 更新状态中的遮罩
        state!['mask'] = mask;
        Logger.info('✅ 地图照明完成');
      } catch (e) {
        Logger.info('⚠️ 地图照明失败: $e');
      }
    }

    // 播放背景音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicWorldMap);

    notifyListeners();
  }

  /// 获取当前位置
  List<int> getCurrentPosition() {
    return [curPos[0], curPos[1]];
  }

  /// 获取当前地形名称
  String getCurrentTerrainName() {
    final terrain = getTerrain();
    final localization = Localization();

    switch (terrain) {
      case ';':
        return localization.translate('world.terrain.forest');
      case ',':
        return localization.translate('world.terrain.field');
      case '.':
        return localization.translate('world.terrain.barrens');
      case '#':
        return localization.translate('world.terrain.road');
      case 'A':
        return localization.translate('world.terrain.village');
      case 'H':
        return localization.translate('world.terrain.old_house');
      case 'V':
        return localization.translate('world.terrain.damp_cave');
      case 'O':
        return localization.translate('world.terrain.abandoned_town');
      case 'Y':
        return localization.translate('world.terrain.ruined_city');
      case 'P':
        return localization.translate('world.terrain.outpost');
      case 'W':
        return localization.translate('world.terrain.crashed_starship');
      case 'I':
        return localization.translate('world.terrain.iron_mine');
      case 'C':
        return localization.translate('world.terrain.coal_mine');
      case 'S':
        return localization.translate('world.terrain.sulphur_mine');
      case 'B':
        return localization.translate('world.terrain.borehole');
      case 'F':
        return localization.translate('world.terrain.battlefield');
      case 'M':
        return localization.translate('world.terrain.dark_swamp');
      case 'U':
        return localization.translate('world.terrain.destroyed_village');
      case 'X':
        return localization.translate('world.terrain.destroyed_starship');
      default:
        return localization.translate('world.terrain.unknown_terrain');
    }
  }

  /// 获取当前状态信息
  Map<String, dynamic> getStatus() {
    return {
      'health': health,
      'maxHealth': getMaxHealth(),
      'water': water,
      'maxWater': getMaxWater(),
      'position': getCurrentPosition(),
      'terrain': getCurrentTerrainName(),
      'danger': danger,
      'starvation': starvation,
      'thirst': thirst,
      'dead': dead,
    };
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    // 在Flutter中，状态更新将通过状态管理自动处理
    notifyListeners();
  }

  /// 按键处理
  void keyDown(dynamic event) {
    // 在原始游戏中处理方向键移动
    // 在Flutter中，这将通过UI按钮处理
  }

  void keyUp(dynamic event) {
    // 在原始游戏中，世界模块不处理按键释放
  }

  /// 滑动处理
  void swipeLeft() {
    moveWest();
  }

  void swipeRight() {
    moveEast();
  }

  void swipeUp() {
    moveNorth();
  }

  void swipeDown() {
    moveSouth();
  }

  /// 使用前哨站 - 参考原游戏的World.useOutpost函数
  void useOutpost() {
    Logger.info('🏛️ useOutpost() 开始执行 - 位置: [${curPos[0]}, ${curPos[1]}]');

    final currentTile = state != null && state!['map'] != null
        ? (state!['map'] as List<dynamic>)[curPos[0]][curPos[1]] as String
        : 'unknown';
    Logger.info('🏛️ 当前地形: $currentTile');

    // 检查前哨站是否已经使用过
    final isUsed = outpostUsed();
    Logger.info('🏛️ 前哨站是否已使用: $isUsed');

    if (isUsed) {
      Logger.info('🏛️ 前哨站已经使用过，无法再次使用');
      final localization = Localization();
      NotificationManager().notify(name,
          localization.translate('world.notifications.outpost_already_used'));
      return;
    }

    // 补充水到最大值
    final oldWater = water;
    water = getMaxWater();
    final localization = Localization();
    NotificationManager().notify(
        name, localization.translate('world.notifications.water_replenished'));

    // 修复：前哨站使用后需要标记为已访问，确保回村庄后显示状态正确
    // 虽然使用状态会重置，但访问状态是永久的，保证显示一致性
    Logger.info('🏛️ 调用 markOutpostUsed()');
    markOutpostUsed();
    Logger.info('🏛️ 调用 markVisited() - 确保前哨站使用后显示为灰色');
    markVisited(curPos[0], curPos[1]);

    // 验证状态
    final finalUsed = outpostUsed();
    final finalTile = state != null && state!['map'] != null
        ? (state!['map'] as List<dynamic>)[curPos[0]][curPos[1]] as String
        : 'unknown';

    Logger.info('🏛️ 前哨站使用完成 - 水: $oldWater -> $water');
    Logger.info('🏛️ 最终状态 - 已使用: $finalUsed, 地形: $finalTile');
    notifyListeners();
  }

  /// 标记位置为已访问 - 参考原游戏的markVisited函数
  void markVisited(int x, int y) {
    if (state != null && state!['map'] != null) {
      try {
        // 安全地转换地图数据类型
        final mapData = state!['map'];
        final map = List<List<String>>.from(
            mapData.map((row) => List<String>.from(row)));

        if (x >= 0 && x < map.length && y >= 0 && y < map[x].length) {
          final currentTile = map[x][y];

          if (!currentTile.endsWith('!')) {
            map[x][y] = '$currentTile!';
            Logger.info('🗺️ 标记位置 ($x, $y) 为已访问: ${map[x][y]}');

            // 更新state中的地图数据（仅在临时状态中）
            state!['map'] = map;

            // 注意：不立即保存到StateManager，只有回到村庄时才保存
            Logger.info('🗺️ 地图状态已更新到临时状态');
          } else {
            Logger.info('🗺️ 位置 ($x, $y) 已经被标记为已访问: $currentTile');
          }
        }
      } catch (e) {
        Logger.info('⚠️ markVisited失败: $e');
        Logger.info('⚠️ 地图数据类型: ${state!['map'].runtimeType}');
      }
    }
    notifyListeners();
  }

  /// 清除地牢状态 - 参考原游戏的clearDungeon函数
  void clearDungeon() {
    Logger.info('🏛️ ========== World.clearDungeon() 开始执行 ==========');
    Logger.info('🏛️ 将当前位置转换为前哨站');
    Logger.info('🏛️ 当前位置: [${curPos[0]}, ${curPos[1]}]');

    if (state == null || state!['map'] == null) {
      Logger.error('❌ 状态或地图数据为空！');
      return;
    }

    try {
      // 安全地转换地图数据类型
      final mapData = state!['map'];
      final map =
          List<List<String>>.from(mapData.map((row) => List<String>.from(row)));

      if (curPos[0] >= 0 &&
          curPos[0] < map.length &&
          curPos[1] >= 0 &&
          curPos[1] < map[curPos[0]].length) {
        final oldTile = map[curPos[0]][curPos[1]];
        Logger.info('🏛️ 转换前地形: $oldTile');

        // 参考原游戏：创建的前哨站不带已访问标记，显示为黑色地标
        map[curPos[0]][curPos[1]] = tile['outpost']!;
        Logger.info('🏛️ 设置新地形: ${tile['outpost']}');

        Logger.info(
            '🏛️ 地形转换: $oldTile -> ${tile['outpost']} 在位置 [${curPos[0]}, ${curPos[1]}]');

        // 更新state中的地图数据
        state!['map'] = map;
        Logger.info('🏛️ 更新state中的地图数据');

        // 验证转换结果
        final verifyTile = map[curPos[0]][curPos[1]];
        if (verifyTile == tile['outpost']) {
          Logger.info('✅ 地形转换验证成功: $verifyTile');
        } else {
          Logger.error('❌ 地形转换验证失败: $verifyTile');
        }

        // 绘制道路连接到前哨站 - 参考原游戏的drawRoad函数
        Logger.info('🏛️ 调用 drawRoad()');
        drawRoad();

        // 注意：不要立即标记前哨站为已使用
        // 新创建的前哨站应该可以立即使用来补充水源

        // 重新绘制地图以更新显示 - 关键！
        Logger.info('🏛️ 调用 notifyListeners()');
        notifyListeners();

        Logger.info('🏛️ ========== clearDungeon() 地形转换完成 ==========');
      } else {
        Logger.error('❌ 位置超出地图范围！');
      }
    } catch (e, stackTrace) {
      Logger.error('❌ clearDungeon失败: $e');
      Logger.error('❌ 堆栈跟踪: $stackTrace');
    }

    final sm = StateManager();
    sm.set('game.world.dungeonCleared', true);
    final localization = Localization();
    NotificationManager().notify(
        name, localization.translate('world.notifications.dungeon_cleared'));
    notifyListeners();
  }

  /// 绘制道路 - 参考原游戏的drawRoad函数
  void drawRoad() {
    if (state == null || state!['map'] == null) return;

    final map = state!['map'] as List<List<String>>;

    // 寻找最近的道路 - 参考原游戏的findClosestRoad函数
    List<int> findClosestRoad(List<int> startPos) {
      // 螺旋搜索最近的道路瓦片
      int x = 0, y = 0, dx = 1, dy = -1;
      final maxDistance = getDistance(startPos, villagePos) + 2;

      for (int i = 0; i < maxDistance * maxDistance; i++) {
        final searchX = startPos[0] + x;
        final searchY = startPos[1] + y;

        if (searchX > 0 &&
            searchX < radius * 2 &&
            searchY > 0 &&
            searchY < radius * 2) {
          final currentTile = map[searchX][searchY];

          // 检查是否是道路、前哨站或村庄
          if (currentTile == tile['road'] ||
              (currentTile == tile['outpost'] && !(x == 0 && y == 0)) ||
              currentTile == tile['village']) {
            return [searchX, searchY];
          }
        }

        // 螺旋移动逻辑
        if (x == 0 || y == 0) {
          final dtmp = dx;
          dx = -dy;
          dy = dtmp;
        }
        if (x == 0 && y <= 0) {
          x++;
        } else {
          x += dx;
          y += dy;
        }
      }
      return villagePos; // 如果找不到道路，返回村庄位置
    }

    final closestRoad = findClosestRoad(curPos);
    final xDist = curPos[0] - closestRoad[0];
    final yDist = curPos[1] - closestRoad[1];

    if (xDist == 0 && yDist == 0) return; // 已经在道路上

    // 修复除零错误：当距离为0时，方向为0
    final xDir = xDist == 0 ? 0 : (xDist.abs() ~/ xDist); // 方向：1, -1 或 0
    final yDir = yDist == 0 ? 0 : (yDist.abs() ~/ yDist); // 方向：1, -1 或 0

    int xIntersect, yIntersect;
    if (xDist.abs() > yDist.abs()) {
      xIntersect = closestRoad[0];
      yIntersect = closestRoad[1] + yDist;
    } else {
      xIntersect = closestRoad[0] + xDist;
      yIntersect = closestRoad[1];
    }

    // 绘制水平道路
    for (int x = 0; x < xDist.abs(); x++) {
      final roadX = closestRoad[0] + (xDir * x);
      if (roadX >= 0 &&
          roadX < map.length &&
          yIntersect >= 0 &&
          yIntersect < map[roadX].length) {
        if (isTerrain(map[roadX][yIntersect])) {
          map[roadX][yIntersect] = tile['road']!;
        }
      }
    }

    // 绘制垂直道路
    for (int y = 0; y < yDist.abs(); y++) {
      final roadY = closestRoad[1] + (yDir * y);
      if (xIntersect >= 0 &&
          xIntersect < map.length &&
          roadY >= 0 &&
          roadY < map[xIntersect].length) {
        if (isTerrain(map[xIntersect][roadY])) {
          map[xIntersect][roadY] = tile['road']!;
        }
      }
    }

    Logger.info(
        '🛤️ 绘制道路完成：从 [${curPos[0]}, ${curPos[1]}] 到 [${closestRoad[0]}, ${closestRoad[1]}]');
  }

  /// 检查位置是否已访问
  bool isVisited(int x, int y) {
    final key = '$x,$y';
    final sm = StateManager();
    return sm.get('game.world.visited["$key"]', true) == true;
  }

  /// 检查地牢是否已清理
  bool isDungeonCleared() {
    final sm = StateManager();
    return sm.get('game.world.dungeonCleared', true) == true;
  }

  /// 测试函数：手动触发地标事件（用于调试）
  void testLandmarkEvent(String landmarkType) {
    Logger.info('🧪 测试地标事件: $landmarkType');
    if (landmarks.containsKey(landmarkType)) {
      final landmarkInfo = landmarks[landmarkType];
      Logger.info('🧪 地标信息: $landmarkInfo');
      _handleMissingSetpiece(landmarkType, landmarkInfo!);
    } else {
      Logger.info('🧪 地标类型不存在: $landmarkType');
    }
  }

  /// 深拷贝世界状态 - 参考原游戏的$.extend(true, {}, obj)
  Map<String, dynamic> _deepCopyWorldState(Map<String, dynamic> original) {
    final copy = <String, dynamic>{};

    for (final entry in original.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        copy[key] = _deepCopyWorldState(value);
      } else if (value is List) {
        copy[key] = _deepCopyList(value);
      } else {
        copy[key] = value;
      }
    }

    return copy;
  }

  /// 深拷贝列表
  List<dynamic> _deepCopyList(List<dynamic> original) {
    final copy = <dynamic>[];

    for (final item in original) {
      if (item is Map<String, dynamic>) {
        copy.add(_deepCopyWorldState(item));
      } else if (item is List) {
        copy.add(_deepCopyList(item));
      } else {
        copy.add(item);
      }
    }

    return copy;
  }

  /// 将物品添加到装备中 - 参考原游戏的临时状态逻辑
  void _addToOutfit(String itemName, int amount) {
    try {
      final path = Path();
      final currentAmount = path.outfit[itemName] ?? 0;
      path.outfit[itemName] = currentAmount + amount;

      // 同步到StateManager（装备数据需要立即同步以保持一致性）
      final sm = StateManager();
      sm.set('outfit["$itemName"]', path.outfit[itemName]);

      // 显示获得物品的通知
      final localization = Localization();
      final itemDisplayName = localization.translate('resources.$itemName');
      final displayName =
          itemDisplayName != 'resources.$itemName' ? itemDisplayName : itemName;

      NotificationManager().notify(
          name,
          localization.translate('world.notifications.found_item',
              [displayName, amount.toString()]));

      Logger.info(
          '🎒 添加到装备: $itemName x$amount (总计: ${path.outfit[itemName]})');
    } catch (e) {
      Logger.info('⚠️ 添加物品到装备时出错: $e');
    }
  }
}

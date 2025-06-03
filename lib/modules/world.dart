import 'package:flutter/material.dart';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import 'path.dart';

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
  final String name = "世界";

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

  // 方向常量
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
    'cave': 'V',
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

  // 武器配置
  static const Map<String, Map<String, dynamic>> weapons = {
    'fists': {'verb': '拳击', 'type': 'unarmed', 'damage': 1, 'cooldown': 2},
    'bone spear': {'verb': '刺击', 'type': 'melee', 'damage': 2, 'cooldown': 2},
    'iron sword': {'verb': '挥砍', 'type': 'melee', 'damage': 4, 'cooldown': 2},
    'steel sword': {'verb': '斩击', 'type': 'melee', 'damage': 6, 'cooldown': 2},
    'bayonet': {'verb': '突刺', 'type': 'melee', 'damage': 8, 'cooldown': 2},
    'rifle': {
      'verb': '射击',
      'type': 'ranged',
      'damage': 5,
      'cooldown': 1,
      'cost': {'bullets': 1}
    },
    'laser rifle': {
      'verb': '激光',
      'type': 'ranged',
      'damage': 8,
      'cooldown': 1,
      'cost': {'energy cell': 1}
    },
    'grenade': {
      'verb': '投掷',
      'type': 'ranged',
      'damage': 15,
      'cooldown': 5,
      'cost': {'grenade': 1}
    },
    'bolas': {
      'verb': '缠绕',
      'type': 'ranged',
      'damage': 'stun',
      'cooldown': 15,
      'cost': {'bolas': 1}
    },
    'plasma rifle': {
      'verb': '分解',
      'type': 'ranged',
      'damage': 12,
      'cooldown': 1,
      'cost': {'energy cell': 1}
    },
    'energy blade': {
      'verb': '切割',
      'type': 'melee',
      'damage': 10,
      'cooldown': 2
    },
    'disruptor': {
      'verb': '眩晕',
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
  String dir = '东方';

  /// 初始化世界模块
  void init([Map<String, dynamic>? options]) {
    print('🌍 World.init() 开始');
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    final sm = StateManager();

    print('🌍 设置地形概率...');
    // 设置地形概率，总和必须等于1
    tileProbs[tile['forest']!] = 0.15;
    tileProbs[tile['field']!] = 0.35;
    tileProbs[tile['barrens']!] = 0.5;
    print('🌍 地形概率设置完成');

    // 地标定义
    landmarks[tile['outpost']!] = {
      'num': 0,
      'minRadius': 0,
      'maxRadius': 0,
      'scene': 'outpost',
      'label': '前哨站'
    };
    landmarks[tile['ironMine']!] = {
      'num': 1,
      'minRadius': 5,
      'maxRadius': 5,
      'scene': 'ironmine',
      'label': '铁矿'
    };
    landmarks[tile['coalMine']!] = {
      'num': 1,
      'minRadius': 10,
      'maxRadius': 10,
      'scene': 'coalmine',
      'label': '煤矿'
    };
    landmarks[tile['sulphurMine']!] = {
      'num': 1,
      'minRadius': 20,
      'maxRadius': 20,
      'scene': 'sulphurmine',
      'label': '硫磺矿'
    };
    landmarks[tile['house']!] = {
      'num': 10,
      'minRadius': 0,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'house',
      'label': '旧房子'
    };
    landmarks[tile['cave']!] = {
      'num': 5,
      'minRadius': 3,
      'maxRadius': 10,
      'scene': 'cave',
      'label': '潮湿洞穴'
    };
    landmarks[tile['town']!] = {
      'num': 10,
      'minRadius': 10,
      'maxRadius': 20,
      'scene': 'town',
      'label': '废弃小镇'
    };
    landmarks[tile['city']!] = {
      'num': 20,
      'minRadius': 20,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'city',
      'label': '废墟城市'
    };
    landmarks[tile['ship']!] = {
      'num': 1,
      'minRadius': 28,
      'maxRadius': 28,
      'scene': 'ship',
      'label': '坠毁星舰'
    };
    landmarks[tile['borehole']!] = {
      'num': 10,
      'minRadius': 15,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'borehole',
      'label': '钻孔'
    };
    landmarks[tile['battlefield']!] = {
      'num': 5,
      'minRadius': 18,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'battlefield',
      'label': '战场'
    };
    landmarks[tile['swamp']!] = {
      'num': 1,
      'minRadius': 15,
      'maxRadius': (radius * 1.5).round(),
      'scene': 'swamp',
      'label': '阴暗沼泽'
    };
    landmarks[tile['executioner']!] = {
      'num': 1,
      'minRadius': 28,
      'maxRadius': 28,
      'scene': 'executioner',
      'label': '被摧毁的战舰'
    };

    // 只有在有声望数据时才添加缓存
    if (sm.get('previous.stores') != null) {
      landmarks[tile['cache']!] = {
        'num': 1,
        'minRadius': 10,
        'maxRadius': (radius * 1.5).round(),
        'scene': 'cache',
        'label': '被摧毁的村庄'
      };
    }

    print('🌍 初始化世界状态...');
    // 初始化世界状态
    final worldFeature = sm.get('features.location.world', true);
    final worldData = sm.get('game.world', true);
    print('🌍 检查世界功能状态: $worldFeature');
    print('🌍 检查世界数据状态: $worldData');

    // 如果世界功能未解锁或者世界数据不存在，则生成新地图
    if (worldFeature == null || worldData == null || worldData is! Map) {
      print('🌍 生成新的世界地图...');
      sm.set('features.location.world', true);
      sm.set('features.executioner', true);
      sm.setM('game.world', {'map': generateMap(), 'mask': newMask()});
      print('🌍 新世界地图生成完成');
    } else if (sm.get('features.executioner', true) != true) {
      print('🌍 在现有地图中放置执行者...');
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
          print('🌍 执行者放置完成');
        } catch (e) {
          print('⚠️ 执行者放置失败: $e');
          sm.set('features.executioner', true);
        }
      } else {
        print('⚠️ 地图数据无效，跳过执行者放置');
        sm.set('features.executioner', true);
      }
    }

    print('🌍 映射飞船...');
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
        print('⚠️ 飞船映射失败: $e');
        ship = [];
        dir = '';
      }
    } else {
      print('⚠️ 世界地图数据无效，跳过飞船映射');
      ship = [];
      dir = '';
    }
    print('🌍 飞船映射完成');

    print('🌍 检查地图可见性...');
    // 检查是否所有地方都已被看到
    testMap();
    print('🌍 地图可见性检查完成');

    print('🌍 World.init() 完成');
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
      print('⚠️ mapSearch: 地图数据无效 (map=$map)');
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
      print('⚠️ mapSearch错误: $e');
    }

    return targets;
  }

  /// 指南针方向
  String compassDir(Map<String, int> pos) {
    String dir = '';
    final horz = pos['x']! < 0 ? '西' : '东';
    final vert = pos['y']! < 0 ? '北' : '南';

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
          print('⚠️ testMap错误: $e');
          // 如果出错，假设还有未探索的区域
          dark = true;
        }
      } else {
        print('⚠️ 地图遮罩数据无效，跳过可见性检查');
        dark = true; // 假设还有未探索的区域
      }
      seenAll = !dark;
    }
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
    if (state == null) return;

    final oldTile = state!['map'][curPos[0]][curPos[1]];
    curPos[0] += direction[0];
    curPos[1] += direction[1];
    narrateMove(oldTile, state!['map'][curPos[0]][curPos[1]]);
    lightMap(curPos[0], curPos[1], state!['mask']);
    // drawMap(); // 在Flutter中由UI自动更新
    doSpace();

    // 播放随机脚步声（暂时注释掉）
    // final randomFootstep = Random().nextInt(5) + 1;
    // AudioEngine().playSound('footsteps_$randomFootstep');

    if (checkDanger()) {
      if (danger) {
        NotificationManager().notify(name, '离村庄这么远而没有适当保护是危险的');
      } else {
        NotificationManager().notify(name, '这里更安全');
      }
    }

    notifyListeners();
  }

  /// 叙述移动
  void narrateMove(String oldTile, String newTile) {
    String? msg;

    switch (oldTile) {
      case ';': // 森林
        switch (newTile) {
          case ',': // 田野
            msg = "树木让位给干草。泛黄的灌木在风中沙沙作响。";
            break;
          case '.': // 荒地
            msg = "树木消失了。干裂的土地和飞扬的尘土是糟糕的替代品。";
            break;
        }
        break;
      case ',': // 田野
        switch (newTile) {
          case ';': // 森林
            msg = "树木在地平线上隐约可见。草地逐渐让位给满是干枝和落叶的森林地面。";
            break;
          case '.': // 荒地
            msg = "草地变稀薄。很快，只剩下尘土。";
            break;
        }
        break;
      case '.': // 荒地
        switch (newTile) {
          case ',': // 田野
            msg = "荒地在一片垂死的草海中断裂，在干燥的微风中摇摆。";
            break;
          case ';': // 森林
            msg = "一堵扭曲的树墙从尘土中升起。它们的枝条扭曲成头顶的骨架状树冠。";
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

  /// 处理空间事件
  void doSpace() {
    if (state == null) return;

    final curTile = state!['map'][curPos[0]][curPos[1]];

    if (curTile == tile['village']) {
      goHome();
    } else if (curTile == tile['executioner']) {
      // 执行者场景（暂时注释掉）
      // final scene = state!['executioner'] ? 'executioner-antechamber' : 'executioner-intro';
      // Events.startEvent(Events.Executioner[scene]);
    } else if (landmarks.containsKey(curTile)) {
      if (curTile != tile['outpost'] || !outpostUsed()) {
        // Events.startEvent(Events.Setpieces[landmarks[curTile]!['scene']]);
      }
    } else {
      if (useSupplies()) {
        checkFight();
      }
    }
  }

  /// 使用补给
  bool useSupplies() {
    final sm = StateManager();
    final path = Path();

    foodMove++;
    waterMove++;

    // 食物
    int currentMovesPerFood = movesPerFood;
    // currentMovesPerFood *= sm.hasPerk('slow metabolism') ? 2 : 1; // 暂时注释掉技能系统

    if (foodMove >= currentMovesPerFood) {
      foodMove = 0;
      var num = path.outfit['cured meat'] ?? 0;
      num--;

      if (num == 0) {
        NotificationManager().notify(name, '肉已经用完了');
      } else if (num < 0) {
        // 饥饿！
        num = 0;
        if (!starvation) {
          NotificationManager().notify(name, '饥饿开始了');
          starvation = true;
        } else {
          sm.set('character.starved',
              (sm.get('character.starved', true) ?? 0) + 1);
          // if (sm.get('character.starved') >= 10 && !sm.hasPerk('slow metabolism')) {
          //   sm.addPerk('slow metabolism');
          // }
          die();
          return false;
        }
      } else {
        starvation = false;
        setHp(health + meatHealAmount());
      }
      path.outfit['cured meat'] = num;
    }

    // 水
    int currentMovesPerWater = movesPerWater;
    // currentMovesPerWater *= sm.hasPerk('desert rat') ? 2 : 1; // 暂时注释掉技能系统

    if (waterMove >= currentMovesPerWater) {
      waterMove = 0;
      var waterAmount = water;
      waterAmount--;

      if (waterAmount == 0) {
        NotificationManager().notify(name, '没有更多的水了');
      } else if (waterAmount < 0) {
        waterAmount = 0;
        if (!thirst) {
          NotificationManager().notify(name, '口渴变得难以忍受');
          thirst = true;
        } else {
          sm.set('character.dehydrated',
              (sm.get('character.dehydrated', true) ?? 0) + 1);
          // if (sm.get('character.dehydrated') >= 10 && !sm.hasPerk('desert rat')) {
          //   sm.addPerk('desert rat');
          // }
          die();
          return false;
        }
      } else {
        thirst = false;
      }
      setWater(waterAmount);
      // updateSupplies(); // 在Flutter中由状态管理自动更新
    }
    return true;
  }

  /// 检查战斗
  void checkFight() {
    fightMove++;
    if (fightMove > fightDelay) {
      double chance = fightChance;
      // chance *= sm.hasPerk('stealthy') ? 0.5 : 1; // 暂时注释掉技能系统
      if (Random().nextDouble() < chance) {
        fightMove = 0;
        // Events.triggerFight(); // 暂时注释掉事件系统
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
    if (hp.isFinite && !hp.isNaN) {
      health = hp;
      if (health > getMaxHealth()) {
        health = getMaxHealth();
      }
      notifyListeners();
    }
  }

  /// 获取肉类治疗量
  int meatHealAmount() {
    // return meatHeal * (sm.hasPerk('gastronome') ? 2 : 1); // 暂时注释掉技能系统
    return meatHeal;
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
    // final sm = StateManager();
    // if (sm.hasPerk('precise')) {
    //   return baseHitChance + 0.1;
    // }
    return baseHitChance;
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

  /// 回家
  void goHome() {
    // Engine().travelTo(Room()); // 暂时注释掉，直到Engine有travelTo方法
    NotificationManager().notify(name, '回到了村庄');
    notifyListeners();
  }

  /// 检查前哨站是否已使用
  bool outpostUsed() {
    final key = '${curPos[0]},${curPos[1]}';
    return usedOutposts[key] ?? false;
  }

  /// 标记前哨站为已使用
  void markOutpostUsed() {
    final key = '${curPos[0]},${curPos[1]}';
    usedOutposts[key] = true;
  }

  /// 死亡
  void die() {
    dead = true;
    health = 0;
    NotificationManager().notify(name, '你死了');

    // 死亡冷却时间
    // Timer(Duration(seconds: deathCooldown), () {
    //   // 重生逻辑
    //   dead = false;
    //   health = getMaxHealth();
    //   water = getMaxWater();
    //   curPos = [villagePos[0], villagePos[1]];
    //   starvation = false;
    //   thirst = false;
    //   notifyListeners();
    // });

    notifyListeners();
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    final sm = StateManager();

    // 初始化状态
    final worldData = sm.get('game.world', true);
    if (worldData != null && worldData is Map<String, dynamic>) {
      state = worldData;
    } else {
      print('⚠️ 世界数据无效，使用默认状态');
      state = null;
    }

    // 设置初始位置和状态
    curPos = [villagePos[0], villagePos[1]];
    health = getMaxHealth();
    water = getMaxWater();

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
    switch (terrain) {
      case ';':
        return '森林';
      case ',':
        return '田野';
      case '.':
        return '荒地';
      case '#':
        return '道路';
      case 'A':
        return '村庄';
      case 'H':
        return '旧房子';
      case 'V':
        return '潮湿洞穴';
      case 'O':
        return '废弃小镇';
      case 'Y':
        return '废墟城市';
      case 'P':
        return '前哨站';
      case 'W':
        return '坠毁星舰';
      case 'I':
        return '铁矿';
      case 'C':
        return '煤矿';
      case 'S':
        return '硫磺矿';
      case 'B':
        return '钻孔';
      case 'F':
        return '战场';
      case 'M':
        return '阴暗沼泽';
      case 'U':
        return '被摧毁的村庄';
      case 'X':
        return '被摧毁的战舰';
      default:
        return '未知地形';
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

  /// 使用前哨站
  void useOutpost() {
    markOutpostUsed();
    NotificationManager().notify(name, '在前哨站休息了一下');
    notifyListeners();
  }

  /// 标记位置为已访问
  void markVisited(int x, int y) {
    final key = '$x,$y';
    final sm = StateManager();
    sm.set('game.world.visited["$key"]', true);
    notifyListeners();
  }

  /// 清除地牢状态
  void clearDungeon() {
    final sm = StateManager();
    sm.set('game.world.dungeonCleared', true);
    NotificationManager().notify(name, '地牢已清理完毕');
    notifyListeners();
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
}

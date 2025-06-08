import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import 'path.dart';
import 'events.dart';
import 'setpieces.dart';
import 'room.dart';

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
    if (state == null) {
      print('⚠️ move() - state为null，无法移动');
      return;
    }

    // 检查是否死亡，死亡状态下不能移动
    if (dead) {
      NotificationManager().notify(name, '你已经死了，无法移动');
      print('⚠️ move() - 玩家已死亡，无法移动');
      return;
    }

    final oldPos = [curPos[0], curPos[1]];
    final oldTile = state!['map'][curPos[0]][curPos[1]];
    curPos[0] += direction[0];
    curPos[1] += direction[1];
    final newTile = state!['map'][curPos[0]][curPos[1]];

    print('🚶 移动: [${oldPos[0]}, ${oldPos[1]}] -> [${curPos[0]}, ${curPos[1]}], $oldTile -> $newTile');
    print('🚶 即将调用doSpace()...');

    narrateMove(oldTile, newTile);
    lightMap(curPos[0], curPos[1], state!['mask']);
    // drawMap(); // 在Flutter中由UI自动更新
    doSpace();

    print('🚶 doSpace()调用完成，即将调用notifyListeners()...');

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

    print('🗺️ doSpace() - 当前位置: [${curPos[0]}, ${curPos[1]}], 地形: $curTile');

    if (curTile == tile['village']) {
      print('🏠 触发村庄事件 - 回到小黑屋');
      goHome();
    } else if (originalTile == tile['executioner']) {
      // 执行者场景（暂时注释掉，需要实现Executioner事件）
      // final scene = state!['executioner'] ? 'executioner-antechamber' : 'executioner-intro';
      // Events().startEvent(Events.Executioner[scene]);
      print('🔮 发现执行者装置');
      NotificationManager().notify(name, '发现了一个神秘的装置');
      if (!isVisited) {
        markVisited(curPos[0], curPos[1]); // 只有未访问时才标记
      }
    } else if (landmarks.containsKey(originalTile)) {
      // 检查是否是地标（使用原始字符检查）
      print('🏛️ 触发地标事件: $originalTile (visited: $isVisited)');
      if (originalTile != tile['outpost'] || !outpostUsed()) {
        // 只有未访问的地标才触发事件
        if (!isVisited) {
          // 触发地标建筑事件
          final landmarkInfo = landmarks[originalTile];
          if (landmarkInfo != null && landmarkInfo['scene'] != null) {
            final setpieces = Setpieces();
            final sceneName = landmarkInfo['scene'];

            // 检查场景是否存在
            if (setpieces.isSetpieceAvailable(sceneName)) {
              print('🏛️ 启动Setpiece场景: $sceneName');
              setpieces.startSetpiece(sceneName);
            } else {
              // 为缺失的场景提供默认处理
              print('🏛️ 场景不存在，使用默认处理: $sceneName');
              _handleMissingSetpiece(originalTile, landmarkInfo);
            }
          } else {
            print('🏛️ 地标信息无效: $landmarkInfo');
            _handleMissingSetpiece(originalTile, {'label': '未知地标'});
          }
        } else {
          print('🏛️ 地标已访问，跳过事件');
        }
      } else {
        print('🏛️ 前哨站已使用，跳过事件');
      }
      // 注意：地标事件不消耗补给！
    } else {
      print('🚶 普通移动 - 使用补给和检查战斗');
      // 只有在普通地形移动时才消耗补给
      if (useSupplies()) {
        checkFight();
      }
    }
  }

  /// 处理缺失的场景事件
  void _handleMissingSetpiece(
      String curTile, Map<String, dynamic> landmarkInfo) {
    final label = landmarkInfo['label'] ?? '未知地点';

    switch (curTile) {
      case 'I': // 铁矿
        NotificationManager().notify(name, '发现了一个废弃的铁矿。里面可能有有用的资源。');
        // 简单的资源奖励
        final sm = StateManager();
        sm.add('stores["iron"]', 5);
        markVisited(curPos[0], curPos[1]);
        break;

      case 'C': // 煤矿
        NotificationManager().notify(name, '发现了一个废弃的煤矿。黑色的煤炭散落在地上。');
        final sm = StateManager();
        sm.add('stores["coal"]', 5);
        markVisited(curPos[0], curPos[1]);
        break;

      case 'S': // 硫磺矿
        NotificationManager().notify(name, '发现了一个硫磺矿。空气中弥漫着刺鼻的气味。');
        final sm = StateManager();
        sm.add('stores["sulphur"]', 5);
        markVisited(curPos[0], curPos[1]);
        break;

      case 'H': // 旧房子
        NotificationManager().notify(name, '发现了一座废弃的房子。也许里面有什么有用的东西。');
        // 随机奖励
        final sm = StateManager();
        final random = Random();
        if (random.nextDouble() < 0.5) {
          sm.add('stores["wood"]', random.nextInt(3) + 1);
        }
        if (random.nextDouble() < 0.3) {
          sm.add('stores["cloth"]', random.nextInt(2) + 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'B': // 钻孔
        NotificationManager().notify(name, '发现了一个深深的钻孔。底部传来奇怪的声音。');
        markVisited(curPos[0], curPos[1]);
        break;

      case 'F': // 战场
        NotificationManager().notify(name, '这里曾经发生过激烈的战斗。地上散落着武器和装备。');
        final sm = StateManager();
        final random = Random();
        if (random.nextDouble() < 0.4) {
          sm.add('stores["bullets"]', random.nextInt(5) + 1);
        }
        if (random.nextDouble() < 0.2) {
          sm.add('stores["rifle"]', 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'Y': // 废墟城市
        NotificationManager().notify(name, '巨大的废墟城市矗立在眼前。曾经的繁华已成过往。');
        markVisited(curPos[0], curPos[1]);
        break;

      case 'W': // 坠毁星舰
        NotificationManager().notify(name, '发现了一艘坠毁的星舰。金属外壳闪闪发光。');
        markVisited(curPos[0], curPos[1]);
        break;

      case 'O': // 废弃小镇
        NotificationManager().notify(name, '发现了一个废弃的小镇。街道上空无一人，但可能还有有用的物品。');
        final sm = StateManager();
        final random = Random();
        // 小镇可能有各种物品
        if (random.nextDouble() < 0.4) {
          sm.add('stores["cloth"]', random.nextInt(3) + 1);
        }
        if (random.nextDouble() < 0.3) {
          sm.add('stores["leather"]', random.nextInt(2) + 1);
        }
        if (random.nextDouble() < 0.2) {
          sm.add('stores["medicine"]', 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'V': // 潮湿洞穴
        NotificationManager().notify(name, '发现了一个潮湿的洞穴。里面很黑，但可能藏着什么。');
        final sm2 = StateManager();
        final random2 = Random();
        if (random2.nextDouble() < 0.3) {
          sm2.add('stores["fur"]', random2.nextInt(2) + 1);
        }
        if (random2.nextDouble() < 0.2) {
          sm2.add('stores["teeth"]', random2.nextInt(3) + 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'M': // 阴暗沼泽
        NotificationManager().notify(name, '进入了一片阴暗的沼泽。空气潮湿，充满了腐败的气味。');
        final sm3 = StateManager();
        final random3 = Random();
        // 沼泽可能有特殊的物品
        if (random3.nextDouble() < 0.3) {
          sm3.add('stores["scales"]', random3.nextInt(2) + 1);
        }
        if (random3.nextDouble() < 0.2) {
          sm3.add('stores["teeth"]', random3.nextInt(3) + 1);
        }
        if (random3.nextDouble() < 0.1) {
          sm3.add('stores["alien alloy"]', 1);
        }
        markVisited(curPos[0], curPos[1]);
        break;

      case 'U': // 被摧毁的村庄
        NotificationManager().notify(name, '这里曾经是一个村庄，现在只剩下废墟。');
        markVisited(curPos[0], curPos[1]);
        break;

      default:
        NotificationManager().notify(name, '发现了$label。');
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

    print(
        '🍖 useSupplies() - foodMove: $foodMove/$movesPerFood, waterMove: $waterMove/$movesPerWater');
    print('🍖 当前状态 - 饥饿: $starvation, 口渴: $thirst, 水: $water');

    // 食物
    int currentMovesPerFood = movesPerFood;
    // currentMovesPerFood *= sm.hasPerk('slow metabolism') ? 2 : 1; // 暂时注释掉技能系统

    if (foodMove >= currentMovesPerFood) {
      foodMove = 0;

      // 安全地访问Path().outfit，避免null错误
      try {
        var num = path.outfit['cured meat'] ?? 0;
        print('🍖 需要消耗食物 - 熏肉数量: $num');
        num--;

        if (num == 0) {
          NotificationManager().notify(name, '肉已经用完了');
          print('⚠️ 肉已经用完了');
        } else if (num < 0) {
          // 饥饿！
          num = 0;
          if (!starvation) {
            NotificationManager().notify(name, '饥饿开始了');
            starvation = true;
            print('⚠️ 开始饥饿状态');
          } else {
            sm.set('character.starved',
                (sm.get('character.starved', true) ?? 0) + 1);
            // if (sm.get('character.starved') >= 10 && !sm.hasPerk('slow metabolism')) {
            //   sm.addPerk('slow metabolism');
            // }
            print('💀 饥饿死亡！');
            die();
            return false;
          }
        } else {
          starvation = false;
          setHp(health + meatHealAmount());
          print('🍖 消耗了熏肉，剩余: $num，恢复生命值');
        }

        // 安全地更新outfit
        path.outfit['cured meat'] = num;

        // 同步到StateManager
        sm.set('outfit["cured meat"]', num);
      } catch (e) {
        print('⚠️ 访问Path().outfit时出错: $e');
        // 如果访问失败，跳过食物消耗
      }
    }

    // 水
    int currentMovesPerWater = movesPerWater;
    // currentMovesPerWater *= sm.hasPerk('desert rat') ? 2 : 1; // 暂时注释掉技能系统

    if (waterMove >= currentMovesPerWater) {
      waterMove = 0;
      var waterAmount = water;
      print('💧 需要消耗水 - 当前水量: $waterAmount');
      waterAmount--;

      if (waterAmount == 0) {
        NotificationManager().notify(name, '没有更多的水了');
        print('⚠️ 没有更多的水了');
      } else if (waterAmount < 0) {
        waterAmount = 0;
        if (!thirst) {
          NotificationManager().notify(name, '口渴变得难以忍受');
          thirst = true;
          print('⚠️ 开始口渴状态');
        } else {
          sm.set('character.dehydrated',
              (sm.get('character.dehydrated', true) ?? 0) + 1);
          // if (sm.get('character.dehydrated') >= 10 && !sm.hasPerk('desert rat')) {
          //   sm.addPerk('desert rat');
          // }
          print('💀 口渴死亡！');
          die();
          return false;
        }
      } else {
        thirst = false;
        print('💧 消耗了水，剩余: $waterAmount');
      }
      setWater(waterAmount);
      // updateSupplies(); // 在Flutter中由状态管理自动更新
    }
    return true;
  }

  /// 检查战斗
  void checkFight() {
    fightMove++;
    print(
        '🎯 World.checkFight() - fightMove: $fightMove, fightDelay: $fightDelay');

    if (fightMove > fightDelay) {
      double chance = fightChance;
      // chance *= sm.hasPerk('stealthy') ? 0.5 : 1; // 暂时注释掉技能系统
      final randomValue = Random().nextDouble();
      print('🎯 战斗检查 - chance: $chance, random: $randomValue');

      if (randomValue < chance) {
        fightMove = 0;
        print('🎯 触发战斗！');
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

  /// 回家 - 参考原游戏的goHome函数
  void goHome() {
    print('🏠 World.goHome() 开始');

    // 保存世界状态到StateManager - 参考原游戏逻辑
    if (state != null) {
      final sm = StateManager();
      sm.setM('game.world', state!);
      print('🏠 保存世界状态完成');

      // 检查并解锁建筑 - 参考原游戏的建筑解锁逻辑
      if (state!['sulphurmine'] == true &&
          (sm.get('game.buildings["sulphur mine"]', true) ?? 0) == 0) {
        sm.add('game.buildings["sulphur mine"]', 1);
        print('🏠 解锁硫磺矿');
      }
      if (state!['ironmine'] == true &&
          (sm.get('game.buildings["iron mine"]', true) ?? 0) == 0) {
        sm.add('game.buildings["iron mine"]', 1);
        print('🏠 解锁铁矿');
      }
      if (state!['coalmine'] == true &&
          (sm.get('game.buildings["coal mine"]', true) ?? 0) == 0) {
        sm.add('game.buildings["coal mine"]', 1);
        print('🏠 解锁煤矿');
      }
      if (state!['ship'] == true &&
          !sm.get('features.location.spaceShip', true)) {
        // Ship.init(); // 暂时注释掉，需要实现Ship模块
        sm.set('features.location.spaceShip', true);
        print('🏠 解锁星舰');
      }
      if (state!['executioner'] == true &&
          !sm.get('features.location.fabricator', true)) {
        // Fabricator.init(); // 暂时注释掉，需要实现Fabricator模块
        sm.set('features.location.fabricator', true);
        NotificationManager().notify(name, '建造者知道这个奇怪的装置。很快就把它拿走了。没有问它从哪里来的。');
        print('🏠 解锁制造器');
      }

      // 清空世界状态
      state = null;
    }

    // 返回装备到仓库 - 参考原游戏的returnOutfit函数
    returnOutfit();

    // 回到小黑屋模块
    final engine = Engine();
    final room = Room();
    engine.travelTo(room);

    NotificationManager().notify(name, '安全回到了村庄');
    print('🏠 World.goHome() 完成');
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

      print('🎒 装备已返回仓库');
    } catch (e) {
      print('⚠️ 返回装备时出错: $e');
    }
  }

  /// 检查物品是否应该留在家里 - 参考原游戏的leaveItAtHome函数
  bool leaveItAtHome(String thing) {
    // 这些物品可以带走：食物、弹药、能量电池、护身符、药物、武器、可制作物品
    return thing != 'cured meat' &&
        thing != 'bullets' &&
        thing != 'energy cell' &&
        thing != 'charm' &&
        thing != 'medicine' &&
        thing != 'stim' &&
        thing != 'hypo' &&
        !weapons.containsKey(thing); // 武器可以带走
    // && typeof Room.Craftables[thing] == 'undefined'; // 暂时注释掉，需要实现Room.Craftables
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

  /// 死亡 - 参考原游戏的World.die函数
  void die() {
    if (!dead) {
      dead = true;
      health = 0;
      print('💀 玩家死亡');

      // 显示死亡通知
      NotificationManager().notify(name, '世界渐渐消失了');

      // 清空世界状态和装备 - 参考原游戏逻辑
      state = null;
      final path = Path();
      try {
        path.outfit.clear();
      } catch (e) {
        print('⚠️ 清空装备时出错: $e');
      }

      // 清除StateManager中的装备数据
      final sm = StateManager();
      sm.remove('outfit');

      // 播放死亡音效（暂时注释掉）
      // AudioEngine().playSound(AudioLibrary.death);

      // 延迟后回到小黑屋 - 参考原游戏的动画时序
      Timer(const Duration(milliseconds: 2000), () {
        // 回到小黑屋模块
        final engine = Engine();
        final room = Room();
        engine.travelTo(room);

        // 重置死亡状态
        dead = false;

        print('🏠 返回小黑屋');
      });

      notifyListeners();
    }
  }

  /// 重生
  void respawn() {
    print('🔄 World.respawn() 被调用');
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
      print('⚠️ 重置装备时出错: $e');
    }

    NotificationManager().notify(name, '你重生了，回到了村庄');
    print('✅ 重生完成 - 生命值: $health, 水: $water');
    notifyListeners();
  }

  /// 手动重生（用于测试）
  void forceRespawn() {
    print('🔄 强制重生被调用');
    respawn();
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    final sm = StateManager();

    // 初始化状态
    final worldMap = sm.get('game.world.map', true);
    final worldMask = sm.get('game.world.mask', true);

    if (worldMap != null && worldMask != null) {
      state = {
        'map': worldMap,
        'mask': worldMask,
      };
      print('✅ 加载已有世界数据');
    } else {
      print('⚠️ 世界数据无效，重新初始化');
      // 如果没有世界数据，重新初始化
      init();
      final newWorldMap = sm.get('game.world.map', true);
      final newWorldMask = sm.get('game.world.mask', true);

      if (newWorldMap != null && newWorldMask != null) {
        state = {
          'map': newWorldMap,
          'mask': newWorldMask,
        };
        print('✅ 重新生成世界数据成功');
      } else {
        print('❌ 无法生成世界数据');
        state = null;
      }
    }

    // 设置初始位置和状态
    curPos = [villagePos[0], villagePos[1]];
    health = getMaxHealth();
    water = getMaxWater();

    // 如果有有效的地图数据，点亮当前位置
    if (state != null && state!['mask'] != null) {
      try {
        final mask = List<List<bool>>.from(
            state!['mask'].map((row) => List<bool>.from(row)));
        lightMap(curPos[0], curPos[1], mask);
        // 更新状态中的遮罩
        state!['mask'] = mask;
        print('✅ 地图照明完成');
      } catch (e) {
        print('⚠️ 地图照明失败: $e');
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

  /// 使用前哨站 - 参考原游戏的World.useOutpost函数
  void useOutpost() {
    // 补充水到最大值
    water = getMaxWater();
    NotificationManager().notify(name, '水已补充');

    // 标记前哨站为已使用
    markOutpostUsed();

    print('🏛️ 前哨站已使用，水补充到: $water');
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
            map[x][y] = currentTile + '!';
            print('🗺️ 标记位置 ($x, $y) 为已访问: ${map[x][y]}');

            // 更新state中的地图数据
            state!['map'] = map;

            // 立即保存到StateManager以确保持久化
            final sm = StateManager();
            sm.set('game.world.map', map);
            print('🗺️ 地图状态已保存到StateManager');
          } else {
            print('🗺️ 位置 ($x, $y) 已经被标记为已访问: $currentTile');
          }
        }
      } catch (e) {
        print('⚠️ markVisited失败: $e');
        print('⚠️ 地图数据类型: ${state!['map'].runtimeType}');
      }
    }
    notifyListeners();
  }

  /// 清除地牢状态 - 参考原游戏的clearDungeon函数
  void clearDungeon() {
    print('🏛️ World.clearDungeon() - 将当前位置转换为前哨站');

    if (state != null && state!['map'] != null) {
      try {
        // 安全地转换地图数据类型
        final mapData = state!['map'];
        final map = List<List<String>>.from(
            mapData.map((row) => List<String>.from(row)));

        if (curPos[0] >= 0 &&
            curPos[0] < map.length &&
            curPos[1] >= 0 &&
            curPos[1] < map[curPos[0]].length) {
          final oldTile = map[curPos[0]][curPos[1]];
          map[curPos[0]][curPos[1]] = tile['outpost']!;

          print(
              '🏛️ 地形转换: $oldTile -> ${tile['outpost']} 在位置 [${curPos[0]}, ${curPos[1]}]');

          // 更新state中的地图数据
          state!['map'] = map;

          // 绘制道路连接到前哨站 - 参考原游戏的drawRoad函数
          drawRoad();

          // 标记前哨站为已使用（因为玩家刚刚清理了这里）
          markOutpostUsed();

          // 重新绘制地图以更新显示 - 关键！
          notifyListeners();
        }
      } catch (e) {
        print('⚠️ clearDungeon失败: $e');
      }
    }

    final sm = StateManager();
    sm.set('game.world.dungeonCleared', true);
    NotificationManager().notify(name, '地牢已清理完毕，这里现在是一个前哨站');
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

    final xDir = xDist.abs() ~/ xDist; // 方向：1 或 -1
    final yDir = yDist.abs() ~/ yDist; // 方向：1 或 -1

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

    print(
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
    print('🧪 测试地标事件: $landmarkType');
    if (landmarks.containsKey(landmarkType)) {
      final landmarkInfo = landmarks[landmarkType];
      print('🧪 地标信息: $landmarkInfo');
      _handleMissingSetpiece(landmarkType, landmarkInfo!);
    } else {
      print('🧪 地标类型不存在: $landmarkType');
    }
  }

  /// 测试函数：手动标记位置为已访问（用于调试）
  void testMarkVisited() {
    print('🧪 测试标记当前位置为已访问');
    markVisited(curPos[0], curPos[1]);
  }
}

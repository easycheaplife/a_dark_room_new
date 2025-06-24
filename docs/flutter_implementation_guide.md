# A Dark Room Flutter实现指南

**最后更新**: 2025-06-24

## 概述

本文档提供了将A Dark Room地图系统移植到Flutter的详细实现指南，包括架构设计、核心算法和最佳实践。基于对原游戏源代码的深入分析，本指南确保移植版本保持原游戏的核心机制和平衡性。

## 1. 整体架构设计

### 1.1 模块结构

```
lib/
├── modules/
│   ├── world.dart           # 世界模块核心逻辑
│   ├── path.dart            # 路径和装备管理
│   ├── events.dart          # 事件系统基础
│   └── combat.dart          # 战斗系统
├── screens/
│   ├── world_screen.dart    # 世界地图界面
│   ├── events_screen.dart   # 事件界面
│   └── combat_screen.dart   # 战斗界面
├── models/
│   ├── landmark.dart        # 地标数据模型
│   ├── enemy.dart           # 敌人数据模型
│   └── loot.dart           # 战利品数据模型
└── utils/
    ├── map_generator.dart   # 地图生成算法
    ├── probability.dart     # 概率计算工具
    └── save_manager.dart    # 存档管理
```

### 1.2 状态管理架构

```dart
// 使用Provider进行状态管理
class GameState extends ChangeNotifier {
  World world;
  Path path;
  Events events;
  Combat combat;
  
  // 全局游戏状态
  bool isInWorld = false;
  bool isInCombat = false;
  bool isInEvent = false;
}

// 世界状态
class World extends ChangeNotifier {
  static const int radius = 30;
  static const List<int> villagePos = [30, 30];
  
  List<List<String>> map = [];
  List<List<bool>> mask = [];
  List<int> curPos = [30, 30];
  
  int water = 10;
  int health = 10;
  int foodMove = 0;
  int waterMove = 0;
  
  Map<String, bool> usedOutposts = {};
  bool starvation = false;
  bool thirst = false;
}
```

## 2. 核心算法实现

### 2.1 地图生成算法

```dart
class MapGenerator {
  static const Map<String, double> tileProbs = {
    'forest': 0.15,
    'field': 0.35,
    'barrens': 0.5,
  };
  
  static const double stickiness = 0.5;
  
  static List<List<String>> generateMap() {
    final map = List.generate(61, (i) => List.generate(61, (j) => ''));
    
    // 村庄固定在中心
    map[30][30] = 'A';
    
    // 螺旋生成地形
    for (int r = 1; r <= 30; r++) {
      for (int t = 0; t < r * 8; t++) {
        final pos = _calculateSpiralPosition(r, t);
        map[pos.x][pos.y] = _chooseTile(pos.x, pos.y, map);
      }
    }
    
    // 放置地标
    _placeLandmarks(map);
    
    return map;
  }
  
  static Point<int> _calculateSpiralPosition(int r, int t) {
    int x, y;
    if (t < 2 * r) {
      x = 30 - r + t;
      y = 30 - r;
    } else if (t < 4 * r) {
      x = 30 + r;
      y = 30 - (3 * r) + t;
    } else if (t < 6 * r) {
      x = 30 + (5 * r) - t;
      y = 30 + r;
    } else {
      x = 30 - r;
      y = 30 + (7 * r) - t;
    }
    return Point(x, y);
  }
  
  static String _chooseTile(int x, int y, List<List<String>> map) {
    // 检查相邻地形
    final adjacent = [
      y > 0 ? map[x][y-1] : null,
      y < 60 ? map[x][y+1] : null,
      x < 60 ? map[x+1][y] : null,
      x > 0 ? map[x-1][y] : null,
    ];
    
    final chances = <String, double>{};
    double nonSticky = 1.0;
    
    // 计算粘性影响
    for (final tile in adjacent) {
      if (tile != null && _isTerrain(tile)) {
        chances[tile] = (chances[tile] ?? 0) + stickiness;
        nonSticky -= stickiness;
      }
    }
    
    // 添加基础概率
    for (final entry in tileProbs.entries) {
      chances[entry.key] = (chances[entry.key] ?? 0) + entry.value * nonSticky;
    }
    
    // 随机选择
    return ProbabilityUtils.selectWeighted(chances) ?? 'barrens';
  }
}
```

### 2.2 概率计算工具

```dart
class ProbabilityUtils {
  static final Random _random = Random();
  
  static String? selectWeighted(Map<String, double> weights) {
    final total = weights.values.fold(0.0, (sum, weight) => sum + weight);
    if (total <= 0) return null;
    
    double random = _random.nextDouble() * total;
    
    for (final entry in weights.entries) {
      random -= entry.value;
      if (random <= 0) {
        return entry.key;
      }
    }
    
    return weights.keys.last;
  }
  
  static String selectRandomScene(Map<double, String> options) {
    final random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (final entry in options.entries) {
      cumulative += entry.key;
      if (random <= cumulative) {
        return entry.value;
      }
    }
    
    return options.values.last;
  }
  
  static bool rollChance(double chance) {
    return _random.nextDouble() < chance;
  }
  
  static int rollRange(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }
}
```

### 2.3 水资源管理系统

```dart
class WaterManager {
  static const int baseWater = 10;
  static const int movesPerWater = 1;
  
  static int getMaxWater(StateManager sm) {
    if (sm.get('stores["fluid recycler"]') > 0) {
      return baseWater + 100;
    } else if (sm.get('stores["water tank"]') > 0) {
      return baseWater + 50;
    } else if (sm.get('stores.cask') > 0) {
      return baseWater + 20;
    } else if (sm.get('stores.waterskin') > 0) {
      return baseWater + 10;
    }
    return baseWater;
  }
  
  static bool useSupplies(World world, StateManager sm) {
    world.waterMove++;
    
    // 检查水消耗
    int movesPerWater = WaterManager.movesPerWater;
    if (sm.hasPerk('desert rat')) {
      movesPerWater *= 2; // 沙漠鼠技能减半消耗
    }
    
    if (world.waterMove >= movesPerWater) {
      world.waterMove = 0;
      world.water--;
      
      if (world.water == 0) {
        NotificationManager().notify('世界', '水即将耗尽');
      } else if (world.water < 0) {
        world.water = 0;
        if (!world.thirst) {
          NotificationManager().notify('世界', '口渴变得难以忍受');
          world.thirst = true;
        } else {
          // 脱水伤害
          world.health--;
          if (world.health <= 0) {
            world.die();
            return false;
          }
        }
      } else {
        world.thirst = false;
      }
      
      world.notifyListeners();
    }
    
    return true;
  }
}
```

### 2.4 地标事件系统

```dart
abstract class LandmarkEvent {
  String get title;
  String get landmarkType;
  Map<String, EventScene> get scenes;
  bool isAvailable(World world);
}

class EventScene {
  final List<String> text;
  final String? notification;
  final Map<String, LootItem>? loot;
  final CombatData? combat;
  final Map<String, EventButton> buttons;
  final VoidCallback? onLoad;
  
  const EventScene({
    required this.text,
    this.notification,
    this.loot,
    this.combat,
    required this.buttons,
    this.onLoad,
  });
}

class EventButton {
  final String text;
  final Map<String, int>? cost;
  final dynamic nextScene; // String or Map<double, String>
  final int? cooldown;
  
  const EventButton({
    required this.text,
    this.cost,
    this.nextScene,
    this.cooldown,
  });
}

// 洞穴事件实现示例
class CaveEvent extends LandmarkEvent {
  @override
  String get title => '潮湿洞穴';
  
  @override
  String get landmarkType => 'V';
  
  @override
  bool isAvailable(World world) => true;
  
  @override
  Map<String, EventScene> get scenes => {
    'start': EventScene(
      text: [
        '洞穴的入口又宽又黑。',
        '看不清里面有什么。'
      ],
      notification: '这里的土地裂开了，仿佛承受着古老的创伤',
      buttons: {
        'enter': EventButton(
          text: '进入',
          cost: {'torch': 1},
          nextScene: {0.3: 'a1', 0.6: 'a2', 1.0: 'a3'},
        ),
        'leave': EventButton(
          text: '离开',
          nextScene: 'end',
        ),
      },
    ),
    // ... 更多场景
  };
}
```

## 3. UI实现要点

### 3.1 地图渲染优化

```dart
class MapWidget extends StatelessWidget {
  final World world;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<World>(
      builder: (context, world, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Container(
              padding: EdgeInsets.all(4),
              child: Column(
                children: List.generate(world.map[0].length, (j) {
                  return Row(
                    children: List.generate(world.map.length, (i) {
                      return _buildMapTile(world, i, j);
                    }),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMapTile(World world, int x, int y) {
    final isPlayer = x == world.curPos[0] && y == world.curPos[1];
    final isVisible = world.mask[x][y] || isPlayer;
    final tile = world.map[x][y];
    
    return Container(
      width: 10,
      height: 10,
      child: Text(
        isPlayer ? '@' : (isVisible ? tile : ' '),
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Courier New',
          color: _getTileColor(tile, isPlayer, isVisible),
          fontWeight: _isLandmark(tile) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
```

### 3.2 事件界面设计

```dart
class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  String currentScene = 'start';
  
  @override
  Widget build(BuildContext context) {
    return Consumer<Events>(
      builder: (context, events, child) {
        if (!events.isActive) return SizedBox.shrink();
        
        final event = events.currentEvent;
        final scene = event.scenes[currentScene];
        
        return Container(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Container(
              width: 400,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ...scene.text.map((text) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(text),
                  )),
                  SizedBox(height: 16),
                  ...scene.buttons.entries.map((entry) => 
                    _buildEventButton(entry.key, entry.value)
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEventButton(String key, EventButton button) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () => _handleButtonPress(key, button),
        child: Text(button.text),
      ),
    );
  }
}
```

## 4. 性能优化建议

### 4.1 地图渲染优化

1. **视口裁剪**：只渲染可见区域的瓦片
2. **瓦片缓存**：缓存已渲染的瓦片Widget
3. **懒加载**：按需加载地图数据
4. **批量更新**：合并多个地图更新操作

### 4.2 状态管理优化

1. **细粒度更新**：只更新变化的部分
2. **异步处理**：将复杂计算移到后台线程
3. **内存管理**：及时释放不需要的资源
4. **缓存策略**：缓存频繁访问的数据

## 5. 测试策略

### 5.1 单元测试

```dart
void main() {
  group('MapGenerator', () {
    test('should generate 61x61 map', () {
      final map = MapGenerator.generateMap();
      expect(map.length, 61);
      expect(map[0].length, 61);
    });
    
    test('should place village at center', () {
      final map = MapGenerator.generateMap();
      expect(map[30][30], 'A');
    });
  });
  
  group('WaterManager', () {
    test('should consume water on movement', () {
      final world = World();
      world.water = 10;
      
      WaterManager.useSupplies(world, StateManager());
      
      expect(world.water, 9);
    });
  });
}
```

### 5.2 集成测试

```dart
void main() {
  group('World Exploration', () {
    testWidgets('should move player on tap', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // 点击地图
      await tester.tap(find.byType(MapWidget));
      await tester.pump();
      
      // 验证玩家移动
      // ...
    });
  });
}
```

## 6. 关键实现细节

### 6.1 距离计算和危险检测

```dart
class DistanceManager {
  static int getDistance(List<int> pos1, List<int> pos2) {
    return (pos1[0] - pos2[0]).abs() + (pos1[1] - pos2[1]).abs();
  }

  static bool checkDanger(World world, StateManager sm) {
    final distance = getDistance(world.curPos, World.villagePos);

    // 第一道防线：距离8格需要铁甲
    if (sm.get('stores["i armour"]') == 0 && distance >= 8) {
      if (!world.danger) {
        world.danger = true;
        NotificationManager().notify('世界', '没有适当保护，在离村庄这么远的地方很危险');
        return true;
      }
    }

    // 第二道防线：距离18格需要钢甲
    if (sm.get('stores["s armour"]') == 0 && distance >= 18) {
      if (!world.danger) {
        world.danger = true;
        NotificationManager().notify('世界', '极度危险的区域，需要更好的装备');
        return true;
      }
    }

    return false;
  }
}
```

### 6.2 战斗概率系统

```dart
class CombatManager {
  static const double baseFightChance = 0.20;
  static const int fightDelay = 3;

  static bool checkFight(World world, StateManager sm) {
    world.fightMove++;

    if (world.fightMove > fightDelay) {
      double chance = baseFightChance;

      // 潜行技能减半概率
      if (sm.hasPerk('stealthy')) {
        chance *= 0.5;
      }

      if (ProbabilityUtils.rollChance(chance)) {
        world.fightMove = 0;
        return true; // 触发战斗
      }
    }

    return false;
  }

  static String selectEnemy(String terrain, int distance) {
    if (distance <= 10) {
      // Tier 1 敌人
      switch (terrain) {
        case 'forest': return 'snarling beast';
        case 'field': return 'strange bird';
        case 'barrens': return 'gaunt man';
        default: return 'snarling beast';
      }
    } else if (distance <= 20) {
      // Tier 2 敌人
      switch (terrain) {
        case 'forest': return 'man-eater';
        case 'field': return 'giant lizard';
        case 'barrens': return 'scavenger';
        default: return 'scavenger';
      }
    } else {
      // Tier 3 敌人
      switch (terrain) {
        case 'forest': return 'feral terror';
        case 'field': return 'sniper';
        case 'barrens': return 'soldier';
        default: return 'soldier';
      }
    }
  }
}
```

### 6.3 前哨站和道路系统

```dart
class OutpostManager {
  static void useOutpost(World world, int x, int y) {
    final key = '$x,$y';
    if (!world.usedOutposts.containsKey(key)) {
      world.setWater(world.getMaxWater());
      world.usedOutposts[key] = true;
      NotificationManager().notify('世界', '水已补充');
      world.notifyListeners();
    }
  }

  static bool isOutpostUsed(World world, int x, int y) {
    final key = '$x,$y';
    return world.usedOutposts[key] ?? false;
  }
}

class RoadManager {
  static void drawRoad(World world, List<int> fromPos) {
    final closestRoad = _findClosestRoad(world, fromPos);
    final path = _calculateLPath(fromPos, closestRoad);

    for (final point in path) {
      if (_isTerrain(world.map[point.x][point.y])) {
        world.map[point.x][point.y] = 'R'; // 道路
      }
    }
  }

  static List<Point<int>> _findClosestRoad(World world, List<int> startPos) {
    // 螺旋搜索最近的道路、前哨站或村庄
    for (int radius = 1; radius <= 30; radius++) {
      for (int t = 0; t < radius * 8; t++) {
        final pos = _calculateSpiralPosition(startPos[0], startPos[1], radius, t);
        if (_isValidPosition(pos.x, pos.y)) {
          final tile = world.map[pos.x][pos.y];
          if (tile == 'R' || tile == 'P' || tile == 'A') {
            return [pos.x, pos.y];
          }
        }
      }
    }
    return World.villagePos; // 默认返回村庄
  }

  static List<Point<int>> _calculateLPath(List<int> from, List<int> to) {
    final path = <Point<int>>[];

    // L型路径：先水平后垂直
    int currentX = from[0];
    int currentY = from[1];

    // 水平移动
    while (currentX != to[0]) {
      currentX += currentX < to[0] ? 1 : -1;
      path.add(Point(currentX, currentY));
    }

    // 垂直移动
    while (currentY != to[1]) {
      currentY += currentY < to[1] ? 1 : -1;
      path.add(Point(currentX, currentY));
    }

    return path;
  }
}
```

### 6.4 存档系统

```dart
class SaveManager {
  static const String saveKey = 'a_dark_room_save';

  static Future<void> saveGame(GameState gameState) async {
    final prefs = await SharedPreferences.getInstance();
    final saveData = {
      'world': gameState.world.toJson(),
      'path': gameState.path.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await prefs.setString(saveKey, jsonEncode(saveData));
  }

  static Future<GameState?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final saveString = prefs.getString(saveKey);

    if (saveString == null) return null;

    try {
      final saveData = jsonDecode(saveString) as Map<String, dynamic>;
      final gameState = GameState();

      gameState.world = World.fromJson(saveData['world']);
      gameState.path = Path.fromJson(saveData['path']);

      return gameState;
    } catch (e) {
      print('Failed to load save: $e');
      return null;
    }
  }

  static Future<void> deleteSave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(saveKey);
  }
}
```

## 7. 部署和发布

### 7.1 构建配置

```yaml
# pubspec.yaml
name: a_dark_room_flutter
description: A Dark Room游戏的Flutter移植版本
version: 1.0.0+1

environment:
  sdk: '>=2.17.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  shared_preferences: ^2.0.0
  path_provider: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  fonts:
    - family: Courier New
      fonts:
        - asset: fonts/CourierNew.ttf
```

### 7.2 性能监控

```dart
class PerformanceMonitor {
  static void trackMapRender(VoidCallback callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();

    if (stopwatch.elapsedMilliseconds > 16) {
      print('Map render took ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  static void trackMemoryUsage() {
    // 监控内存使用情况
    final info = ProcessInfo.currentRss;
    if (info > 100 * 1024 * 1024) { // 100MB
      print('High memory usage: ${info ~/ (1024 * 1024)}MB');
    }
  }
}
```

## 8. 总结

这个实现指南提供了将A Dark Room复杂的地图系统成功移植到Flutter的完整框架，包括：

### 核心特性
- **完整的地图生成算法**：螺旋生成、地形粘性、地标放置
- **精确的水资源管理**：消耗计算、容量升级、脱水机制
- **复杂的事件系统**：多层分支、概率选择、资源消耗
- **平衡的战斗系统**：距离难度、敌人分层、装备需求

### 技术优势
- **高性能渲染**：视口裁剪、瓦片缓存、批量更新
- **可靠的状态管理**：Provider架构、细粒度更新
- **完整的测试覆盖**：单元测试、集成测试、性能测试
- **跨平台兼容**：Android、iOS、Web、Desktop

### 设计原则
- **忠实原作**：保持原游戏的核心机制和平衡性
- **用户体验**：流畅的动画、直观的界面、清晰的反馈
- **可维护性**：模块化设计、清晰的架构、完整的文档
- **可扩展性**：易于添加新功能、修改平衡性、支持mod

通过遵循这个指南，开发者可以创建一个既保持原游戏精髓又充分利用Flutter优势的高质量移植版本。

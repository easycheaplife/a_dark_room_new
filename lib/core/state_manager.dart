import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// StateManager (SM) 是游戏的中央状态管理系统
/// 它替代了原始游戏中的 JavaScript $SM 对象
class StateManager with ChangeNotifier {
  static final StateManager _instance = StateManager._internal();

  factory StateManager() {
    return _instance;
  }

  StateManager._internal();

  // 游戏状态
  Map<String, dynamic> _state = {};

  // Getters
  Map<String, dynamic> get state => _state;

  // 初始化状态管理器
  void init() {
    if (_state.isEmpty) {
      _state = {
        'version': 1.3,
        'stores': {},
        'income': {},
        'character': {
          'perks': {},
        },
        'game': {
          'fire': {'value': 0},
          'temperature': {'value': 0},
          'builder': {'level': -1},
          'buildings': {},
          'workers': {},
          'population': 0,
          'thieves': false,
          'stolen': {},
        },
        'features': {
          'location': {
            'room': true,
          },
        },
        'playStats': {},
        'config': {
          'lightsOff': false,
          'hyperMode': false,
          'soundOn': true,
        },
        'cooldown': {},
        'wait': {},
        'outfit': {},
        'previous': {},
        'timers': {},
      };
      notifyListeners();
    }
  }

  // 从状态中获取值
  dynamic get(String path, [bool nullIfMissing = false]) {
    List<String> parts = path.split('.');
    dynamic current = _state;

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];

      // Handle array notation like "stores['wood']"
      if (part.contains('[') && part.contains(']')) {
        int startBracket = part.indexOf('[');
        int endBracket = part.indexOf(']');

        String objName = part.substring(0, startBracket);
        String key = part.substring(startBracket + 2, endBracket - 1);

        if (current[objName] == null) {
          if (nullIfMissing) return null;
          return 0;
        }

        current = current[objName];

        if (current[key] == null) {
          if (nullIfMissing) return null;
          return 0;
        }

        current = current[key];
      } else {
        if (current[part] == null) {
          if (nullIfMissing) return null;
          if (i == parts.length - 1 && part == 'value') {
            return 0;
          }
          return 0;
        }

        current = current[part];
      }
    }

    return current;
  }

  // 在状态中设置值
  void set(String path, dynamic value, [bool noNotify = false]) {
    List<String> parts = path.split('.');
    dynamic current = _state;

    for (int i = 0; i < parts.length - 1; i++) {
      String part = parts[i];

      // Handle array notation like "stores['wood']"
      if (part.contains('[') && part.contains(']')) {
        int startBracket = part.indexOf('[');
        int endBracket = part.indexOf(']');

        String objName = part.substring(0, startBracket);
        String key = part.substring(startBracket + 2, endBracket - 1);

        if (current[objName] == null) {
          current[objName] = {};
        }

        current = current[objName];

        if (current[key] == null) {
          current[key] = {};
        }

        current = current[key];
      } else {
        if (current[part] == null) {
          current[part] = {};
        }

        current = current[part];
      }
    }

    String lastPart = parts.last;

    // Handle array notation for the last part
    if (lastPart.contains('[') && lastPart.contains(']')) {
      int startBracket = lastPart.indexOf('[');
      int endBracket = lastPart.indexOf(']');

      String objName = lastPart.substring(0, startBracket);
      String key = lastPart.substring(startBracket + 2, endBracket - 1);

      if (current[objName] == null) {
        current[objName] = {};
      }

      current = current[objName];
      current[key] = value;
    } else {
      current[lastPart] = value;
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // 向状态中的现有值添加值
  void add(String path, dynamic value, [bool noNotify = false]) {
    dynamic current = get(path);

    if (current == null) {
      set(path, value, noNotify);
    } else if (current is double && value is double) {
      set(path, current + value, noNotify);
    } else if (current is int && value is int) {
      set(path, current + value, noNotify);
    } else if (current is String && value is String) {
      set(path, current + value, noNotify);
    } else if (current is List && value is List) {
      List newList = List.from(current);
      newList.addAll(value);
      set(path, newList, noNotify);
    } else if (current is Map && value is Map) {
      Map newMap = Map.from(current);
      newMap.addAll(value);
      set(path, newMap, noNotify);
    }
  }

  // 一次设置多个值
  void setM(String path, Map<String, dynamic> values, [bool noNotify = false]) {
    for (String key in values.keys) {
      set('$path["$key"]', values[key], true);
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // 从状态中获取数值
  double getNum(String path, dynamic object) {
    if (object != null && object.type == 'building') {
      return (get('game.buildings["$path"]', true) ?? 0).toDouble();
    }
    return (get('stores["$path"]', true) ?? 0).toDouble();
  }

  // 设置资源的收入
  void setIncome(String source, Map<String, dynamic> options) {
    if (_state['income'] == null) {
      _state['income'] = {};
    }

    _state['income'][source] = options;
    notifyListeners();
  }

  // 收集所有来源的收入
  void collectIncome() {
    if (_state['income'] == null) return;

    for (String source in _state['income'].keys) {
      Map<String, dynamic> income = _state['income'][source];

      if (income['stores'] != null) {
        for (String store in income['stores'].keys) {
          add('stores["$store"]', income['stores'][store]);
        }
      }
    }
  }

  // 保存游戏状态
  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonState = jsonEncode(_state);
      await prefs.setString('gameState', jsonState);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game: $e');
      }
    }
  }

  // 加载游戏状态
  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonState = prefs.getString('gameState');

      if (jsonState != null) {
        _state = jsonDecode(jsonState);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading game: $e');
      }
    }
  }

  // 更新旧状态格式到新格式
  void updateOldState() {
    var version = get('version');
    if (version is! num) version = 1.0;

    if (version == 1.0) {
      // v1.1 引入了Lodge，所以移除没有lodge的猎人
      remove('outside.workers.hunter', true);
      remove('income.hunter', true);
      if (kDebugMode) {
        print('升级存档到 v1.1');
      }
      version = 1.1;
    }

    if (version == 1.1) {
      // v1.2 在地图上添加了沼泽，所以将其添加到已生成的地图中
      if (get('world') != null) {
        // 在Flutter版本中，我们需要实现World.placeLandmark
        // World.placeLandmark(15, World.RADIUS * 1.5, World.TILE.SWAMP, get('world.map'));
      }
      if (kDebugMode) {
        print('升级存档到 v1.2');
      }
      version = 1.2;
    }

    if (version == 1.2) {
      // 添加了StateManager，所以将数据移动到新位置
      remove('room.fire');
      remove('room.temperature');
      remove('room.buttons');
      if (get('room') != null) {
        set('features.location.room', true);
        set('game.builder.level', get('room.builder'));
        remove('room');
      }
      if (get('outside') != null) {
        set('features.location.outside', true);
        set('game.population', get('outside.population'));
        set('game.buildings', get('outside.buildings'));
        set('game.workers', get('outside.workers'));
        set('game.outside.seenForest', get('outside.seenForest'));
        remove('outside');
      }
      if (get('world') != null) {
        set('features.location.world', true);
        set('game.world.map', get('world.map'));
        set('game.world.mask', get('world.mask'));
        set('starved', get('character.starved', true));
        set('dehydrated', get('character.dehydrated', true));
        remove('world');
        remove('starved');
        remove('dehydrated');
      }
      if (get('ship') != null) {
        set('features.location.spaceShip', true);
        set('game.spaceShip.hull', get('ship.hull', true));
        set('game.spaceShip.thrusters', get('ship.thrusters', true));
        set('game.spaceShip.seenWarning', get('ship.seenWarning'));
        set('game.spaceShip.seenShip', get('ship.seenShip'));
        remove('ship');
      }
      if (get('punches') != null) {
        set('character.punches', get('punches'));
        remove('punches');
      }
      if (get('perks') != null) {
        set('character.perks', get('perks'));
        remove('perks');
      }
      if (get('thieves') != null) {
        set('game.thieves', get('thieves'));
        remove('thieves');
      }
      if (get('stolen') != null) {
        set('game.stolen', get('stolen'));
        remove('stolen');
      }
      if (get('cityCleared') != null) {
        set('character.cityCleared', get('cityCleared'));
        remove('cityCleared');
      }
      set('version', 1.3);
    }
  }

  // 从状态中移除值
  void remove(String path, [bool noNotify = false]) {
    List<String> parts = path.split('.');
    dynamic current = _state;

    try {
      for (int i = 0; i < parts.length - 1; i++) {
        String part = parts[i];

        // 处理数组表示法，如 "stores['wood']"
        if (part.contains('[') && part.contains(']')) {
          int startBracket = part.indexOf('[');
          int endBracket = part.indexOf(']');

          String objName = part.substring(0, startBracket);
          String key = part.substring(startBracket + 2, endBracket - 1);

          if (current[objName] == null) {
            return; // 父对象不存在
          }

          current = current[objName];

          if (current[key] == null) {
            return; // 键不存在
          }

          current = current[key];
        } else {
          if (current[part] == null) {
            return; // 路径不存在
          }

          current = current[part];
        }
      }

      String lastPart = parts.last;

      // 处理最后一部分的数组表示法
      if (lastPart.contains('[') && lastPart.contains(']')) {
        int startBracket = lastPart.indexOf('[');
        int endBracket = lastPart.indexOf(']');

        String objName = lastPart.substring(0, startBracket);
        String key = lastPart.substring(startBracket + 2, endBracket - 1);

        if (current[objName] != null) {
          current = current[objName];
          current.remove(key);
        }
      } else {
        if (current is Map) {
          current.remove(lastPart);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('警告：尝试移除不存在的状态 \'$path\'。');
      }
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // 移除分支（递归移除）
  void removeBranch(String path, [bool noNotify = false]) {
    dynamic obj = get(path);

    if (obj is Map) {
      for (var key in obj.keys.toList()) {
        if (obj[key] is Map) {
          removeBranch('$path["$key"]', true);
        }
      }

      if (obj.isEmpty) {
        remove(path, true);
      }
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // 添加技能
  void addPerk(String name) {
    set('character.perks["$name"]', true);
    // 在原始游戏中，这会显示通知
    // Notifications.notify(null, Engine.Perks[name].notify);
  }

  // 检查是否有技能
  bool hasPerk(String name) {
    return get('character.perks["$name"]') == true;
  }

  // 添加被盗物品
  void addStolen(Map<String, dynamic> stores) {
    for (var k in stores.keys) {
      var old = get('stores["$k"]', true) ?? 0;
      var short = old + stores[k];
      // 如果他们会偷走比实际拥有的更多
      if (short < 0) {
        add('game.stolen["$k"]', (stores[k] * -1) + short);
      } else {
        add('game.stolen["$k"]', stores[k] * -1);
      }
    }
  }

  // 开始小偷事件
  void startThieves() {
    set('game.thieves', true);
    setIncome('thieves', {
      'delay': 10,
      'stores': {'wood': -10, 'fur': -5, 'meat': -5}
    });
  }
}

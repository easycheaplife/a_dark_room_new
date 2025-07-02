import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'logger.dart';
import 'localization.dart';

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
    // 如果状态为空，创建初始状态
    if (_state.isEmpty) {
      Logger.info('🎮 StateManager: Initializing new game state');
      _initializeNewGameState();
      Logger.info(
          '✅ StateManager: Initial state created with wood: ${_state['stores']['wood']}');
      notifyListeners();
    } else {
      Logger.info(
          '🔄 StateManager: Using existing state with wood: ${_state['stores']?['wood']}');
      // 确保已加载的状态有所有必需的字段
      _ensureRequiredFields();
    }
  }

  // 初始化新游戏状态
  void _initializeNewGameState() {
    _state = {
      'version': 1.3,
      'stores': {
        'wood': 0, // 原始游戏从0个木材开始，点火是免费的
      },
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
        'stokeCount': 0, // 添柴次数计数器
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
  }

  // 确保已加载的状态有所有必需的字段
  void _ensureRequiredFields() {
    // 确保基本类别存在
    final requiredCategories = [
      'features',
      'stores',
      'character',
      'income',
      'timers',
      'game',
      'playStats',
      'previous',
      'outfit',
      'config',
      'wait',
      'cooldown'
    ];

    for (String category in requiredCategories) {
      if (_state[category] == null) {
        _state[category] = {};
      }
    }

    // 确保版本号存在
    if (_state['version'] == null) {
      _state['version'] = 1.3;
    }

    // 确保基本配置存在
    if (_state['config'] != null) {
      final config = _safeMapCast(_state['config']);
      config['lightsOff'] ??= false;
      config['hyperMode'] ??= false;
      config['soundOn'] ??= true;
      _state['config'] = config;
    }

    // 确保游戏状态存在
    if (_state['game'] != null) {
      final game = _safeMapCast(_state['game']);
      game['fire'] ??= {'value': 0};
      game['temperature'] ??= {'value': 0};
      game['builder'] ??= {'level': -1};
      game['buildings'] ??= {};
      game['workers'] ??= {};
      game['population'] ??= 0;
      game['thieves'] ??= false;
      game['stolen'] ??= {};
      game['stokeCount'] ??= 0;
      _state['game'] = game;
    }

    // 确保特性状态存在
    if (_state['features'] != null) {
      final features = _safeMapCast(_state['features']);
      features['location'] ??= {};
      final location = _safeMapCast(features['location']);
      location['room'] ??= true;
      features['location'] = location;
      _state['features'] = features;
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

    // 重要：stores值不能为负数（按照原游戏逻辑）
    if (path.startsWith('stores') && value is num && value < 0) {
      if (kDebugMode) {
        Logger.info(
            '⚠️ StateManager: stores value cannot be negative, setting $path from $value to 0');
      }
      // 重新设置为0，确保类型一致性
      final zeroValue = value is int ? 0 : 0.0;
      if (lastPart.contains('[') && lastPart.contains(']')) {
        int startBracket = lastPart.indexOf('[');
        int endBracket = lastPart.indexOf(']');
        String objName = lastPart.substring(0, startBracket);
        String key = lastPart.substring(startBracket + 2, endBracket - 1);

        // 确保父对象存在
        if (current[objName] == null) {
          current[objName] = {};
        }
        current[objName][key] = zeroValue;
      } else {
        current[lastPart] = zeroValue;
      }
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
    } else if ((current is num) && (value is num)) {
      // 处理所有数字类型的组合 (int, double)
      // 使用set方法确保负数检查生效
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
      set('$path.$key', values[key], true);
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // 一次添加多个值
  void addM(String path, Map<String, dynamic> values, [bool noNotify = false]) {
    for (String key in values.keys) {
      final value = values[key];
      // 确保数值类型一致性 - 将所有数值转换为int（原游戏使用整数）
      if (value is num && value != value.toInt()) {
        // 如果是小数，四舍五入到最近的整数
        add('$path.$key', value.round(), true);
      } else {
        add('$path.$key', value, true);
      }
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // 从状态中获取数值
  double getNum(String path, dynamic object) {
    if (object != null && object.type == 'building') {
      return (get('game.buildings.$path', true) ?? 0).toDouble();
    }
    return (get('stores.$path', true) ?? 0).toDouble();
  }

  // 设置资源的收入
  void setIncome(String source, Map<String, dynamic> options) {
    if (_state['income'] == null) {
      _state['income'] = {};
    }

    _state['income'][source] = options;
    notifyListeners();
  }

  // 收集所有来源的收入 - 按照原游戏逻辑实现
  void collectIncome() {
    if (_state['income'] == null) return;

    bool changed = false;

    for (String source in _state['income'].keys) {
      Map<String, dynamic> income = _state['income'][source];

      // 初始化timeLeft如果不存在
      if (income['timeLeft'] == null) {
        income['timeLeft'] = 0;
      }

      // 减少时间 - 确保timeLeft是int类型
      final currentTimeLeft = income['timeLeft'];
      income['timeLeft'] = (currentTimeLeft is int
              ? currentTimeLeft
              : (currentTimeLeft as num).toInt()) -
          1;

      // 如果时间到了，收集收入
      if (income['timeLeft'] <= 0) {
        if (kDebugMode) {
          final localization = Localization();
          Logger.info(
              '🏭 ${localization.translateLog('collecting_income_from')} $source ${localization.translateLog('income_suffix')}');
        }

        // 检查是否有足够的资源（对于消耗型工人）
        bool canProduce = true;
        if (source != 'thieves' && income['stores'] != null) {
          final stores = _safeMapCast(income['stores']);
          for (String store in stores.keys) {
            final cost = stores[store];
            if (cost < 0) {
              // 如果是消耗资源
              final have = get('stores.$store', true) ?? 0;
              if (have + cost < 0) {
                canProduce = false;
                if (kDebugMode) {
                  final localization = Localization();
                  Logger.error(
                      '⚠️ $source ${localization.translateLog('lacks')} $store ${localization.translateLog('resources_cannot_produce')}');
                }
                break;
              }
            }
          }
        }

        // 如果可以生产，添加/消耗资源
        if (canProduce && income['stores'] != null) {
          final stores = _safeMapCast(income['stores']);
          // 使用addM方法，它会自动处理负数检查
          addM('stores', stores, true);
          changed = true;
        }

        // 重置计时器 - 确保delay转换为int
        if (income['delay'] != null) {
          final delay = income['delay'];
          income['timeLeft'] = delay is int ? delay : (delay as num).toInt();
        }
      }
    }

    // 如果有变化，通知监听器
    if (changed) {
      notifyListeners();
    }
  }

  // 保存游戏状态
  Future<void> saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 确保状态不为空
      if (_state.isEmpty) {
        if (kDebugMode) {
          Logger.error('⚠️ StateManager: Cannot save empty state');
        }
        return;
      }

      // 创建保存状态的副本，确保与原游戏格式兼容
      final saveState = Map<String, dynamic>.from(_state);

      // 确保版本号正确
      saveState['version'] = 1.3;

      final jsonState = jsonEncode(saveState);

      // 调试：显示要保存的数据
      Logger.info('🔍 StateManager: Saving data length: ${jsonState.length}');
      Logger.info(
          '🔍 StateManager: Saving data preview: ${jsonState.substring(0, jsonState.length > 100 ? 100 : jsonState.length)}...');

      final success = await prefs.setString('gameState', jsonState);
      Logger.info('🔍 StateManager: Save operation result: $success');

      // 同时保存时间戳
      await prefs.setInt(
          'gameStateTimestamp', DateTime.now().millisecondsSinceEpoch);

      // 验证保存是否成功
      final verifyState = prefs.getString('gameState');
      if (verifyState != null && verifyState == jsonState) {
        Logger.info(
            '✅ StateManager: Save verified successfully - Wood: ${saveState['stores']?['wood']}');
      } else {
        Logger.error('❌ StateManager: Save verification failed!');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('❌ Failed to save game: $e');
      }
    }
  }

  // 自动保存游戏状态（每30秒）
  void startAutoSave() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      saveGame();
    });
  }

  // 加载游戏状态
  Future<void> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 调试：列出所有保存的键
      final keys = prefs.getKeys();
      Logger.info('🔍 StateManager: Available keys: $keys');

      final jsonState = prefs.getString('gameState');
      Logger.info(
          '🔍 StateManager: Raw saved data: ${jsonState?.substring(0, jsonState.length > 100 ? 100 : jsonState.length)}...');

      if (jsonState != null && jsonState.isNotEmpty) {
        Logger.info('💾 StateManager: Loading saved game state');
        final decodedData = jsonDecode(jsonState);

        // 安全的类型转换
        Map<String, dynamic> loadedState;
        if (decodedData is Map<String, dynamic>) {
          loadedState = decodedData;
        } else if (decodedData is Map) {
          // 处理LinkedMap等其他Map类型
          loadedState = Map<String, dynamic>.from(decodedData);
        } else {
          Logger.error(
              '❌ StateManager: Invalid data type: ${decodedData.runtimeType}');
          loadedState = {};
        }

        // 验证加载的状态是否有效
        if (loadedState.isNotEmpty) {
          _state = loadedState;

          // 更新旧状态格式（如果需要）
          updateOldState();

          Logger.info(
              '📊 StateManager: Loaded state with wood: ${_state['stores']?['wood']}');
          Logger.info('📊 StateManager: State version: ${_state['version']}');
          notifyListeners();
        } else {
          Logger.error(
              '⚠️ StateManager: Loaded state is empty, will use default');
        }
      } else {
        Logger.error(
            '🆕 StateManager: No saved game found (jsonState: $jsonState), will use default state');
      }
    } catch (e) {
      Logger.error('❌ StateManager: Error loading game: $e');
      if (kDebugMode) {
        Logger.error('Error loading game: $e');
      }
      // 如果加载失败，保持空状态，让init()创建新状态
      _state = {};
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
        Logger.info('Upgrading save to v1.1');
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
        Logger.info('Upgrading save to v1.2');
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
        Logger.error(
            'Warning: Attempting to remove non-existent state \'$path\'.');
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
    set('character.perks.$name', true);
    // 在原始游戏中，这会显示通知
    // Notifications.notify(null, Engine.Perks[name].notify);
  }

  // 检查是否有技能
  bool hasPerk(String name) {
    return get('character.perks.$name') == true;
  }

  // 添加被盗物品
  void addStolen(Map<String, dynamic> stores) {
    for (var k in stores.keys) {
      var old = get('stores.$k', true) ?? 0;
      var short = old + stores[k];
      // 如果他们会偷走比实际拥有的更多
      if (short < 0) {
        add('game.stolen.$k', (stores[k] * -1) + short);
      } else {
        add('game.stolen.$k', stores[k] * -1);
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

  // 确保状态结构完整 - 用于导入时
  void _ensureStateStructure() {
    // 确保基本分类存在
    final categories = [
      'features',
      'stores',
      'character',
      'income',
      'timers',
      'game',
      'playStats',
      'previous',
      'outfit',
      'config',
      'wait',
      'cooldown'
    ];

    for (String category in categories) {
      if (_state[category] == null) {
        _state[category] = {};
      }
    }

    // 确保版本号存在
    if (_state['version'] == null) {
      _state['version'] = 1.3;
    }

    // 确保基本配置存在
    if (_state['config'] != null) {
      final config = _safeMapCast(_state['config']);
      config['lightsOff'] ??= false;
      config['hyperMode'] ??= false;
      config['soundOn'] ??= true;
      _state['config'] = config;
    }

    // 确保游戏状态存在
    if (_state['game'] != null) {
      final game = _safeMapCast(_state['game']);
      game['fire'] ??= {'value': 0};
      game['temperature'] ??= {'value': 0};
      game['builder'] ??= {'level': -1};
      game['buildings'] ??= {};
      game['workers'] ??= {};
      game['population'] ??= 0;
      game['thieves'] ??= false;
      game['stolen'] ??= {};
      game['stokeCount'] ??= 0;
      _state['game'] = game;
    }

    // 确保特性状态存在
    if (_state['features'] != null) {
      final features = _safeMapCast(_state['features']);
      features['location'] ??= {};
      final location = _safeMapCast(features['location']);
      location['room'] ??= true;
      features['location'] = location;
      _state['features'] = features;
    }

    // 确保stores存在
    if (_state['stores'] == null) {
      _state['stores'] = {};
    }
  }

  // 导出游戏状态为JSON字符串 - 兼容原游戏格式
  String exportGameState() {
    try {
      // 创建与原游戏完全兼容的状态格式
      final exportData = Map<String, dynamic>.from(_state);

      // 确保版本号与原游戏一致
      exportData['version'] = 1.3;

      // 移除Flutter特有的字段
      exportData.remove('exportTimestamp');
      exportData.remove('exportVersion');

      return jsonEncode(exportData);
    } catch (e) {
      if (kDebugMode) {
        Logger.error('❌ Failed to export game state: $e');
      }
      rethrow;
    }
  }

  // 从JSON字符串导入游戏状态 - 兼容原游戏格式
  Future<bool> importGameState(String jsonData) async {
    try {
      final decodedData = jsonDecode(jsonData);

      // 安全的类型转换
      Map<String, dynamic> importedData;
      if (decodedData is Map<String, dynamic>) {
        importedData = decodedData;
      } else if (decodedData is Map) {
        importedData = Map<String, dynamic>.from(decodedData);
      } else {
        Logger.error('❌ Invalid import data type: ${decodedData.runtimeType}');
        return false;
      }

      // 验证导入数据的基本结构
      if (!_validateImportData(importedData)) {
        if (kDebugMode) {
          Logger.error('❌ Invalid import data format');
        }
        return false;
      }

      // 移除导出相关的元数据（如果存在）
      importedData.remove('exportTimestamp');
      importedData.remove('exportVersion');

      // 备份当前状态
      final backupState = Map<String, dynamic>.from(_state);

      try {
        // 导入新状态
        _state = importedData;

        // 确保状态结构完整
        _ensureStateStructure();

        // 更新旧状态格式（如果需要）
        updateOldState();

        // 保存导入的状态
        await saveGame();

        // 通知监听器
        notifyListeners();

        if (kDebugMode) {
          Logger.info('✅ Game state imported successfully');
          Logger.info(
              '📊 Wood count after import: ${_state['stores']?['wood']}');
        }

        return true;
      } catch (e) {
        // 如果导入失败，恢复备份状态
        _state = backupState;
        notifyListeners();

        if (kDebugMode) {
          Logger.error('❌ Import failed, restored original state: $e');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('❌ Failed to parse import data: $e');
      }
      return false;
    }
  }

  // 验证导入数据的基本结构
  bool _validateImportData(Map<String, dynamic> data) {
    // 检查必要的字段
    if (!data.containsKey('version')) return false;
    if (!data.containsKey('stores')) return false;
    if (!data.containsKey('game')) return false;

    // 检查版本兼容性
    final version = data['version'];
    if (version is! num || version < 1.0 || version > 1.3) {
      return false;
    }

    return true;
  }

  // 获取保存时间信息
  Future<String?> getSaveTimeInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('gameStateTimestamp');

      if (timestamp != null) {
        final saveTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(saveTime);

        if (difference.inDays > 0) {
          return '${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hours ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} minutes ago';
        } else {
          return 'just now';
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('❌ Failed to get save time: $e');
      }
      return null;
    }
  }

  // 清除游戏数据
  Future<void> clearGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gameState');
      await prefs.remove('gameStateTimestamp');

      // 重置为初始状态
      _state.clear();
      init();

      if (kDebugMode) {
        Logger.info('🗑️ Game data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('❌ Failed to clear game data: $e');
      }
    }
  }

  /// 重置StateManager的内存状态（用于重新开始游戏）
  void reset() {
    Logger.info('🔄 重置StateManager内存状态');
    _state = {};
    Logger.info('🔄 StateManager内存状态已清空');
  }

  /// 安全的Map类型转换辅助方法
  Map<String, dynamic> _safeMapCast(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      Logger.error('❌ Invalid map data type: ${data.runtimeType}');
      return {};
    }
  }
}

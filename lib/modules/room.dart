import 'dart:async';
import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/audio_engine.dart';
import '../core/audio_library.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import '../widgets/button.dart';
import 'outside.dart';
import 'path.dart';

/// Room 是游戏的起始模块
class Room with ChangeNotifier {
  static final Room _instance = Room._internal();

  factory Room() {
    return _instance;
  }

  Room._internal();

  // 常量（时间单位：毫秒）
  static const int _fireCoolDelay = 5 * 60 * 1000; // 火焰冷却延迟
  // static const int _roomWarmDelay = 30 * 1000; // 房间温度更新延迟 - 暂时未使用
  static const int _builderStateDelay = 30 * 1000; // 建造者状态更新延迟
  // static const int _stokeCooldown = 10; // 添柴冷却时间 - 暂时未使用
  static const int _needWoodDelay = 15 * 1000; // 需要木材的延迟

  // 模块名称
  final String name = "Room";

  // UI元素
  late Widget panel;
  late Widget tab;

  // 按钮
  Map<String, GameButton> buttons = {};

  // 计时器
  Timer? _fireTimer;
  // Timer? _tempTimer; // 暂时未使用
  Timer? _builderTimer;

  // 状态
  bool changed = false;
  bool pathDiscovery = false;

  // 可制作物品
  final Map<String, Map<String, dynamic>> craftables = {
    'trap': {
      'name': 'trap',
      'button': null,
      'maximum': 10,
      'availableMsg':
          'builder says she can make traps to catch any creatures might still be alive out there',
      'buildMsg': 'more traps to catch more creatures',
      'maxMsg': "more traps won't help now",
      'type': 'building',
      'cost': (StateManager sm) {
        final n = sm.get('game.buildings["trap"]', true) ?? 0;
        return {'wood': 10 + (n * 10)};
      },
      'audio': AudioLibrary.build,
    },
    'cart': {
      'name': 'cart',
      'button': null,
      'maximum': 1,
      'availableMsg': 'builder says she can make a cart for carrying wood',
      'buildMsg': 'the rickety cart will carry more wood from the forest',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 30};
      },
      'audio': AudioLibrary.build,
    },
    'hut': {
      'name': 'hut',
      'button': null,
      'maximum': 20,
      'availableMsg':
          "builder says there are more wanderers. says they'll work, too.",
      'buildMsg':
          'builder puts up a hut, out in the forest. says word will get around.',
      'maxMsg': 'no more room for huts.',
      'type': 'building',
      'cost': (StateManager sm) {
        final n = sm.get('game.buildings["hut"]', true) ?? 0;
        return {'wood': 100 + (n * 50)};
      },
      'audio': AudioLibrary.build,
    },
    'lodge': {
      'name': 'lodge',
      'button': null,
      'maximum': 1,
      'availableMsg': 'villagers could help hunt, given the means',
      'buildMsg': 'the hunting lodge stands in the forest, a ways out of town',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 200, 'fur': 10, 'meat': 5};
      },
      'audio': AudioLibrary.build,
    },
    'trading post': {
      'name': 'trading post',
      'button': null,
      'maximum': 1,
      'availableMsg': "a trading post would make commerce easier",
      'buildMsg':
          "now the nomads have a place to set up shop, they might stick around a while",
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 400, 'fur': 100};
      },
      'audio': AudioLibrary.build,
    },
    'tannery': {
      'name': 'tannery',
      'button': null,
      'maximum': 1,
      'availableMsg':
          "builder says leather could be useful. says the villagers could make it.",
      'buildMsg': 'tannery goes up quick, on the edge of the village',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 500, 'fur': 50};
      },
      'audio': AudioLibrary.build,
    }
  };

  // 交易物品
  final Map<String, Map<String, dynamic>> tradeGoods = {
    'scales': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 150};
      },
      'audio': AudioLibrary.buy,
    },
    'teeth': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 300};
      },
      'audio': AudioLibrary.buy,
    },
    'iron': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 150, 'scales': 50};
      },
      'audio': AudioLibrary.buy,
    },
    'coal': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 200, 'teeth': 50};
      },
      'audio': AudioLibrary.buy,
    },
    'steel': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 300, 'scales': 50, 'teeth': 50};
      },
      'audio': AudioLibrary.buy,
    },
    'medicine': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'scales': 50, 'teeth': 30};
      },
      'audio': AudioLibrary.buy,
    },
    'bullets': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'scales': 10};
      },
      'audio': AudioLibrary.buy,
    },
    'energy cell': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'scales': 10, 'teeth': 10};
      },
      'audio': AudioLibrary.buy,
    },
    'bolas': {
      'type': 'weapon',
      'cost': (StateManager sm) {
        return {'teeth': 10};
      },
      'audio': AudioLibrary.buy,
    },
    'compass': {
      'type': 'special',
      'maximum': 1,
      'cost': (StateManager sm) {
        return {'fur': 400, 'scales': 20, 'teeth': 10};
      },
      'audio': AudioLibrary.buy,
    }
  };

  // 温度枚举
  static const Map<String, Map<String, dynamic>> tempEnum = {
    'Freezing': {'value': 0, 'text': 'freezing'},
    'Cold': {'value': 1, 'text': 'cold'},
    'Mild': {'value': 2, 'text': 'mild'},
    'Warm': {'value': 3, 'text': 'warm'},
    'Hot': {'value': 4, 'text': 'hot'},
  };

  // 火焰枚举
  static const Map<String, Map<String, dynamic>> fireEnum = {
    'Dead': {'value': 0, 'text': 'dead'},
    'Smoldering': {'value': 1, 'text': 'smoldering'},
    'Flickering': {'value': 2, 'text': 'flickering'},
    'Burning': {'value': 3, 'text': 'burning'},
    'Roaring': {'value': 4, 'text': 'roaring'},
  };

  // 初始化房间
  Future<void> init() async {
    final sm = StateManager();

    // Set up initial state if not already set
    if (sm.get('features.location.room') == null) {
      sm.set('features.location.room', true);
      sm.set('game.builder.level', -1);
    }

    // 设置初始温度和火焰状态
    if (sm.get('game.temperature.value') == null) {
      sm.set('game.temperature', tempEnum['Freezing']!['value']);
    }

    if (sm.get('game.fire.value') == null) {
      sm.set('game.fire', fireEnum['Dead']!['value']);
    }

    // 设置路径发现
    pathDiscovery = sm.get('stores.compass', true) != null &&
        sm.get('stores.compass', true) > 0;

    // 如果有指南针，打开路径
    if (pathDiscovery) {
      Path().init();

      // 在原始游戏中，这会调用 Path.openPath()
      // Path.openPath();
    }

    // 启动计时器
    _fireTimer = Engine().setTimeout(() => coolFire(), _fireCoolDelay);
    // _tempTimer = Engine().setTimeout(() => adjustTemp(), _roomWarmDelay); // 暂时注释掉

    // Check builder state
    final builderLevel = sm.get('game.builder.level');
    if (builderLevel != null && builderLevel >= 0 && builderLevel < 3) {
      _builderTimer =
          Engine().setTimeout(() => updateBuilderState(), _builderStateDelay);
    }

    // 检查是否需要解锁森林
    if (builderLevel == 1 &&
        sm.get('stores.wood', true) != null &&
        sm.get('stores.wood', true) < 0) {
      Engine().setTimeout(() => unlockForest(), _needWoodDelay);
    }

    // Notify about room state
    final tempValue = sm.get('game.temperature.value');
    final fireValue = sm.get('game.fire.value');

    String tempText = '';
    String fireText = '';

    for (final entry in tempEnum.entries) {
      if (entry.value['value'] == tempValue) {
        tempText = entry.value['text'] as String;
        break;
      }
    }

    for (final entry in fireEnum.entries) {
      if (entry.value['value'] == fireValue) {
        fireText = entry.value['text'] as String;
        break;
      }
    }

    NotificationManager().notify(name, 'the room is $tempText');
    NotificationManager().notify(name, 'the fire is $fireText');

    notifyListeners();
  }

  // 当到达此模块时调用
  void onArrival(int transitionDiff) {
    setTitle();

    if (changed) {
      final sm = StateManager();
      final tempValue = sm.get('game.temperature.value');
      final fireValue = sm.get('game.fire.value');

      String tempText = '';
      String fireText = '';

      for (final entry in tempEnum.entries) {
        if (entry.value['value'] == tempValue) {
          tempText = entry.value['text'] as String;
          break;
        }
      }

      for (final entry in fireEnum.entries) {
        if (entry.value['value'] == fireValue) {
          fireText = entry.value['text'] as String;
          break;
        }
      }

      NotificationManager().notify(name, 'the room is $tempText');
      NotificationManager().notify(name, 'the fire is $fireText');
      changed = false;
    }

    final sm = StateManager();
    if (sm.get('game.builder.level') == 3) {
      sm.add('game.builder.level', 1);
      sm.setIncome('builder', {
        'delay': 10,
        'stores': {'wood': 2},
      });

      NotificationManager().notify(name,
          'the stranger is standing by the fire. she says she can help. says she builds things.');
    }

    setMusic();
    notifyListeners();
  }

  // 根据火焰状态设置标题
  void setTitle() {
    // 在原始游戏中，这会设置文档标题
    // 对于Flutter，我们只需更新UI
    // 在实际应用中，可以将title传递给UI组件
    // final sm = StateManager();
    // final fireValue = sm.get('game.fire.value');
    // String title = fireValue < 2 ? '黑暗房间' : '火光房间';

    notifyListeners();
  }

  // 点燃火堆
  void lightFire() {
    final sm = StateManager();
    final wood = sm.get('stores.wood');

    if (wood < 5) {
      NotificationManager()
          .notify(name, 'not enough wood to get the fire going');
      // Clear button cooldown
      return;
    }

    sm.set('stores.wood', wood - 5);
    sm.set('game.fire', fireEnum['Burning']!['value']);
    AudioEngine().playSound(AudioLibrary.lightFire);
    onFireChange();
  }

  // 添柴
  void stokeFire() {
    final sm = StateManager();
    final wood = sm.get('stores.wood');

    if (wood == 0) {
      NotificationManager().notify(name, 'the wood has run out');
      // Clear button cooldown
      return;
    }

    sm.set('stores.wood', wood - 1);

    final fireValue = sm.get('game.fire.value');
    if (fireValue < 4) {
      sm.set('game.fire', fireValue + 1);
    }

    AudioEngine().playSound(AudioLibrary.stokeFire);
    onFireChange();
  }

  // 处理火焰状态变化
  void onFireChange() {
    if (Engine().activeModule != this) {
      changed = true;
    }

    final sm = StateManager();
    final fireValue = sm.get('game.fire.value');

    String fireText = '';
    for (final entry in fireEnum.entries) {
      if (entry.value['value'] == fireValue) {
        fireText = entry.value['text'] as String;
        break;
      }
    }

    NotificationManager().notify(name, 'the fire is $fireText', noQueue: true);

    if (fireValue > 1 && sm.get('game.builder.level') < 0) {
      sm.set('game.builder.level', 0);
      NotificationManager().notify(name,
          'the light from the fire spills from the windows, out into the dark');
      _builderTimer?.cancel();
      _builderTimer =
          Engine().setTimeout(() => updateBuilderState(), _builderStateDelay);
    }

    _fireTimer?.cancel();
    _fireTimer = Engine().setTimeout(() => coolFire(), _fireCoolDelay);

    setTitle();

    // Update music if in the room
    if (Engine().activeModule == this) {
      setMusic();
    }

    notifyListeners();
  }

  // 随时间冷却火焰
  void coolFire() {
    final sm = StateManager();
    final wood = sm.get('stores.wood');
    final fireValue = sm.get('game.fire.value');
    final builderLevel = sm.get('game.builder.level');

    if (fireValue <= fireEnum['Flickering']!['value'] &&
        builderLevel > 3 &&
        wood > 0) {
      NotificationManager()
          .notify(name, 'builder stokes the fire', noQueue: true);
      sm.set('stores.wood', wood - 1);
      sm.set('game.fire', fireValue + 1);
    }

    if (fireValue > 0) {
      sm.set('game.fire', fireValue - 1);
      _fireTimer = Engine().setTimeout(() => coolFire(), _fireCoolDelay);
      onFireChange();
    }
  }

  // 根据火焰调整房间温度
  void adjustTemp() {
    final sm = StateManager();
    final tempValue = sm.get('game.temperature.value');
    final fireValue = sm.get('game.fire.value');

    if (tempValue > 0 && tempValue > fireValue) {
      sm.set('game.temperature', tempValue - 1);

      String tempText = '';
      for (final entry in tempEnum.entries) {
        if (entry.value['value'] == tempValue - 1) {
          tempText = entry.value['text'] as String;
          break;
        }
      }

      NotificationManager()
          .notify(name, 'the room is $tempText', noQueue: true);
    }

    if (tempValue < 4 && tempValue < fireValue) {
      sm.set('game.temperature', tempValue + 1);

      String tempText = '';
      for (final entry in tempEnum.entries) {
        if (entry.value['value'] == tempValue + 1) {
          tempText = entry.value['text'] as String;
          break;
        }
      }

      NotificationManager()
          .notify(name, 'the room is $tempText', noQueue: true);
    }

    if (tempValue != sm.get('game.temperature.value')) {
      changed = true;
    }

    // _tempTimer = Engine().setTimeout(() => adjustTemp(), _roomWarmDelay); // 暂时注释掉
  }

  // 解锁森林位置
  void unlockForest() {
    final sm = StateManager();
    sm.set('stores.wood', 4);
    Outside().init();
    NotificationManager().notify(name, 'the wind howls outside');
    NotificationManager().notify(name, 'the wood is running out');
    Engine().event('progress', 'outside');
  }

  // 更新建造者状态
  void updateBuilderState() {
    final sm = StateManager();
    final builderLevel = sm.get('game.builder.level');

    if (builderLevel == 0) {
      NotificationManager().notify(name,
          'a ragged stranger stumbles through the door and collapses in the corner');
      sm.set('game.builder.level', 1);
      Engine().setTimeout(() => unlockForest(), _needWoodDelay);
    } else if (builderLevel < 3 &&
        sm.get('game.temperature.value') >= tempEnum['Warm']!['value']) {
      String msg = '';

      switch (builderLevel) {
        case 1:
          msg =
              'the stranger shivers, and mumbles quietly. her words are unintelligible.';
          break;
        case 2:
          msg =
              'the stranger in the corner stops shivering. her breathing calms.';
          break;
      }

      NotificationManager().notify(name, msg);

      if (builderLevel < 3) {
        sm.set('game.builder.level', builderLevel + 1);
      }
    }

    if (builderLevel < 3) {
      _builderTimer =
          Engine().setTimeout(() => updateBuilderState(), _builderStateDelay);
    }

    Engine().saveGame();
  }

  // 更新商店视图
  void updateStoresView() {
    final sm = StateManager();
    final stores = sm.get('stores');

    if (stores == null) return;

    // 检查是否有指南针并且还没有发现路径
    if (sm.get('stores.compass') != null && !pathDiscovery) {
      pathDiscovery = true;
      // Path.openPath(); // 当Path模块实现后取消注释
    }

    // 检查盗贼
    for (final entry in stores.entries) {
      final num = entry.value;
      if (sm.get('game.thieves') == null &&
          num > 5000 &&
          sm.get('features.location.world') == true) {
        sm.startThieves();
      }
    }

    notifyListeners();
  }

  // 更新收入视图
  void updateIncomeView() {
    final sm = StateManager();
    final income = sm.get('income');

    if (income == null) return;

    // 计算总收入
    final Map<String, Map<String, dynamic>> totalIncome = {};

    for (final incomeSource in income.keys) {
      final incomeData = income[incomeSource];
      if (incomeData['stores'] != null) {
        for (final store in incomeData['stores'].keys) {
          final storeIncome = incomeData['stores'][store];
          if (storeIncome != 0) {
            if (!totalIncome.containsKey(store)) {
              totalIncome[store] = {'income': 0, 'delay': incomeData['delay']};
            }
            totalIncome[store]!['income'] += storeIncome;
          }
        }
      }
    }

    notifyListeners();
  }

  // 购买物品
  bool buy(String thing) {
    final good = tradeGoods[thing];
    if (good == null) return false;

    final sm = StateManager();
    final numThings = sm.get('stores["$thing"]', true) ?? 0;

    if (good['maximum'] != null && good['maximum'] <= numThings) {
      return false;
    }

    final cost = good['cost']();
    final Map<String, dynamic> storeMod = {};

    // 检查是否有足够的资源
    for (final entry in cost.entries) {
      final have = sm.get('stores["${entry.key}"]', true) ?? 0;
      if (have < entry.value) {
        NotificationManager().notify(name, 'not enough ${entry.key}');
        return false;
      } else {
        storeMod[entry.key] = have - entry.value;
      }
    }

    // 扣除资源
    sm.setM('stores', storeMod);

    // 添加物品
    sm.add('stores["$thing"]', 1);

    // 显示消息
    if (good['buildMsg'] != null) {
      NotificationManager().notify(name, good['buildMsg']);
    }

    // 播放音频
    if (good['audio'] != null) {
      AudioEngine().playSound(good['audio']);
    }

    return true;
  }

  // 建造物品
  bool build(String thing) {
    final craftable = craftables[thing];
    if (craftable == null) return false;

    final sm = StateManager();
    final numThings = sm.get('game.buildings["$thing"]', true) ?? 0;

    if (craftable['maximum'] != null && craftable['maximum'] <= numThings) {
      return false;
    }

    final cost = craftable['cost']();
    final Map<String, dynamic> storeMod = {};

    // 检查是否有足够的资源
    for (final entry in cost.entries) {
      final have = sm.get('stores["${entry.key}"]', true) ?? 0;
      if (have < entry.value) {
        NotificationManager().notify(name, 'not enough ${entry.key}');
        return false;
      } else {
        storeMod[entry.key] = have - entry.value;
      }
    }

    // 扣除资源
    sm.setM('stores', storeMod);

    // 添加建筑
    if (craftable['type'] == 'building') {
      sm.add('game.buildings["$thing"]', 1);
    } else {
      sm.add('stores["$thing"]', 1);
    }

    // 显示消息
    if (craftable['buildMsg'] != null) {
      NotificationManager().notify(name, craftable['buildMsg']);
    }

    // 播放音频
    if (craftable['audio'] != null) {
      AudioEngine().playSound(craftable['audio']);
    }

    return true;
  }

  // 更新建造按钮
  void updateBuildButtons() {
    // 这个方法在Flutter中可能不需要，因为UI会自动更新
    // 保留作为接口兼容性
    notifyListeners();
  }

  // 根据火焰级别设置音乐
  void setMusic() {
    // 暂时禁用背景音乐，直到我们有音频文件
    /*
    final sm = StateManager();
    final fireValue = sm.get('game.fire.value');

    switch (fireValue) {
      case 0:
        AudioEngine().playBackgroundMusic(AudioLibrary.MUSIC_FIRE_DEAD);
        break;
      case 1:
        AudioEngine().playBackgroundMusic(AudioLibrary.MUSIC_FIRE_SMOLDERING);
        break;
      case 2:
        AudioEngine().playBackgroundMusic(AudioLibrary.MUSIC_FIRE_FLICKERING);
        break;
      case 3:
        AudioEngine().playBackgroundMusic(AudioLibrary.MUSIC_FIRE_BURNING);
        break;
      case 4:
        AudioEngine().playBackgroundMusic(AudioLibrary.MUSIC_FIRE_ROARING);
        break;
    }
    */
  }

  // 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    // 处理状态更新事件
    notifyListeners();
  }

  // 按键处理
  void keyDown(dynamic event) {
    // 在原始游戏中，房间模块不处理按键
  }

  void keyUp(dynamic event) {
    // 在原始游戏中，房间模块不处理按键
  }

  // 滑动处理
  void swipeLeft() {
    // 在原始游戏中，房间模块不处理滑动
  }

  void swipeRight() {
    // 在原始游戏中，房间模块不处理滑动
  }

  void swipeUp() {
    // 在原始游戏中，房间模块不处理滑动
  }

  void swipeDown() {
    // 在原始游戏中，房间模块不处理滑动
  }
}

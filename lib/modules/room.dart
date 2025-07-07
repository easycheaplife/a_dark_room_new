import 'dart:async';
import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/audio_engine.dart';
import '../core/audio_library.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import '../core/progress_manager.dart';
import '../widgets/button.dart';
import '../config/game_config.dart';
import 'outside.dart';
import 'path.dart';

/// Room 是游戏的起始模块
class Room with ChangeNotifier {
  static final Room _instance = Room._internal();

  factory Room() {
    return _instance;
  }

  Room._internal();

  // 常量（时间单位：毫秒）- 从GameConfig获取
  static int get _fireCoolDelay => GameConfig.fireCoolDelay; // 火焰冷却延迟
  static int get _roomWarmDelay =>
      GameConfig.getCurrentRoomWarmDelay(); // 房间温度更新延迟
  static int get _builderStateDelay =>
      GameConfig.getCurrentBuilderStateDelay(); // 建造者状态更新延迟
  static int get _needWoodDelay =>
      GameConfig.getCurrentNeedWoodDelay(); // 需要木材的延迟

  // 模块名称
  final String name = "Room";

  // UI元素
  late Widget panel;
  late Widget tab;

  // 按钮
  Map<String, GameButton> buttons = {};

  // 计时器
  Timer? _fireTimer;
  Timer? _tempTimer;
  // 用于延迟调整房间温度
  Timer? _builderTimer;

  // 状态
  bool changed = false;
  bool pathDiscovery = false;

  // 本地化实例 - 使用getter确保总是获取最新状态
  Localization get _localization => Localization();

  // 可制作物品
  final Map<String, Map<String, dynamic>> craftables = {
    'trap': {
      'name': 'trap',
      'button': null,
      'maximum': 10,
      'availableMsg': 'craftables.trap.availableMsg',
      'buildMsg': 'craftables.trap.buildMsg',
      'maxMsg': 'craftables.trap.maxMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        final n = sm.get('game.buildings.trap', true) ?? 0;
        return {'wood': 10 + (n * 10)};
      },
      'audio': AudioLibrary.build,
    },
    'cart': {
      'name': 'cart',
      'button': null,
      'maximum': 1,
      'availableMsg': 'craftables.cart.availableMsg',
      'buildMsg': 'craftables.cart.buildMsg',
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
      'availableMsg': 'craftables.hut.availableMsg',
      'buildMsg': 'craftables.hut.buildMsg',
      'maxMsg': 'craftables.hut.maxMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        final n = sm.get('game.buildings.hut', true) ?? 0;
        return {'wood': 100 + (n * 50)};
      },
      'audio': AudioLibrary.build,
    },
    'lodge': {
      'name': 'lodge',
      'button': null,
      'maximum': 1,
      'availableMsg': 'craftables.lodge.availableMsg',
      'buildMsg': 'craftables.lodge.buildMsg',
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
      'availableMsg': 'craftables.trading post.availableMsg',
      'buildMsg': 'craftables.trading post.buildMsg',
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
      'availableMsg': 'craftables.tannery.availableMsg',
      'buildMsg': 'craftables.tannery.buildMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 500, 'fur': 50};
      },
      'audio': AudioLibrary.build,
    },
    'smokehouse': {
      'name': 'smokehouse',
      'button': null,
      'maximum': 1,
      'availableMsg': 'craftables.smokehouse.availableMsg',
      'buildMsg': 'craftables.smokehouse.buildMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 600, 'meat': 50};
      },
      'audio': AudioLibrary.build,
    },
    'workshop': {
      'name': 'workshop',
      'button': null,
      'maximum': 1,
      'availableMsg': 'craftables.workshop.availableMsg',
      'buildMsg': 'craftables.workshop.buildMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 800, 'leather': 100, 'scales': 10};
      },
      'audio': AudioLibrary.build,
    },
    'steelworks': {
      'name': 'steelworks',
      'button': null,
      'maximum': 1,
      'availableMsg': 'craftables.steelworks.availableMsg',
      'buildMsg': 'craftables.steelworks.buildMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 1500, 'iron': 100, 'coal': 100};
      },
      'audio': AudioLibrary.build,
    },
    'armoury': {
      'name': 'armoury',
      'button': null,
      'maximum': 1,
      'availableMsg': 'craftables.armoury.availableMsg',
      'buildMsg': 'craftables.armoury.buildMsg',
      'type': 'building',
      'cost': (StateManager sm) {
        return {'wood': 3000, 'steel': 100, 'sulphur': 50};
      },
      'audio': AudioLibrary.build,
    },
    // 工具类
    'torch': {
      'name': 'torch',
      'button': null,
      'type': 'tool',
      'buildMsg': 'craftables.torch.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 1, 'cloth': 1};
      },
      'audio': AudioLibrary.build,
    },
    // 升级类
    'waterskin': {
      'name': 'waterskin',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.waterskin.buildMsg',
      'cost': (StateManager sm) {
        return {'leather': 50};
      },
      'audio': AudioLibrary.build,
    },
    'cask': {
      'name': 'cask',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.cask.buildMsg',
      'cost': (StateManager sm) {
        return {'leather': 100, 'iron': 20};
      },
      'audio': AudioLibrary.build,
    },
    'water tank': {
      'name': 'water tank',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.water tank.buildMsg',
      'cost': (StateManager sm) {
        return {'iron': 100, 'steel': 50};
      },
      'audio': AudioLibrary.build,
    },
    'rucksack': {
      'name': 'rucksack',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.rucksack.buildMsg',
      'cost': (StateManager sm) {
        return {'leather': 200};
      },
      'audio': AudioLibrary.build,
    },
    'wagon': {
      'name': 'wagon',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.wagon.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 500, 'iron': 100};
      },
      'audio': AudioLibrary.build,
    },
    'convoy': {
      'name': 'convoy',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.convoy.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 1000, 'iron': 200, 'steel': 100};
      },
      'audio': AudioLibrary.build,
    },
    // 武器类
    'bone spear': {
      'name': 'bone spear',
      'button': null,
      'type': 'weapon',
      'buildMsg': 'craftables.bone spear.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 100, 'teeth': 5};
      },
      'audio': AudioLibrary.build,
    },
    'iron sword': {
      'name': 'iron sword',
      'button': null,
      'type': 'weapon',
      'buildMsg': 'craftables.iron sword.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 200, 'leather': 50, 'iron': 20};
      },
      'audio': AudioLibrary.build,
    },
    'steel sword': {
      'name': 'steel sword',
      'button': null,
      'type': 'weapon',
      'buildMsg': 'craftables.steel sword.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 500, 'leather': 100, 'steel': 20};
      },
      'audio': AudioLibrary.build,
    },
    'rifle': {
      'name': 'rifle',
      'button': null,
      'type': 'weapon',
      'buildMsg': 'craftables.rifle.buildMsg',
      'cost': (StateManager sm) {
        return {'wood': 200, 'steel': 50, 'sulphur': 50};
      },
      'audio': AudioLibrary.build,
    },
    // 护甲类
    'l armour': {
      'name': 'l armour',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.l armour.buildMsg',
      'cost': (StateManager sm) {
        return {'leather': 200, 'scales': 20};
      },
      'audio': AudioLibrary.build,
    },
    'i armour': {
      'name': 'i armour',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.i armour.buildMsg',
      'cost': (StateManager sm) {
        return {'leather': 200, 'iron': 100};
      },
      'audio': AudioLibrary.build,
    },
    's armour': {
      'name': 's armour',
      'button': null,
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': 'craftables.s armour.buildMsg',
      'cost': (StateManager sm) {
        return {'leather': 200, 'steel': 100};
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
    'grenade': {
      'type': 'weapon',
      'cost': (StateManager sm) {
        return {'scales': 100, 'teeth': 50};
      },
      'audio': AudioLibrary.buy,
    },
    'bayonet': {
      'type': 'weapon',
      'cost': (StateManager sm) {
        return {'scales': 500, 'teeth': 250};
      },
      'audio': AudioLibrary.buy,
    },
    'alien alloy': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 1500, 'scales': 750, 'teeth': 300};
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

    // 本地化实例通过getter自动获取

    // Set up initial state if not already set
    if (sm.get('features.location.room') == null) {
      sm.set('features.location.room', true);
      sm.set('game.builder.level', -1);
    }

    // 设置初始温度和火焰状态
    if (sm.get('game.temperature.value') == null) {
      sm.set('game.temperature.value', tempEnum['Freezing']!['value']);
    }

    if (sm.get('game.fire.value') == null) {
      sm.set('game.fire.value', fireEnum['Dead']!['value']);
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
    _tempTimer = Engine().setTimeout(() => adjustTemp(), _roomWarmDelay);

    // Check builder state
    final builderLevel = sm.get('game.builder.level');
    if (builderLevel != null && builderLevel >= 0 && builderLevel < 3) {
      _builderTimer =
          Engine().setTimeout(() => updateBuilderState(), _builderStateDelay);
    }

    // 检查是否需要解锁森林
    if (builderLevel == 1 && (sm.get('stores.wood', true) ?? 0) <= 0) {
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

    // 传递原始键给通知管理器，让它处理本地化
    NotificationManager()
        .notify(name, 'notifications.the_room_is temperature.$tempText');
    NotificationManager()
        .notify(name, 'notifications.the_fire_is fire.$fireText');

    // 启动收入系统
    Engine().setTimeout(() => sm.collectIncome(), 1000);

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

      // 传递原始键给通知管理器，让它处理本地化
      NotificationManager()
          .notify(name, 'notifications.the_room_is temperature.$tempText');
      NotificationManager()
          .notify(name, 'notifications.the_fire_is fire.$fireText');
      changed = false;
    }

    // 检查建造者升级
    checkBuilderUpgrade();

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
    // String title = fireValue < 2 ? '小黑屋' : '生火间';

    notifyListeners();
  }

  // 点燃火堆
  void lightFire() {
    final sm = StateManager();
    final wood = sm.get('stores.wood', true) ?? 0;

    // 调试信息
    Logger.info('🔥 lightFire called');
    Logger.info('🪵 Current wood: $wood');
    Logger.info('📊 Full stores state: ${sm.get('stores')}');

    // 按照原始游戏逻辑：如果没有木材，点火是免费的！
    if (wood == 0) {
      Logger.info('🆓 Free fire lighting (no wood available)');
      sm.set('game.fire.value', fireEnum['Burning']!['value']);
      AudioEngine().playSound(AudioLibrary.lightFire);
      onFireChange();
      return;
    }

    // 如果有木材但不足5个，显示错误
    if (wood < 5) {
      NotificationManager()
          .notify(name, _localization.translate('room.notEnoughWood'));
      Logger.error('❌ Not enough wood: need 5, have $wood');
      return;
    }

    // 如果有足够木材，消耗5个
    sm.set('stores.wood', wood - 5);
    sm.set('game.fire.value', fireEnum['Burning']!['value']);
    AudioEngine().playSound(AudioLibrary.lightFire);
    Logger.info('✅ Fire lit successfully! Wood remaining: ${wood - 5}');
    onFireChange();
  }

  // 添柴
  void stokeFire() {
    final sm = StateManager();
    final wood = sm.get('stores.wood', true) ?? 0;

    // 按照原始游戏逻辑：如果没有木材，显示提示并返回
    if (wood == 0) {
      /*
      NotificationManager()
          .notify(name, _localization.translate('room.woodRunOut'));
      */
      return;
    }

    // 如果有木材，消耗1个
    sm.set('stores.wood', wood - 1);

    final fireValue = sm.get('game.fire.value', true) ?? 0;
    if (fireValue < 4) {
      sm.set('game.fire.value', fireValue + 1);
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
    final fireValue = sm.get('game.fire.value', true) ?? 0;

    String fireText = '';
    for (final entry in fireEnum.entries) {
      if (entry.value['value'] == fireValue) {
        fireText = entry.value['text'] as String;
        break;
      }
    }

    // 传递原始键给通知管理器，让它处理本地化
    NotificationManager().notify(
        name, 'notifications.the_fire_is fire.$fireText',
        noQueue: true);

    if (fireValue > 1 && sm.get('game.builder.level') < 0) {
      sm.set('game.builder.level', 0);
      NotificationManager()
          .notify(name, _localization.translate('room.lightFromFire'));
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

    // 处理按钮冷却状态传递 - 参考原游戏room.js:654-662
    _handleButtonCooldownTransfer(fireValue);

    notifyListeners();
  }

  // 处理按钮冷却状态传递
  // 参考原游戏room.js:654-662的updateButton函数
  void _handleButtonCooldownTransfer(int fireValue) {
    final progressManager = ProgressManager();

    if (fireValue == fireEnum['Dead']!['value']) {
      // 火焰熄灭，从stokeButton传递冷却状态到lightButton
      progressManager.transferProgress(
        'stokeButton',
        'lightButton',
        GameConfig.stokeFireProgressDuration,
        () {}, // 空回调，因为冷却完成不需要额外操作
      );
    } else {
      // 火焰燃烧，从lightButton传递冷却状态到stokeButton
      progressManager.transferProgress(
        'lightButton',
        'stokeButton',
        GameConfig.stokeFireProgressDuration,
        () {}, // 空回调，因为冷却完成不需要额外操作
      );
    }
  }

  // 随时间冷却火焰
  void coolFire() {
    final sm = StateManager();
    final wood = sm.get('stores.wood', true) ?? 0;
    final fireValue = sm.get('game.fire.value', true) ?? 0;
    final builderLevel = sm.get('game.builder.level', true) ?? -1;

    if (fireValue <= fireEnum['Flickering']!['value'] &&
        builderLevel > 3 &&
        wood > 0) {
      NotificationManager().notify(
          name, _localization.translate('room.builderStokes'),
          noQueue: true);
      sm.set('stores.wood', wood - 1);
      sm.set('game.fire.value', fireValue + 1);
    }

    if (fireValue > 0) {
      sm.set('game.fire.value', fireValue - 1);
      _fireTimer = Engine().setTimeout(() => coolFire(), _fireCoolDelay);
      onFireChange();
    }
  }

  // 根据火焰调整房间温度
  void adjustTemp() {
    final sm = StateManager();
    final oldTempValue = sm.get('game.temperature.value', true) ?? 0;
    final fireValue = sm.get('game.fire.value', true) ?? 0;

    if (oldTempValue > 0 && oldTempValue > fireValue) {
      final newTempValue = oldTempValue - 1;
      sm.set('game.temperature.value', newTempValue);

      String tempText = '';
      for (final entry in tempEnum.entries) {
        if (entry.value['value'] == newTempValue) {
          tempText = entry.value['text'] as String;
          break;
        }
      }

      // 传递原始键给通知管理器，让它处理本地化
      NotificationManager().notify(
          name, 'notifications.the_room_is temperature.$tempText',
          noQueue: true);
    }

    if (oldTempValue < 4 && oldTempValue < fireValue) {
      final newTempValue = oldTempValue + 1;
      sm.set('game.temperature.value', newTempValue);

      String tempText = '';
      for (final entry in tempEnum.entries) {
        if (entry.value['value'] == newTempValue) {
          tempText = entry.value['text'] as String;
          break;
        }
      }

      // 传递原始键给通知管理器，让它处理本地化
      NotificationManager().notify(
          name, 'notifications.the_room_is temperature.$tempText',
          noQueue: true);
    }

    final newTempValue = sm.get('game.temperature.value', true) ?? 0;
    if (oldTempValue != newTempValue) {
      changed = true;
    }

    _tempTimer?.cancel();
    _tempTimer = Engine().setTimeout(() => adjustTemp(), _roomWarmDelay);
  }

  // 解锁森林位置
  void unlockForest() {
    final sm = StateManager();
    final builderLevel = sm.get('game.builder.level', true) ?? -1;
    final outsideUnlocked = sm.get('features.location.outside');

    // 只有在建造者状态为1且森林未解锁时才解锁
    if (builderLevel >= 1 &&
        (outsideUnlocked == null ||
            outsideUnlocked == false ||
            outsideUnlocked == 0)) {
      sm.set('stores.wood', 4);
      sm.set('features.location.outside', true); // 设置森林解锁标志
      Outside().init();
      NotificationManager()
          .notify(name, _localization.translate('room.windHowls'));
      NotificationManager()
          .notify(name, _localization.translate('room.needWood'));
      Engine().event('progress', 'outside');

      // 自动切换到Outside模块
      Engine().travelTo(Outside());
    }
  }

  // 更新建造者状态
  void updateBuilderState() {
    final sm = StateManager();
    final builderLevel = sm.get('game.builder.level', true) ?? -1;

    if (builderLevel == 0) {
      NotificationManager()
          .notify(name, _localization.translate('room.strangerArrives'));
      sm.set('game.builder.level', 1);
      // 在建造者状态为1且木材不足时解锁森林
      Engine().setTimeout(() => unlockForest(), _needWoodDelay);
    } else if (builderLevel < 3 &&
        (sm.get('game.temperature.value', true) ?? 0) >=
            tempEnum['Warm']!['value']) {
      String msg = '';

      switch (builderLevel) {
        case 1:
          msg = _localization.translate('room.strangerShivers');
          break;
        case 2:
          msg = _localization.translate('room.strangerCalms');
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

  // 检查并升级建造者到等级4（在onArrival时调用）
  void checkBuilderUpgrade() {
    final sm = StateManager();
    final builderLevel = sm.get('game.builder.level', true) ?? -1;

    // 当建造者等级为3时，升级到4并开始帮助建造
    if (builderLevel == 3) {
      sm.set('game.builder.level', 4);

      // 设置建造者收入 - 每10秒生产2木材
      sm.setIncome('builder', {
        'delay': 10,
        'stores': {'wood': 2}
      });

      NotificationManager()
          .notify(name, _localization.translate('room.builderHelps'));

      // 更新收入视图
      updateIncomeView();

      notifyListeners();
    }
  }

  // 更新商店视图
  void updateStoresView() {
    final sm = StateManager();
    final stores = sm.get('stores');

    if (stores == null) return;

    // 检查是否有指南针并且还没有发现路径
    if (sm.get('stores.compass', true) != null && !pathDiscovery) {
      pathDiscovery = true;
      // Path.openPath(); // 当Path模块实现后取消注释
    }

    // 检查盗贼
    for (final entry in stores.entries) {
      final num = entry.value;
      if (sm.get('game.thieves', true) == null &&
          num > 5000 &&
          sm.get('features.location.world', true) == true) {
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
    final numThings = sm.get('stores.$thing', true) ?? 0;

    if (good['maximum'] != null && good['maximum'] <= numThings) {
      return false;
    }

    final cost = good['cost'](sm);
    final Map<String, dynamic> storeMod = {};

    // 检查是否有足够的资源
    for (final entry in cost.entries) {
      final have = sm.get('stores.${entry.key}', true) ?? 0;
      if (have < entry.value) {
        NotificationManager().notify(name,
            '${_localization.translate('notifications.not_enough')} ${_localization.translate(entry.key)}');
        return false;
      } else {
        storeMod[entry.key] = have - entry.value;
      }
    }

    // 扣除资源
    sm.setM('stores', storeMod);

    // 添加物品
    sm.add('stores.$thing', 1);

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
    final sm = StateManager();

    // 检查温度 - 建造者在太冷时会拒绝工作
    if ((sm.get('game.temperature.value', true) ?? 0) <=
        tempEnum['Cold']!['value']) {
      NotificationManager()
          .notify(name, _localization.translate('room.builderShivers'));
      return false;
    }

    final craftable = craftables[thing];
    if (craftable == null) return false;

    final numThings = sm.get('game.buildings.$thing', true) ?? 0;

    if (craftable['maximum'] != null && craftable['maximum'] <= numThings) {
      return false;
    }

    final cost = craftable['cost'](sm);
    final Map<String, dynamic> storeMod = {};

    // 检查是否有足够的资源
    for (final entry in cost.entries) {
      final have = sm.get('stores.${entry.key}', true) ?? 0;
      if (have < entry.value) {
        NotificationManager().notify(name,
            '${_localization.translate('notifications.not_enough')} ${_localization.translate(entry.key)}');
        return false;
      } else {
        storeMod[entry.key] = have - entry.value;
      }
    }

    // 扣除资源
    sm.setM('stores', storeMod);

    // 添加建筑
    if (craftable['type'] == 'building') {
      sm.add('game.buildings.$thing', 1);
    } else {
      sm.add('stores.$thing', 1);
    }

    // 显示消息
    if (craftable['buildMsg'] != null) {
      NotificationManager().notify(name, craftable['buildMsg']);
    }

    // 播放音频
    if (craftable['audio'] != null) {
      AudioEngine().playSound(craftable['audio']);
    }

    // 通知UI更新 - 修复升级物品后需要刷新页面的问题
    notifyListeners();

    return true;
  }

  // 更新按钮状态
  void updateButton() {
    // 在Flutter版本中，按钮状态通过UI状态管理自动更新
    notifyListeners();
  }

  // 检查制作是否解锁
  bool craftUnlocked(String thing) {
    final sm = StateManager();

    final builderLevel = sm.get('game.builder.level', true);

    if (builderLevel < 4) {
      return false;
    }

    final craftable = craftables[thing];
    if (craftable == null) {
      return false;
    }

    if (needsWorkshop(craftable['type']) &&
        (sm.get('game.buildings.workshop', true) ?? 0) == 0) {
      return false;
    }

    final cost = craftable['cost'](sm);

    // 如果已经建造过，显示按钮
    if ((sm.get('game.buildings.$thing', true) ?? 0) > 0) {
      return true;
    }

    // 如果有至少一半的木材，并且所有其他组件都见过，显示按钮
    final woodHave = sm.get('stores.wood', true) ?? 0;
    final woodNeed = (cost['wood'] ?? 0) * 0.5;
    if (woodHave < woodNeed) {
      return false;
    }

    for (final entry in cost.entries) {
      // 检查是否见过这种材料（即使数量为0也算见过）
      final storeValue = sm.get('stores.${entry.key}', true);
      if (storeValue == null) {
        return false;
      }
    }

    // 注意：不在这里显示可用消息，因为这个函数在UI构建过程中被调用
    // 可用消息应该在实际解锁时显示，而不是在检查解锁状态时显示

    return true;
  }

  // 检查购买是否解锁
  bool buyUnlocked(String thing) {
    final sm = StateManager();
    final hasTradingPost =
        (sm.get('game.buildings["trading post"]', true) ?? 0) > 0;

    if (hasTradingPost) {
      // 指南针特殊处理：即使没有见过也可以购买（原游戏逻辑）
      if (thing == 'compass') {
        return true;
      }

      // 其他物品：一旦见过就允许购买（包括数量为0的情况）
      final hasSeenItem = sm.get('stores["$thing"]', true) != null;

      if (hasSeenItem) {
        return true;
      }
    }

    return false;
  }

  // 检查是否需要工坊
  bool needsWorkshop(String type) {
    return type == 'weapon' || type == 'upgrade' || type == 'tool';
  }

  // 更新建造按钮
  void updateBuildButtons() {
    // 在Flutter版本中，建造按钮通过UI状态管理自动更新
    // 这个方法保留作为接口兼容性
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

  // 获取可用的制作物品列表
  List<String> getAvailableCraftables() {
    final List<String> available = [];

    for (final entry in craftables.entries) {
      if (craftUnlocked(entry.key)) {
        available.add(entry.key);
      }
    }

    return available;
  }

  // 获取可用的交易物品列表
  List<String> getAvailableTradeGoods() {
    final List<String> available = [];

    for (final entry in tradeGoods.entries) {
      if (buyUnlocked(entry.key)) {
        available.add(entry.key);
      }
    }

    return available;
  }

  // 获取物品的本地化名称
  String getLocalizedName(String itemName) {
    final localization = Localization();

    // 直接使用新的翻译逻辑，它会自动尝试所有类别
    String translatedName = localization.translate(itemName);

    // 如果翻译成功（不等于原名称），返回翻译
    if (translatedName != itemName) {
      return translatedName;
    }

    // 如果都没有找到，返回原名称
    return itemName;
  }

  // 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    final sm = StateManager();

    // 检查建造者状态
    final builderLevel = sm.get('game.builder.level', true) ?? -1;
    if (builderLevel >= 0 && builderLevel < 3) {
      updateBuilderState();
    }

    // 检查火焰状态
    final fireValue = sm.get('game.fire.value', true) ?? 0;
    if (fireValue > 0) {
      onFireChange();
    }

    // 更新商店和收入视图
    updateStoresView();
    updateIncomeView();

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

  // 建造功能
  void buildItem(String thing) {
    final sm = StateManager();

    // 检查温度是否足够
    if (sm.get('game.temperature.value') <= tempEnum['Cold']!['value']) {
      NotificationManager()
          .notify(name, _localization.translate('room.builderShivers'));
      return;
    }

    final craftable = craftables[thing];
    if (craftable == null) return;

    // 获取当前数量
    int numThings = 0;
    switch (craftable['type']) {
      case 'good':
      case 'weapon':
      case 'tool':
      case 'upgrade':
        numThings = sm.get('stores["$thing"]', true) ?? 0;
        break;
      case 'building':
        numThings = sm.get('game.buildings["$thing"]', true) ?? 0;
        break;
    }

    if (numThings < 0) numThings = 0;

    // 检查是否达到最大数量
    final maximum = craftable['maximum'] ?? 999999;
    if (maximum <= numThings) {
      if (craftable['maxMsg'] != null) {
        NotificationManager().notify(name, craftable['maxMsg']);
      }
      return;
    }

    // 计算成本
    final costFunction = craftable['cost'] as Function(StateManager);
    final costResult = costFunction(sm);
    final cost = <String, int>{};
    if (costResult is Map<String, dynamic>) {
      for (final entry in costResult.entries) {
        cost[entry.key] = (entry.value as num).toInt();
      }
    }

    // 检查资源是否足够
    Map<String, int> storeMod = {};
    for (var k in cost.keys) {
      final have = sm.get('stores["$k"]', true) ?? 0;
      if (have < cost[k]!) {
        NotificationManager().notify(name,
            '${_localization.translate('notifications.not_enough')} ${_localization.translate(k)}');
        return;
      } else {
        storeMod[k] = have - cost[k]!;
      }
    }

    // 扣除资源
    for (var k in storeMod.keys) {
      sm.set('stores["$k"]', storeMod[k]);
    }

    // 显示建造消息
    if (craftable['buildMsg'] != null) {
      NotificationManager().notify(name, craftable['buildMsg']);
    }

    // 增加物品数量
    switch (craftable['type']) {
      case 'good':
      case 'weapon':
      case 'upgrade':
      case 'tool':
        sm.add('stores["$thing"]', 1);
        break;
      case 'building':
        sm.add('game.buildings["$thing"]', 1);
        break;
    }

    // 播放音效
    switch (craftable['type']) {
      case 'weapon':
      case 'upgrade':
      case 'tool':
        AudioEngine().playSound(AudioLibrary.craft);
        break;
      case 'building':
        AudioEngine().playSound(AudioLibrary.build);
        break;
    }

    notifyListeners();
  }

  // 购买功能
  void buyItem(String thing) {
    final sm = StateManager();

    final good = tradeGoods[thing];
    if (good == null) {
      return;
    }

    final numThings = sm.get('stores["$thing"]', true) ?? 0;
    final maximum = good['maximum'] ?? 999999;

    if (maximum <= numThings) {
      return;
    }

    // 计算成本
    final costFunction = good['cost'] as Function(StateManager);
    final costResult = costFunction(sm);
    final cost = <String, int>{};
    if (costResult is Map<String, dynamic>) {
      for (final entry in costResult.entries) {
        cost[entry.key] = (entry.value as num).toInt();
      }
    }

    // 检查资源是否足够
    Map<String, num> storeMod = {};
    for (var k in cost.keys) {
      final have = sm.get('stores["$k"]', true) ?? 0;
      if (have < cost[k]!) {
        NotificationManager().notify(name,
            '${_localization.translate('notifications.not_enough')} ${_localization.translate(k)}');
        return;
      } else {
        storeMod[k] = have - cost[k]!;
      }
    }

    // 扣除资源
    for (var k in storeMod.keys) {
      sm.set('stores["$k"]', storeMod[k]);
    }

    // 显示购买消息
    if (good['buildMsg'] != null) {
      NotificationManager().notify(name, good['buildMsg']);
    }

    // 增加物品数量
    sm.add('stores["$thing"]', 1);

    // 播放音效
    AudioEngine().playSound(AudioLibrary.buy);

    notifyListeners();
  }
}

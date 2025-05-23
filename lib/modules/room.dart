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
  static const int _roomWarmDelay = 30 * 1000; // 房间温度更新延迟
  static const int _builderStateDelay = 30 * 1000; // 建造者状态更新延迟
  static const int _stokeCooldown = 10; // 添柴冷却时间
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
  Timer? _tempTimer;
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
      'audio': AudioLibrary.BUILD_TRAP,
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
      'audio': AudioLibrary.BUILD_CART,
    },
    // Additional craftables would be defined here
  };

  // 交易物品
  final Map<String, Map<String, dynamic>> tradeGoods = {
    'scales': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 150};
      },
      'audio': AudioLibrary.BUY_SCALES,
    },
    'teeth': {
      'type': 'good',
      'cost': (StateManager sm) {
        return {'fur': 300};
      },
      'audio': AudioLibrary.BUY_TEETH,
    },
    // Additional trade goods would be defined here
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

    // Set up path discovery
    pathDiscovery = sm.get('stores.compass', true) != null &&
        sm.get('stores.compass', true) > 0;

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

  // Called when arriving at this module
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

  // Set the title based on fire state
  void setTitle() {
    final sm = StateManager();
    final fireValue = sm.get('game.fire.value');

    final title = fireValue < 2 ? 'A Dark Room' : 'A Firelit Room';

    // In the original game, this would set the document title
    // For Flutter, we'll just update the UI
    notifyListeners();
  }

  // Light the fire
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
    AudioEngine().playSound(AudioLibrary.LIGHT_FIRE);
    onFireChange();
  }

  // Stoke the fire
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

    AudioEngine().playSound(AudioLibrary.STOKE_FIRE);
    onFireChange();
  }

  // Handle fire state changes
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

  // Cool the fire over time
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

  // Adjust room temperature based on fire
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

    _tempTimer = Engine().setTimeout(() => adjustTemp(), _roomWarmDelay);
  }

  // Unlock the forest location
  void unlockForest() {
    final sm = StateManager();
    sm.set('stores.wood', 4);
    Outside().init();
    NotificationManager().notify(name, 'the wind howls outside');
    NotificationManager().notify(name, 'the wood is running out');
    Engine().event('progress', 'outside');
  }

  // Update the builder state
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

  // Set music based on fire level
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
}

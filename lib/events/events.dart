import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/audio_engine.dart';

/// 事件系统 - 处理随机事件和战斗
class Events extends ChangeNotifier {
  static final Events _instance = Events._internal();

  factory Events() {
    return _instance;
  }

  Events._internal();

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

  // 状态
  List<Map<String, dynamic>> eventPool = [];
  List<Map<String, dynamic>> eventStack = [];
  String delayState = 'wait';
  String? activeScene;
  Map<String, dynamic>? _activeEvent;
  bool fought = false;
  bool won = false;
  bool paused = false;
  Timer? _nextEventTimer;
  Timer? _enemyAttackTimer;
  List<Timer> _specialTimers = [];

  /// 初始化事件系统
  void init() {
    // 构建事件池
    eventPool = [
      // 这里将添加各种事件
      // ...globalEvents,
      // ...roomEvents,
      // ...outsideEvents,
      // ...marketingEvents,
    ];

    eventStack = [];
    scheduleNextEvent();
    initDelay();
  }

  /// 安排下一个事件
  void scheduleNextEvent() {
    if (_nextEventTimer != null) {
      _nextEventTimer!.cancel();
    }

    final random = Random();
    final minutes = eventTimeRange[0] +
        random.nextInt(eventTimeRange[1] - eventTimeRange[0] + 1);

    _nextEventTimer = Timer(Duration(minutes: minutes), () {
      triggerRandomEvent();
    });
  }

  /// 触发随机事件
  void triggerRandomEvent() {
    if (eventPool.isEmpty) return;

    final random = Random();
    final event = eventPool[random.nextInt(eventPool.length)];

    // 检查事件是否可用
    if (isEventAvailable(event)) {
      startEvent(event);
    } else {
      scheduleNextEvent();
    }
  }

  /// 检查事件是否可用
  bool isEventAvailable(Map<String, dynamic> event) {
    // 检查事件的可用性条件
    if (event['isAvailable'] != null) {
      return event['isAvailable']();
    }
    return true;
  }

  /// 开始事件
  void startEvent(Map<String, dynamic> event) {
    _activeEvent = event;
    activeScene = 'start';

    // 播放事件音频
    if (event['audio'] != null) {
      AudioEngine().playSound(event['audio']);
    }

    loadScene('start');
    notifyListeners();
  }

  /// 加载场景
  void loadScene(String name) {
    // Engine().log('loading scene: $name'); // 暂时注释掉，直到Engine类有log方法
    activeScene = name;

    if (_activeEvent == null) return;

    final scene = _activeEvent!['scenes'][name];
    if (scene == null) return;

    // onLoad 回调
    if (scene['onLoad'] != null) {
      scene['onLoad']();
    }

    // 通知
    if (scene['notification'] != null) {
      NotificationManager().notify('events', scene['notification']);
    }

    // 奖励
    if (scene['reward'] != null) {
      // final sm = StateManager();
      // sm.addM('stores', scene['reward']); // 暂时注释掉，直到StateManager有addM方法
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
    // Engine().event('game event', 'combat'); // 暂时注释掉
    fought = false;
    won = false;

    // 设置敌人攻击计时器
    startEnemyAttacks(scene['attackDelay'] ?? 2);

    // 设置特殊技能计时器
    if (scene['specials'] != null) {
      _specialTimers = (scene['specials'] as List).map((s) {
        return Timer.periodic(Duration(milliseconds: (s['delay'] * 1000).round()), (timer) {
          final text = s['action']();
          if (text != null) {
            // 显示浮动文本
          }
        });
      }).toList();
    }

    notifyListeners();
  }

  /// 开始故事模式
  void startStory(Map<String, dynamic> scene) {
    // 处理故事场景
    notifyListeners();
  }

  /// 开始敌人攻击
  void startEnemyAttacks([double? delay]) {
    _enemyAttackTimer?.cancel();

    if (_activeEvent == null || activeScene == null) return;

    final scene = _activeEvent!['scenes'][activeScene];
    final attackDelay = delay ?? scene['attackDelay'] ?? 2.0;

    _enemyAttackTimer = Timer.periodic(Duration(milliseconds: (attackDelay * 1000).round()), (timer) {
      enemyAttack();
    });
  }

  /// 敌人攻击
  void enemyAttack() {
    if (_activeEvent == null || activeScene == null) return;

    final scene = _activeEvent!['scenes'][activeScene];
    if (scene == null) return;

    // 实现敌人攻击逻辑
    // 这里需要根据具体的战斗系统来实现

    notifyListeners();
  }

  /// 使用武器
  void useWeapon(String weaponName) {
    // 实现武器使用逻辑
    notifyListeners();
  }

  /// 吃肉回血
  void eatMeat() {
    // 实现吃肉回血逻辑
    AudioEngine().playSound('eat_meat');
    notifyListeners();
  }

  /// 使用药品
  void useMeds() {
    // 实现使用药品逻辑
    AudioEngine().playSound('use_meds');
    notifyListeners();
  }

  /// 使用兴奋剂
  void useHypo() {
    // 实现使用兴奋剂逻辑
    AudioEngine().playSound('use_meds');
    notifyListeners();
  }

  /// 使用护盾
  void useShield() {
    // 实现使用护盾逻辑
    notifyListeners();
  }

  /// 使用刺激剂
  void useStim() {
    // 实现使用刺激剂逻辑
    notifyListeners();
  }

  /// 设置状态
  void setStatus(String fighter, String status) {
    // 实现状态设置逻辑
    notifyListeners();
  }

  /// 绘制浮动文本
  void drawFloatText(String text, String target) {
    // 在Flutter中，这可能需要通过动画来实现
    notifyListeners();
  }

  /// 初始化延迟事件
  void initDelay() {
    final sm = StateManager();
    final waitState = sm.get('wait');

    if (waitState != null) {
      // 处理延迟事件
    }
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    notifyListeners();
  }

  /// 获取当前活动事件
  Map<String, dynamic>? activeEvent() {
    return _activeEvent;
  }

  /// 结束事件
  void endEvent() {
    _activeEvent = null;
    activeScene = null;
    _enemyAttackTimer?.cancel();

    for (final timer in _specialTimers) {
      timer.cancel();
    }
    _specialTimers.clear();

    scheduleNextEvent();
    notifyListeners();
  }

  @override
  void dispose() {
    _nextEventTimer?.cancel();
    _enemyAttackTimer?.cancel();
    for (final timer in _specialTimers) {
      timer.cancel();
    }
    super.dispose();
  }
}

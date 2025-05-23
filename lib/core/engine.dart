import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state_manager.dart';
import 'audio_engine.dart';
import 'audio_library.dart';
import 'notifications.dart';
import 'localization.dart';
import '../modules/room.dart';
import '../modules/outside.dart';
import '../modules/path.dart';
import '../modules/fabricator.dart';
import '../modules/ship.dart';
import '../events/events.dart';

/// Engine是游戏的核心引擎，负责协调所有游戏系统
class Engine with ChangeNotifier {
  static final Engine _instance = Engine._internal();

  factory Engine() {
    return _instance;
  }

  Engine._internal();

  // 常量
  static const String SITE_URL = "http://adarkroom.doublespeakgames.com";
  static const double VERSION = 1.3;
  static const int MAX_STORE = 99999999999999;
  static const int SAVE_DISPLAY = 30 * 1000;

  // 游戏状态
  bool gameOver = false;
  bool keyPressed = false;
  bool keyLock = false;
  bool tabNavigation = true;
  bool restoreNavigation = false;

  // 技能
  Map<String, Map<String, String>> perks = {
    'boxer': {'name': '拳击手', 'desc': '拳头造成更多伤害', 'notify': '学会了有目的地出拳'},
    'martial artist': {
      'name': '武术家',
      'desc': '拳头造成更多伤害',
      'notify': '学会了在没有武器的情况下有效战斗'
    },
    'unarmed master': {
      'name': '徒手大师',
      'desc': '出拳速度加倍，力量更大',
      'notify': '学会了在没有武器的情况下更快地攻击'
    },
    'barbarian': {'name': '野蛮人', 'desc': '近战武器造成更多伤害', 'notify': '学会了用力挥舞武器'},
    'slow metabolism': {
      'name': '缓慢新陈代谢',
      'desc': '不吃东西可以走两倍远',
      'notify': '学会了如何忽略饥饿'
    },
    'desert rat': {'name': '沙漠鼠', 'desc': '不喝水可以走两倍远', 'notify': '学会了喜欢干燥的空气'},
    'evasive': {'name': '闪避', 'desc': '更有效地躲避攻击', 'notify': '学会了出现在敌人打不到的地方'},
    'precise': {'name': '精确', 'desc': '更频繁地命中', 'notify': '学会了预测敌人的移动'},
    'scout': {'name': '侦察兵', 'desc': '看得更远', 'notify': '学会了向前看'},
    'stealthy': {'name': '隐秘', 'desc': '在野外更好地避免冲突', 'notify': '学会了如何不被看见'},
    'gastronome': {'name': '美食家', 'desc': '吃东西时恢复更多健康', 'notify': '学会了充分利用食物'}
  };

  // 选项
  Map<String, dynamic> options = {
    'debug': false,
    'log': false,
    'dropbox': false,
    'doubleTime': false,
  };

  // 活动模块
  dynamic activeModule;

  // 保存计时器
  Timer? _saveTimer;
  DateTime? _lastNotify;

  // 初始化引擎
  Future<void> init({Map<String, dynamic>? options}) async {
    this.options = {...this.options, ...?options};

    // 初始化状态管理器
    final sm = StateManager();
    sm.init();

    // 初始化音频引擎
    await AudioEngine().init();

    // 初始化通知
    NotificationManager().init();

    // 初始化本地化
    await Localization().init();

    // 加载保存的游戏
    await loadGame();

    // 初始化模块
    await Room().init();

    // 检查是否应该初始化外部
    if (sm.get('stores.wood') != null) {
      await Outside().init();
    }

    // 检查是否应该初始化路径
    if (sm.get('stores.compass', true) != null &&
        sm.get('stores.compass', true) > 0) {
      await Path().init();
    }

    // 检查是否应该初始化制造机
    if (sm.get('features.location.fabricator', true) == true) {
      await Fabricator().init();
    }

    // 检查是否应该初始化飞船
    if (sm.get('features.location.spaceShip', true) == true) {
      await Ship().init();
    }

    // 设置保存计时器
    _saveTimer = Timer.periodic(const Duration(minutes: 1), (_) => saveGame());

    // 设置初始模块
    travelTo(Room());

    // 根据保存的设置设置音频
    toggleVolume(sm.get('config.soundOn', true) == true);

    // 开始收集收入
    Timer.periodic(const Duration(seconds: 1), (_) => sm.collectIncome());

    notifyListeners();
  }

  // 保存游戏
  Future<void> saveGame() async {
    await StateManager().saveGame();

    if (_lastNotify == null ||
        DateTime.now().difference(_lastNotify!).inMilliseconds > SAVE_DISPLAY) {
      // 显示保存通知
      _lastNotify = DateTime.now();
      // 在原始游戏中，这会显示"已保存"消息的动画
    }
  }

  // 加载游戏
  Future<void> loadGame() async {
    try {
      await StateManager().loadGame();
      if (kDebugMode) {
        print('游戏加载成功');
      }
    } catch (e) {
      if (kDebugMode) {
        print('加载游戏时出错: $e');
      }

      // 初始化新游戏状态
      final sm = StateManager();
      sm.set('version', VERSION);

      // 记录新游戏事件
      event('progress', 'new game');
    }
  }

  // 删除保存并重新开始
  Future<void> deleteSave({bool noReload = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!noReload) {
        // 在Web上下文中，这会重新加载页面
        // 在Flutter中，我们将重新初始化游戏
        await init();
      }
    } catch (e) {
      if (kDebugMode) {
        print('删除保存时出错: $e');
      }
    }
  }

  // 前往不同的模块
  void travelTo(dynamic module) {
    if (activeModule == module) {
      return;
    }

    // 更新活动模块
    activeModule = module;

    // 调用新模块的onArrival
    module.onArrival(1);

    // 打印模块的通知
    NotificationManager().printQueue(module.name);

    notifyListeners();
  }

  // 切换游戏音量
  Future<void> toggleVolume([bool? enabled]) async {
    final sm = StateManager();

    enabled ??= !(sm.get('config.soundOn', true) == true);

    sm.set('config.soundOn', enabled);

    if (enabled) {
      await AudioEngine().setMasterVolume(1.0);
    } else {
      await AudioEngine().setMasterVolume(0.0);
    }

    notifyListeners();
  }

  // 切换关灯模式
  void turnLightsOff() {
    final sm = StateManager();
    final lightsOff = sm.get('config.lightsOff', true) == true;

    sm.set('config.lightsOff', !lightsOff);

    notifyListeners();
  }

  // 切换超级模式（双倍速度）
  void triggerHyperMode() {
    options['doubleTime'] = !options['doubleTime'];

    StateManager().set('config.hyperMode', options['doubleTime']);

    notifyListeners();
  }

  // 记录事件
  void event(String category, String action) {
    // 在原始游戏中，这会发送分析
    // 现在，我们只在调试模式下记录
    if (kDebugMode) {
      print('事件: $category - $action');
    }
  }

  // 获取收入消息
  String getIncomeMsg(num value, int delay) {
    final prefix = value > 0 ? "+" : "";
    return "$prefix$value 每 ${delay}秒";
  }

  // 设置间隔，支持双倍时间
  Timer setInterval(Function callback, int interval,
      {bool skipDouble = false}) {
    if (options['doubleTime'] == true && !skipDouble) {
      interval = (interval / 2).round();
    }

    return Timer.periodic(Duration(milliseconds: interval), (_) => callback());
  }

  // 设置超时，支持双倍时间
  Timer setTimeout(Function callback, int timeout, {bool skipDouble = false}) {
    if (options['doubleTime'] == true && !skipDouble) {
      timeout = (timeout / 2).round();
    }

    return Timer(Duration(milliseconds: timeout), () => callback());
  }

  // 处理按键按下事件
  void keyDown(KeyEvent event) {
    if (!keyPressed && !keyLock) {
      keyPressed = true;

      if (activeModule != null && activeModule.keyDown != null) {
        activeModule.keyDown(event);
      }
    }
  }

  // 处理按键释放事件
  void keyUp(KeyEvent event) {
    keyPressed = false;

    if (activeModule != null && activeModule.keyUp != null) {
      activeModule.keyUp(event);
    } else {
      // 处理导航键
      // 这将根据键码实现
    }

    if (restoreNavigation) {
      tabNavigation = true;
      restoreNavigation = false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    AudioEngine().dispose();
    super.dispose();
  }
}

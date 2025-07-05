import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import 'ship.dart';
import 'score.dart';
import 'prestige.dart';

/// 太空模块 - 注册太空探索功能
/// 包括飞船控制、小行星躲避、星空动画等功能
class Space extends ChangeNotifier {
  static final Space _instance = Space._internal();

  factory Space() {
    return _instance;
  }

  static Space get instance => _instance;

  Space._internal();

  // 模块名称
  String get name {
    final localization = Localization();
    return localization.translate('space.module_name');
  }

  // 常量
  static const double shipSpeed = 3.0;
  static const int baseAsteroidDelay = 500;
  static const int baseAsteroidSpeed = 1500;
  static const int ftbSpeed = 60000;
  static const int starWidth = 3000;
  static const int starHeight = 3000;
  static const int numStars = 200;
  static const int starSpeed = 60000;
  static const int frameDelay = 100;

  // 状态变量
  Map<String, dynamic> options = {};
  bool done = false;
  double shipX = 350.0;
  double shipY = 350.0;
  int hull = 0;
  int altitude = 0;
  DateTime? lastMove;

  // 控制状态
  bool up = false;
  bool down = false;
  bool left = false;
  bool right = false;

  // 定时器
  Timer? shipTimer;
  Timer? volumeTimer;
  Timer? altitudeTimer;
  Timer? asteroidTimer;
  Timer? panelTimer;

  // 性能优化相关
  DateTime? _lastNotifyTime;
  bool _needsNotify = false;
  static const int _notifyThrottleMs =
      kIsWeb ? 16 : 33; // Web: 60FPS, Mobile: 30FPS

  // 小行星列表
  List<Map<String, dynamic>> asteroids = [];

  /// 节流通知监听器，避免过度重绘
  void _throttledNotifyListeners() {
    final now = DateTime.now();
    if (_lastNotifyTime == null ||
        now.difference(_lastNotifyTime!).inMilliseconds >= _notifyThrottleMs) {
      _lastNotifyTime = now;
      _needsNotify = false;
      notifyListeners();
    } else {
      _needsNotify = true;
      // 延迟通知，确保最终状态被更新
      Timer(Duration(milliseconds: _notifyThrottleMs), () {
        if (_needsNotify) {
          _lastNotifyTime = DateTime.now();
          _needsNotify = false;
          notifyListeners();
        }
      });
    }
  }

  /// 初始化太空模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    _throttledNotifyListeners();
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    done = false;
    hull = Ship().getMaxHull();
    altitude = 0;
    setTitle();
    updateHull();

    // 重置控制状态
    up = down = left = right = false;

    // 重置飞船位置
    shipX = 350.0;
    shipY = 350.0;

    // 清空小行星列表，确保每次起飞都从干净状态开始
    asteroids.clear();
    Logger.info('🚀 起飞时清空小行星列表，开始新的飞行');

    startAscent();

    // 启动定时器 - 根据平台调整频率
    final shipUpdateInterval = kIsWeb ? 33 : 50; // Web: 30FPS, Mobile: 20FPS
    shipTimer = Timer.periodic(
        Duration(milliseconds: shipUpdateInterval), (_) => moveShip());
    volumeTimer = Timer.periodic(Duration(seconds: 1), (_) => lowerVolume());

    // 播放背景音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicSpace);

    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // String title;
    // if (altitude < 10) {
    //   title = "对流层";
    // } else if (altitude < 20) {
    //   title = "平流层";
    // } else if (altitude < 30) {
    //   title = "中间层";
    // } else if (altitude < 45) {
    //   title = "热层";
    // } else if (altitude < 60) {
    //   title = "外逸层";
    // } else {
    //   title = "太空";
    // }
    // 在Flutter中，标题设置将通过状态管理处理
    // 标题变化不需要立即重绘，使用节流通知
    _throttledNotifyListeners();
  }

  /// 获取飞船速度
  double getSpeed() {
    final sm = StateManager();
    final thrusters = (sm.get('game.spaceShip.thrusters', true) ?? 1) as int;
    return shipSpeed + thrusters;
  }

  /// 更新船体显示
  void updateHull() {
    // 船体更新是重要状态变化，立即通知
    notifyListeners();
  }

  /// 创建小行星
  void createAsteroid([bool noNext = false]) {
    if (done) return;

    final random = Random();
    String character;
    final r = random.nextDouble();

    if (r < 0.2) {
      character = '#';
    } else if (r < 0.4) {
      character = '\$';
    } else if (r < 0.6) {
      character = '%';
    } else if (r < 0.8) {
      character = '&';
    } else {
      character = 'H';
    }

    final x = random.nextDouble() * 700;
    final asteroid = {
      'character': character,
      'x': x,
      'y': 0.0,
      'width': 20.0,
      'height': 20.0,
      'speed': baseAsteroidSpeed -
          random.nextInt((baseAsteroidSpeed * 0.65).round()),
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    asteroids.add(asteroid);

    // 开始小行星动画
    _animateAsteroid(asteroid);

    if (!noNext) {
      // 根据高度增加难度
      if (altitude > 10) {
        createAsteroid(true);
      }
      if (altitude > 20) {
        createAsteroid(true);
        createAsteroid(true);
      }
      if (altitude > 40) {
        createAsteroid(true);
        createAsteroid(true);
      }

      if (!done) {
        final delay = 1000 - (altitude * 10);
        Timer(Duration(milliseconds: delay.clamp(100, 1000)),
            () => createAsteroid());
      }
    }

    notifyListeners();
  }

  /// 小行星动画
  void _animateAsteroid(Map<String, dynamic> asteroid) {
    // 根据平台调整动画频率
    final animationInterval = kIsWeb ? 16 : 33; // Web: 60FPS, Mobile: 30FPS
    Timer.periodic(Duration(milliseconds: animationInterval), (timer) {
      if (done) {
        timer.cancel();
        return;
      }

      asteroid['y'] += 2.0; // 向下移动

      // 碰撞检测
      if (_checkCollision(asteroid)) {
        timer.cancel();
        asteroids.remove(asteroid);
        hull--;
        updateHull();

        // 播放撞击音效（暂时注释掉）
        // final r = Random().nextInt(2);
        // if (altitude > 40) {
        //   AudioEngine().playSound('asteroid_hit_${r + 6}');
        // } else if (altitude > 20) {
        //   AudioEngine().playSound('asteroid_hit_${r + 4}');
        // } else {
        //   AudioEngine().playSound('asteroid_hit_${r + 1}');
        // }

        if (hull <= 0) {
          crash();
        }
        return;
      }

      // 移除超出屏幕的小行星
      if (asteroid['y'] > 740) {
        timer.cancel();
        asteroids.remove(asteroid);
        return;
      }

      // 使用节流通知，减少重绘频率
      _throttledNotifyListeners();
    });
  }

  /// 碰撞检测
  bool _checkCollision(Map<String, dynamic> asteroid) {
    final aX = asteroid['x'] as double;
    final aY = asteroid['y'] as double;
    final aWidth = asteroid['width'] as double;
    final aHeight = asteroid['height'] as double;

    return (aX <= shipX && aX + aWidth >= shipX) &&
        (aY <= shipY && aY + aHeight >= shipY);
  }

  /// 移动飞船
  void moveShip() {
    if (done) return;

    double dx = 0, dy = 0;
    bool hasMovement = false;

    if (up) {
      dy -= getSpeed();
      hasMovement = true;
    } else if (down) {
      dy += getSpeed();
      hasMovement = true;
    }
    if (left) {
      dx -= getSpeed();
      hasMovement = true;
    } else if (right) {
      dx += getSpeed();
      hasMovement = true;
    }

    // 只有在有移动时才进行计算和更新
    if (!hasMovement) return;

    // 对角线移动时调整速度
    if (dx != 0 && dy != 0) {
      dx = dx / sqrt(2);
      dy = dy / sqrt(2);
    }

    // 时间补偿
    if (lastMove != null) {
      final dt = DateTime.now().difference(lastMove!).inMilliseconds;
      final expectedInterval = kIsWeb ? 33 : 50;
      dx *= dt / expectedInterval;
      dy *= dt / expectedInterval;
    }

    final oldX = shipX;
    final oldY = shipY;
    shipX = (shipX + dx).clamp(10.0, 690.0);
    shipY = (shipY + dy).clamp(10.0, 690.0);

    // 只有位置真正改变时才记录日志和通知
    if (shipX != oldX || shipY != oldY) {
      if (kDebugMode) {
        Logger.info(
            '🚀 飞船位置更新: ($oldX, $oldY) -> ($shipX, $shipY), dx=$dx, dy=$dy');
      }
      lastMove = DateTime.now();
      _throttledNotifyListeners();
    }
  }

  /// 开始上升
  void startAscent() {
    // 绘制星空（在Flutter中将通过UI组件处理）
    drawStars();

    // 高度计时器
    altitudeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (done) {
        timer.cancel();
        return;
      }

      altitude += 1;
      if (altitude % 10 == 0) {
        setTitle();
      }
      if (altitude >= 60) {
        timer.cancel();
        // 达到太空，游戏胜利
        endGame();
      }
    });

    // 延迟面板颜色变化
    panelTimer = Timer(Duration(milliseconds: ftbSpeed ~/ 2), () {
      // 在Flutter中，颜色变化将通过主题处理
    });

    createAsteroid();
  }

  /// 绘制星空
  void drawStars() {
    // 在Flutter中，星空将通过自定义绘制组件实现
    // 星空绘制不需要频繁更新，使用节流通知
    _throttledNotifyListeners();
  }

  /// 坠毁
  void crash() {
    if (done) return;

    done = true;
    _clearTimers();

    final localization = Localization();
    NotificationManager().notify(
        name, localization.translate('space.notifications.ship_crashed'));

    // 播放坠毁音效（暂时注释掉）
    // AudioEngine().playSound(AudioLibrary.crash);

    // 清空小行星列表，避免下次起飞时残留
    final asteroidCount = asteroids.length;
    asteroids.clear();
    Logger.info('🚀 坠毁时已清空 $asteroidCount 个小行星');

    Logger.info('🚀 飞船坠毁，返回破旧星舰页签');

    // 参考原游戏逻辑：失败时返回破旧星舰页签
    // Engine.activeModule = Ship; Ship.onArrival();
    Timer(Duration(milliseconds: 1000), () {
      final sm = StateManager();
      sm.set('game.switchToShip', true);
      Logger.info('🚀 已设置切换到破旧星舰页签的标志');
    });

    notifyListeners();
  }

  /// 游戏结束 - 胜利
  void endGame() {
    if (done) return;

    done = true;
    _clearTimers();

    final localization = Localization();
    NotificationManager().notify(
        name, localization.translate('space.notifications.escaped_planet'));

    // 播放结束音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicEnding);

    // 标记游戏完成
    final sm = StateManager();
    sm.set('game.completed', true);
    sm.set('game.won', true);

    // 保存分数和声望数据
    _saveGameScore();

    // 显示胜利动画和结束选项
    Timer(Duration(seconds: 2), () {
      showEndingOptions(true);
    });

    notifyListeners();
  }

  /// 保存游戏分数
  void _saveGameScore() {
    final sm = StateManager();
    final score = Score();
    final prestige = Prestige();

    // 计算并保存当前游戏分数
    final currentScore = score.totalScore();
    sm.set('game.currentScore', currentScore);

    // 保存到声望系统
    prestige.save();

    Logger.info('🏆 游戏分数已保存: $currentScore');
  }

  /// 显示结束选项
  void showEndingOptions(bool isVictory) {
    final sm = StateManager();
    sm.set('game.showEndingDialog', true);
    sm.set('game.endingIsVictory', isVictory);

    final localization = Localization();
    final message = isVictory
        ? localization.translate('space.notifications.game_completed')
        : localization.translate('space.notifications.ship_crashed');

    NotificationManager().notify(name, message);
    notifyListeners();
  }

  /// 清除所有定时器
  void _clearTimers() {
    shipTimer?.cancel();
    volumeTimer?.cancel();
    altitudeTimer?.cancel();
    asteroidTimer?.cancel();
    panelTimer?.cancel();
  }

  /// 按键按下处理
  void keyDown(LogicalKeyboardKey key) {
    if (kDebugMode) {
      Logger.info('🚀 Space.keyDown() 被调用: $key, done=$done');
    }

    bool stateChanged = false;
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        if (!up) {
          up = true;
          stateChanged = true;
          if (kDebugMode) Logger.info('🚀 设置 up = true');
        }
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        if (!down) {
          down = true;
          stateChanged = true;
          if (kDebugMode) Logger.info('🚀 设置 down = true');
        }
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        if (!left) {
          left = true;
          stateChanged = true;
          if (kDebugMode) Logger.info('🚀 设置 left = true');
        }
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        if (!right) {
          right = true;
          stateChanged = true;
          if (kDebugMode) Logger.info('🚀 设置 right = true');
        }
        break;
    }
    // 只有状态真正改变时才通知
    if (stateChanged) {
      _throttledNotifyListeners();
    }
  }

  /// 按键释放处理
  void keyUp(LogicalKeyboardKey key) {
    bool stateChanged = false;
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        if (up) {
          up = false;
          stateChanged = true;
        }
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        if (down) {
          down = false;
          stateChanged = true;
        }
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        if (left) {
          left = false;
          stateChanged = true;
        }
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        if (right) {
          right = false;
          stateChanged = true;
        }
        break;
    }
    // 只有状态真正改变时才通知
    if (stateChanged) {
      _throttledNotifyListeners();
    }
  }

  /// 降低音量
  void lowerVolume() {
    if (done) return;

    // 随着飞船进入太空降低音量
    // final progress = altitude / 60.0;
    // final newVolume = 1.0 - progress;

    // AudioEngine().setBackgroundMusicVolume(newVolume, 0.3); // 暂时注释掉
  }

  /// 获取太空状态
  Map<String, dynamic> getSpaceStatus() {
    return {
      'altitude': altitude,
      'hull': hull,
      'maxHull': Ship().getMaxHull(),
      'shipX': shipX,
      'shipY': shipY,
      'asteroids': asteroids,
      'done': done,
      'up': up,
      'down': down,
      'left': left,
      'right': right,
      'speed': getSpeed(),
    };
  }

  /// 获取当前大气层名称
  String getAtmosphereLayer() {
    final localization = Localization();
    if (altitude < 10) {
      return localization.translate('space.atmosphere_layers.troposphere');
    } else if (altitude < 20) {
      return localization.translate('space.atmosphere_layers.stratosphere');
    } else if (altitude < 30) {
      return localization.translate('space.atmosphere_layers.mesosphere');
    } else if (altitude < 45) {
      return localization.translate('space.atmosphere_layers.thermosphere');
    } else if (altitude < 60) {
      return localization.translate('space.atmosphere_layers.exosphere');
    } else {
      return localization.translate('space.atmosphere_layers.space');
    }
  }

  /// 获取难度描述
  String getDifficultyDescription() {
    final localization = Localization();
    if (altitude < 10) {
      return localization.translate('space.difficulty.easy');
    } else if (altitude < 20) {
      return localization.translate('space.difficulty.normal');
    } else if (altitude < 40) {
      return localization.translate('space.difficulty.hard');
    } else {
      return localization.translate('space.difficulty.extreme');
    }
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    // 在Flutter中，状态更新将通过状态管理自动处理
    notifyListeners();
  }

  /// 重置太空状态（用于新游戏）
  void reset() {
    Logger.info('🚀 开始重置太空模块状态');

    // 停止所有定时器
    _clearTimers();

    // 重置所有状态
    done = false;
    shipX = 350.0;
    shipY = 350.0;
    hull = 0;
    altitude = 0;
    lastMove = null;
    up = down = left = right = false;

    // 清空小行星列表
    asteroids.clear();
    Logger.info('🚀 已清空 ${asteroids.length} 个小行星');

    // 重新启动游戏循环
    _startGameLoop();

    Logger.info('🚀 太空模块重置完成');
    notifyListeners();
  }

  /// 启动游戏循环
  void _startGameLoop() {
    // 重新启动基本定时器（参考原始的onArrival方法）
    final shipUpdateInterval = kIsWeb ? 33 : 50; // Web: 30FPS, Mobile: 20FPS
    shipTimer = Timer.periodic(
        Duration(milliseconds: shipUpdateInterval), (_) => moveShip());
    volumeTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => lowerVolume());

    // 启动上升过程
    startAscent();

    Logger.info('🚀 游戏循环定时器已重新启动');
  }

  /// 手动控制飞船（用于触摸控制）
  void setShipDirection({bool? up, bool? down, bool? left, bool? right}) {
    bool stateChanged = false;

    if (up != null && this.up != up) {
      this.up = up;
      stateChanged = true;
    }
    if (down != null && this.down != down) {
      this.down = down;
      stateChanged = true;
    }
    if (left != null && this.left != left) {
      this.left = left;
      stateChanged = true;
    }
    if (right != null && this.right != right) {
      this.right = right;
      stateChanged = true;
    }

    // 只有状态真正改变时才通知
    if (stateChanged) {
      _throttledNotifyListeners();
    }
  }

  /// 获取小行星数量
  int getAsteroidCount() {
    return asteroids.length;
  }

  /// 检查是否在太空中
  bool isInSpace() {
    return altitude >= 60;
  }

  /// 获取进度百分比
  double getProgress() {
    return (altitude / 60.0).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }
}

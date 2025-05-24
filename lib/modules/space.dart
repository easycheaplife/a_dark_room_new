import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import 'ship.dart';

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
  final String name = "太空";

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

  // 小行星列表
  List<Map<String, dynamic>> asteroids = [];

  /// 初始化太空模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    notifyListeners();
  }

  /// 到达时调用
  void onArrival() {
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

    startAscent();

    // 启动定时器
    shipTimer = Timer.periodic(Duration(milliseconds: 33), (_) => moveShip());
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
    notifyListeners();
  }

  /// 获取飞船速度
  double getSpeed() {
    final sm = StateManager();
    final thrusters = (sm.get('game.spaceShip.thrusters', true) ?? 1) as int;
    return shipSpeed + thrusters;
  }

  /// 更新船体显示
  void updateHull() {
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
      'speed': baseAsteroidSpeed - random.nextInt((baseAsteroidSpeed * 0.65).round()),
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
        Timer(Duration(milliseconds: delay.clamp(100, 1000)), () => createAsteroid());
      }
    }

    notifyListeners();
  }

  /// 小行星动画
  void _animateAsteroid(Map<String, dynamic> asteroid) {
    Timer.periodic(Duration(milliseconds: 16), (timer) {
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
      }

      notifyListeners();
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

    if (up) {
      dy -= getSpeed();
    } else if (down) {
      dy += getSpeed();
    }
    if (left) {
      dx -= getSpeed();
    } else if (right) {
      dx += getSpeed();
    }

    // 对角线移动时调整速度
    if (dx != 0 && dy != 0) {
      dx = dx / sqrt(2);
      dy = dy / sqrt(2);
    }

    // 时间补偿
    if (lastMove != null) {
      final dt = DateTime.now().difference(lastMove!).inMilliseconds;
      dx *= dt / 33;
      dy *= dt / 33;
    }

    shipX = (shipX + dx).clamp(10.0, 690.0);
    shipY = (shipY + dy).clamp(10.0, 690.0);

    lastMove = DateTime.now();
    notifyListeners();
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
      if (altitude > 60) {
        timer.cancel();
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
    notifyListeners();
  }

  /// 坠毁
  void crash() {
    if (done) return;

    done = true;
    _clearTimers();

    NotificationManager().notify(name, "飞船坠毁了！");

    // 播放坠毁音效（暂时注释掉）
    // AudioEngine().playSound(AudioLibrary.crash);

    // 返回飞船模块
    Timer(Duration(milliseconds: 300), () {
      Ship().onArrival();
      // 设置起飞按钮冷却
    });

    notifyListeners();
  }

  /// 游戏结束
  void endGame() {
    if (done) return;

    done = true;
    _clearTimers();

    NotificationManager().notify(name, "成功逃离了星球！");

    // 播放结束音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicEnding);

    // 标记游戏完成
    final sm = StateManager();
    sm.set('game.completed', true);
    sm.set('game.won', true);

    // 显示结束选项
    Timer(Duration(seconds: 5), () {
      showEndingOptions();
    });

    notifyListeners();
  }

  /// 显示结束选项
  void showEndingOptions() {
    // 在Flutter中，结束选项将通过对话框显示
    NotificationManager().notify(name, "游戏完成！恭喜你成功逃离了这个星球！");
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
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        up = true;
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        down = true;
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        left = true;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        right = true;
        break;
    }
    notifyListeners();
  }

  /// 按键释放处理
  void keyUp(LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        up = false;
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        down = false;
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        left = false;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        right = false;
        break;
    }
    notifyListeners();
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
    if (altitude < 10) {
      return "对流层";
    } else if (altitude < 20) {
      return "平流层";
    } else if (altitude < 30) {
      return "中间层";
    } else if (altitude < 45) {
      return "热层";
    } else if (altitude < 60) {
      return "外逸层";
    } else {
      return "太空";
    }
  }

  /// 获取难度描述
  String getDifficultyDescription() {
    if (altitude < 10) {
      return "轻松";
    } else if (altitude < 20) {
      return "普通";
    } else if (altitude < 40) {
      return "困难";
    } else {
      return "极难";
    }
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    // 在Flutter中，状态更新将通过状态管理自动处理
    notifyListeners();
  }

  /// 重置太空状态（用于新游戏）
  void reset() {
    done = false;
    shipX = 350.0;
    shipY = 350.0;
    hull = 0;
    altitude = 0;
    lastMove = null;
    up = down = left = right = false;
    asteroids.clear();
    _clearTimers();

    notifyListeners();
  }

  /// 手动控制飞船（用于触摸控制）
  void setShipDirection({bool? up, bool? down, bool? left, bool? right}) {
    if (up != null) this.up = up;
    if (down != null) this.down = down;
    if (left != null) this.left = left;
    if (right != null) this.right = right;
    notifyListeners();
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

import 'package:flutter/material.dart';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import 'events.dart';

/// 飞船模块 - 注册星际飞船功能
/// 包括船体强化、引擎升级、起飞等功能
class Ship extends ChangeNotifier {
  static final Ship _instance = Ship._internal();

  factory Ship() {
    return _instance;
  }

  static Ship get instance => _instance;

  Ship._internal();

  // 模块名称
  final String name = "飞船";

  // 常量
  static const int liftoffCooldown = 120;
  static const int alloyPerHull = 1;
  static const int alloyPerThruster = 1;
  static const int baseHull = 0;
  static const int baseThrusters = 1;

  // 状态变量
  Map<String, dynamic> options = {};
  int hull = 0;
  int thrusters = 1;

  /// 初始化飞船模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    final sm = StateManager();

    if (sm.get('features.location.spaceShip') == null) {
      sm.set('features.location.spaceShip', true);
      sm.setM('game.spaceShip', {
        'hull': baseHull,
        'thrusters': baseThrusters
      });
    }

    // 获取当前飞船状态
    hull = (sm.get('game.spaceShip.hull', true) ?? baseHull) as int;
    thrusters = (sm.get('game.spaceShip.thrusters', true) ?? baseThrusters) as int;

    // 初始化太空模块（暂时注释掉，直到Space模块完成）
    // Space().init();

    notifyListeners();
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    setTitle();
    final sm = StateManager();

    if (sm.get('game.spaceShip.seenShip', true) != true) {
      NotificationManager().notify(name, '在碎片云的某处，流浪者舰队在盘旋。在这块岩石上待得太久了。');
      sm.set('game.spaceShip.seenShip', true);
    }

    // 播放背景音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicShip);

    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // 在Flutter中，标题设置将通过状态管理处理
    // document.title = "古老的星际飞船";
  }

  /// 强化船体
  void reinforceHull() {
    final sm = StateManager();
    final alienAlloy = (sm.get('stores["alien alloy"]', true) ?? 0) as int;

    if (alienAlloy < alloyPerHull) {
      NotificationManager().notify(name, "外星合金不足");
      return;
    }

    sm.add('stores["alien alloy"]', -alloyPerHull);
    sm.add('game.spaceShip.hull', 1);
    hull = (sm.get('game.spaceShip.hull', true) ?? 0) as int;

    // 播放音效（暂时注释掉）
    // AudioEngine().playSound(AudioLibrary.reinforceHull);

    NotificationManager().notify(name, "船体已强化");
    notifyListeners();
  }

  /// 升级引擎
  void upgradeEngine() {
    final sm = StateManager();
    final alienAlloy = (sm.get('stores["alien alloy"]', true) ?? 0) as int;

    if (alienAlloy < alloyPerThruster) {
      NotificationManager().notify(name, "外星合金不足");
      return;
    }

    sm.add('stores["alien alloy"]', -alloyPerThruster);
    sm.add('game.spaceShip.thrusters', 1);
    thrusters = (sm.get('game.spaceShip.thrusters', true) ?? 0) as int;

    // 播放音效（暂时注释掉）
    // AudioEngine().playSound(AudioLibrary.upgradeEngine);

    NotificationManager().notify(name, "引擎已升级");
    notifyListeners();
  }

  /// 获取最大船体值
  int getMaxHull() {
    return hull;
  }

  /// 检查起飞条件
  void checkLiftOff() {
    final sm = StateManager();

    if (sm.get('game.spaceShip.seenWarning', true) != true) {
      // 显示警告事件
      final liftOffEvent = {
        'title': '准备离开？',
        'scenes': {
          'start': {
            'text': ['是时候离开这个地方了。不会再回来了。'],
            'buttons': {
              'fly': {
                'text': '起飞',
                'onChoose': () {
                  sm.set('game.spaceShip.seenWarning', true);
                  liftOff();
                },
                'nextScene': 'end'
              },
              'wait': {
                'text': '等待',
                'onChoose': () {
                  // 清除起飞按钮冷却
                  NotificationManager().notify(name, "决定再等等");
                },
                'nextScene': 'end'
              }
            }
          }
        }
      };

      Events().startEvent(liftOffEvent);
    } else {
      liftOff();
    }
  }

  /// 起飞
  void liftOff() {
    // 在Flutter中，起飞动画将通过UI组件处理
    NotificationManager().notify(name, "飞船正在起飞...");

    // 切换到太空模块（暂时注释掉）
    // Space().onArrival();
    // Engine().activeModule = Space();

    // 播放起飞音效（暂时注释掉）
    // AudioEngine().playSound(AudioLibrary.liftOff);

    // 标记游戏完成
    final sm = StateManager();
    sm.set('game.completed', true);

    notifyListeners();
  }

  /// 检查是否可以起飞
  bool canLiftOff() {
    return hull > 0;
  }

  /// 检查是否可以强化船体
  bool canReinforceHull() {
    final sm = StateManager();
    final alienAlloy = (sm.get('stores["alien alloy"]', true) ?? 0) as int;
    return alienAlloy >= alloyPerHull;
  }

  /// 检查是否可以升级引擎
  bool canUpgradeEngine() {
    final sm = StateManager();
    final alienAlloy = (sm.get('stores["alien alloy"]', true) ?? 0) as int;
    return alienAlloy >= alloyPerThruster;
  }

  /// 获取飞船状态
  Map<String, dynamic> getShipStatus() {
    final sm = StateManager();
    final alienAlloy = (sm.get('stores["alien alloy"]', true) ?? 0) as int;

    return {
      'hull': hull,
      'thrusters': thrusters,
      'alienAlloy': alienAlloy,
      'canLiftOff': canLiftOff(),
      'canReinforceHull': canReinforceHull(),
      'canUpgradeEngine': canUpgradeEngine(),
      'seenShip': sm.get('game.spaceShip.seenShip', true) == true,
      'seenWarning': sm.get('game.spaceShip.seenWarning', true) == true,
      'completed': sm.get('game.completed', true) == true,
    };
  }

  /// 获取所需外星合金数量
  Map<String, int> getRequiredAlloy() {
    return {
      'hull': alloyPerHull,
      'thruster': alloyPerThruster,
    };
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    final category = event['category'];
    final stateName = event['stateName'];

    if (category == 'stores' && stateName?.toString().contains('alien alloy') == true) {
      notifyListeners();
    } else if (stateName?.toString().startsWith('game.spaceShip') == true) {
      // 更新本地状态
      final sm = StateManager();
      hull = (sm.get('game.spaceShip.hull', true) ?? 0) as int;
      thrusters = (sm.get('game.spaceShip.thrusters', true) ?? 0) as int;
      notifyListeners();
    }
  }

  /// 重置飞船状态（用于新游戏）
  void reset() {
    final sm = StateManager();
    sm.setM('game.spaceShip', {
      'hull': baseHull,
      'thrusters': baseThrusters
    });
    sm.remove('game.spaceShip.seenShip');
    sm.remove('game.spaceShip.seenWarning');
    sm.remove('game.completed');

    hull = baseHull;
    thrusters = baseThrusters;

    notifyListeners();
  }

  /// 获取飞船描述
  String getShipDescription() {
    if (hull <= 0) {
      return "飞船需要强化船体才能起飞";
    } else if (hull < 5) {
      return "飞船勉强能够飞行";
    } else if (hull < 10) {
      return "飞船状况良好";
    } else {
      return "飞船装甲坚固，准备就绪";
    }
  }

  /// 获取引擎描述
  String getEngineDescription() {
    if (thrusters <= 1) {
      return "基础推进器";
    } else if (thrusters < 5) {
      return "改进的推进系统";
    } else if (thrusters < 10) {
      return "高效推进系统";
    } else {
      return "先进的推进系统";
    }
  }
}
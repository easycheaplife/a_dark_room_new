import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/audio_engine.dart';
import '../core/engine.dart';

/// 外部区域模块 - 注册户外功能
/// 包括村庄建设、工人管理、陷阱检查等功能
class Outside extends ChangeNotifier {
  static final Outside _instance = Outside._internal();

  factory Outside() {
    return _instance;
  }

  static Outside get instance => _instance;

  Outside._internal();

  // 模块名称
  final String name = "外部";

  // 常量
  // static const int _storesOffset = 0; // 暂时未使用
  // static const int _gatherDelay = 60; // 暂时未使用
  // static const int _trapsDelay = 90; // 暂时未使用
  static const List<double> _popDelay = [0.5, 3];
  static const int _hutRoom = 4;

  // 收入配置
  static const Map<String, Map<String, dynamic>> _income = {
    'gatherer': {
      'name': '采集者',
      'delay': 10,
      'stores': {
        'wood': 1
      }
    },
    'hunter': {
      'name': '猎人',
      'delay': 10,
      'stores': {
        'fur': 0.5,
        'meat': 0.5
      }
    },
    'trapper': {
      'name': '陷阱师',
      'delay': 10,
      'stores': {
        'meat': -1,
        'bait': 1
      }
    },
    'tanner': {
      'name': '制革工',
      'delay': 10,
      'stores': {
        'fur': -5,
        'leather': 1
      }
    },
    'charcutier': {
      'name': '腌肉师',
      'delay': 10,
      'stores': {
        'meat': -5,
        'wood': -5,
        'cured meat': 1
      }
    },
    'iron miner': {
      'name': '铁矿工',
      'delay': 10,
      'stores': {
        'cured meat': -1,
        'iron': 1
      }
    },
    'coal miner': {
      'name': '煤矿工',
      'delay': 10,
      'stores': {
        'cured meat': -1,
        'coal': 1
      }
    },
    'sulphur miner': {
      'name': '硫磺矿工',
      'delay': 10,
      'stores': {
        'cured meat': -1,
        'sulphur': 1
      }
    },
    'steelworker': {
      'name': '钢铁工',
      'delay': 10,
      'stores': {
        'iron': -1,
        'coal': -1,
        'steel': 1
      }
    },
    'armourer': {
      'name': '军械师',
      'delay': 10,
      'stores': {
        'steel': -1,
        'sulphur': -1,
        'bullets': 1
      }
    }
  };

  // 陷阱掉落物配置
  static const List<Map<String, dynamic>> trapDrops = [
    {
      'rollUnder': 0.5,
      'name': 'fur',
      'message': '毛皮碎片'
    },
    {
      'rollUnder': 0.75,
      'name': 'meat',
      'message': '肉块'
    },
    {
      'rollUnder': 0.85,
      'name': 'scales',
      'message': '奇怪的鳞片'
    },
    {
      'rollUnder': 0.93,
      'name': 'teeth',
      'message': '散落的牙齿'
    },
    {
      'rollUnder': 0.995,
      'name': 'cloth',
      'message': '破烂的布料'
    },
    {
      'rollUnder': 1.0,
      'name': 'charm',
      'message': '粗制的护身符'
    }
  ];

  // 状态变量
  Timer? _popTimeout;
  Map<String, dynamic> options = {};

  /// 初始化外部模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    final sm = StateManager();

    // 调试模式下加速
    final engine = Engine();
    if (engine.options['debug'] == true) {
      // _gatherDelay = 0;
      // _trapsDelay = 0;
    }

    // 设置初始状态
    if (sm.get('features.location.outside') == null) {
      sm.set('features.location.outside', true);
      if (sm.get('game.buildings') == null) sm.set('game.buildings', {});
      if (sm.get('game.population') == null) sm.set('game.population', 0);
      if (sm.get('game.workers') == null) sm.set('game.workers', {});
    }

    updateVillage();
    updateWorkersView();
    updateVillageIncome();
    updateTrapButton();

    notifyListeners();
  }

  /// 获取最大人口数
  int getMaxPopulation() {
    final sm = StateManager();
    return (sm.get('game.buildings["hut"]', true) ?? 0) * _hutRoom;
  }

  /// 增加人口
  void increasePopulation() {
    final sm = StateManager();
    final space = getMaxPopulation() - (sm.get('game.population', true) ?? 0);
    if (space > 0) {
      final random = Random();
      var num = (random.nextDouble() * (space / 2) + space / 2).floor();
      if (num == 0) num = 1;

      String message;
      if (num == 1) {
        message = '一个陌生人在夜里到达';
      } else if (num < 5) {
        message = '一个饱经风霜的家庭住进了其中一间小屋';
      } else if (num < 10) {
        message = '一小群人到达，满身尘土和疲惫';
      } else if (num < 30) {
        message = '一支车队蹒跚而来，忧虑与希望并存';
      } else {
        message = '小镇正在蓬勃发展，消息确实传开了';
      }

      NotificationManager().notify(name, message);
      // Engine().log('人口增加了 $num'); // 暂时注释掉，直到Engine有log方法
      sm.add('game.population', num);
    }
    schedulePopIncrease();
  }

  /// 杀死村民
  void killVillagers(int num) {
    final sm = StateManager();
    sm.add('game.population', -num);
    if ((sm.get('game.population', true) ?? 0) < 0) {
      sm.set('game.population', 0);
    }

    final remaining = getNumGatherers();
    if (remaining < 0) {
      var gap = -remaining;
      final workers = sm.get('game.workers', true) ?? {};
      for (final k in workers.keys) {
        final numWorkers = (sm.get('game.workers["$k"]', true) ?? 0) as int;
        if (numWorkers < gap) {
          gap -= numWorkers;
          sm.set('game.workers["$k"]', 0);
        } else {
          sm.add('game.workers["$k"]', -gap);
          break;
        }
      }
    }
  }

  /// 摧毁小屋
  int destroyHuts(int num, [bool allowEmpty = false]) {
    final sm = StateManager();
    var dead = 0;
    final random = Random();

    for (var i = 0; i < num; i++) {
      final population = sm.get('game.population', true) ?? 0;
      final rate = population / _hutRoom;
      final full = rate.floor();
      // 默认情况下用于摧毁满的或半满的小屋
      // 传递 allowEmpty 以在末日中包括空小屋
      final huts = allowEmpty ? (sm.get('game.buildings["hut"]', true) ?? 0) : rate.ceil();
      if (huts == 0) {
        break;
      }

      // random 可以是 0 但不能是 1；然而，0 作为目标是无用的
      final target = (random.nextDouble() * huts).floor() + 1;
      var inhabitants = 0;
      if (target <= full) {
        inhabitants = _hutRoom;
      } else if (target == full + 1) {
        inhabitants = population % _hutRoom;
      }

      sm.set('game.buildings["hut"]', (sm.get('game.buildings["hut"]', true) ?? 0) - 1);
      if (inhabitants > 0) {
        killVillagers(inhabitants);
        dead += inhabitants;
      }
    }
    // 此方法返回受害者总数，用于进一步操作
    return dead;
  }

  /// 安排人口增长
  void schedulePopIncrease() {
    final random = Random();
    final nextIncrease = (random.nextDouble() * (_popDelay[1] - _popDelay[0]) + _popDelay[0]);
    // Engine().log('下次人口增长安排在 $nextIncrease 分钟后'); // 暂时注释掉
    _popTimeout = Timer(Duration(milliseconds: (nextIncrease * 60 * 1000).round()), increasePopulation);
  }

  /// 更新工人视图
  void updateWorkersView() {
    final sm = StateManager();

    // 如果我们的人口是 0 并且我们还没有工人视图，这里没有什么要做的
    if ((sm.get('game.population', true) ?? 0) == 0) return;

    // 计算采集者数量（暂时不使用，但保留逻辑）
    // var numGatherers = sm.get('game.population', true) ?? 0;
    // final workers = sm.get('game.workers', true) ?? {};
    //
    // for (final k in workers.keys) {
    //   final workerCount = sm.get('game.workers["$k"]', true) ?? 0;
    //   numGatherers -= workerCount;
    // }

    notifyListeners();
  }

  /// 获取采集者数量
  int getNumGatherers() {
    final sm = StateManager();
    var num = sm.get('game.population', true) ?? 0;
    final workers = sm.get('game.workers', true) ?? {};
    for (final k in workers.keys) {
      num -= sm.get('game.workers["$k"]', true) ?? 0;
    }
    return num;
  }

  /// 增加工人
  void increaseWorker(String worker, int amount) {
    final sm = StateManager();
    if (getNumGatherers() > 0) {
      final increaseAmt = min(getNumGatherers(), amount);
      // Engine().log('增加 $worker $increaseAmt'); // 暂时注释掉
      sm.add('game.workers["$worker"]', increaseAmt);
    }
  }

  /// 减少工人
  void decreaseWorker(String worker, int amount) {
    final sm = StateManager();
    final currentWorkers = (sm.get('game.workers["$worker"]', true) ?? 0) as int;
    if (currentWorkers > 0) {
      final decreaseAmt = min<int>(currentWorkers, amount);
      // Engine().log('减少 $worker $decreaseAmt'); // 暂时注释掉
      sm.add('game.workers["$worker"]', -decreaseAmt);
    }
  }

  /// 更新村庄行
  void updateVillageRow(String name, int num) {
    // 在Flutter中，这将通过状态管理自动更新UI
    notifyListeners();
  }

  /// 更新村庄
  void updateVillage([bool ignoreStores = false]) {
    final sm = StateManager();
    final buildings = sm.get('game.buildings', true) ?? {};

    for (final k in buildings.keys) {
      if (k == 'trap') {
        final numTraps = (sm.get('game.buildings["$k"]', true) ?? 0) as int;
        final numBait = (sm.get('stores.bait', true) ?? 0) as int;
        final traps = max<int>(0, numTraps - numBait);
        updateVillageRow(k, traps);
        updateVillageRow('baited trap', min<int>(numBait, numTraps));
      } else {
        if (checkWorker(k)) {
          updateWorkersView();
        }
        updateVillageRow(k, (sm.get('game.buildings["$k"]', true) ?? 0) as int);
      }
    }

    setTitle();

    final hasPeeps = (sm.get('game.buildings["hut"]', true) ?? 0) > 0;
    if (hasPeeps && _popTimeout == null) {
      schedulePopIncrease();
    }

    notifyListeners();
  }

  /// 检查工人
  bool checkWorker(String name) {
    final jobMap = {
      'lodge': ['hunter', 'trapper'],
      'tannery': ['tanner'],
      'smokehouse': ['charcutier'],
      'iron mine': ['iron miner'],
      'coal mine': ['coal miner'],
      'sulphur mine': ['sulphur miner'],
      'steelworks': ['steelworker'],
      'armoury': ['armourer']
    };

    final jobs = jobMap[name];
    var added = false;
    final sm = StateManager();

    if (jobs != null) {
      for (final job in jobs) {
        if (sm.get('game.buildings["$name"]') != null &&
            sm.get('game.workers["$job"]') == null) {
          // Engine().log('添加 $job 到工人列表'); // 暂时注释掉
          sm.set('game.workers["$job"]', 0);
          added = true;
        }
      }
    }
    return added;
  }

  /// 更新村庄收入
  void updateVillageIncome() {
    final sm = StateManager();

    for (final worker in _income.keys) {
      final income = _income[worker]!;
      final num = worker == 'gatherer' ? getNumGatherers() : ((sm.get('game.workers["$worker"]', true) ?? 0) as int);

      if (num >= 0) {
        final stores = <String, dynamic>{};
        final incomeStores = income['stores'] as Map<String, dynamic>;

        for (final store in incomeStores.keys) {
          stores[store] = incomeStores[store] * num;
        }

        // 设置收入
        sm.setIncome(worker, {
          'delay': income['delay'],
          'stores': stores
        });
      }
    }

    // Room.updateIncomeView(); // 当Room模块完善后取消注释
    notifyListeners();
  }

  /// 更新陷阱按钮
  void updateTrapButton() {
    // final sm = StateManager();
    // final numTraps = sm.get('game.buildings["trap"]', true) ?? 0;

    // 在Flutter中，按钮状态将通过状态管理自动更新
    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // final sm = StateManager();
    // final numHuts = (sm.get('game.buildings["hut"]', true) ?? 0) as int;

    // 根据小屋数量确定标题（暂时不存储，但保留逻辑）
    // String title;
    // if (numHuts == 0) {
    //   title = "寂静的森林";
    // } else if (numHuts == 1) {
    //   title = "孤独的小屋";
    // } else if (numHuts <= 4) {
    //   title = "小村庄";
    // } else if (numHuts <= 8) {
    //   title = "中等村庄";
    // } else if (numHuts <= 14) {
    //   title = "大村庄";
    // } else {
    //   title = "喧闹的村庄";
    // }

    // 在Flutter中，标题更新将通过状态管理处理
    notifyListeners();
  }

  /// 获取当前标题
  String getTitle() {
    final sm = StateManager();
    final numHuts = (sm.get('game.buildings["hut"]', true) ?? 0) as int;

    if (numHuts == 0) {
      return "寂静的森林";
    } else if (numHuts == 1) {
      return "孤独的小屋";
    } else if (numHuts <= 4) {
      return "小村庄";
    } else if (numHuts <= 8) {
      return "中等村庄";
    } else if (numHuts <= 14) {
      return "大村庄";
    } else {
      return "喧闹的村庄";
    }
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    final sm = StateManager();
    setTitle();

    if (sm.get('game.outside.seenForest', true) != true) {
      NotificationManager().notify(name, "天空是灰色的，风无情地吹着");
      sm.set('game.outside.seenForest', true);
    }

    updateTrapButton();
    updateVillage(true);

    // 设置音乐（暂时注释掉，直到AudioLibrary有这些常量）
    // final numberOfHuts = (sm.get('game.buildings["hut"]', true) ?? 0) as int;
    // if (numberOfHuts == 0) {
    //   AudioEngine().playBackgroundMusic(AudioLibrary.musicSilentForest);
    // } else if (numberOfHuts == 1) {
    //   AudioEngine().playBackgroundMusic(AudioLibrary.musicLonelyHut);
    // } else if (numberOfHuts <= 4) {
    //   AudioEngine().playBackgroundMusic(AudioLibrary.musicTinyVillage);
    // } else if (numberOfHuts <= 8) {
    //   AudioEngine().playBackgroundMusic(AudioLibrary.musicModestVillage);
    // } else if (numberOfHuts <= 14) {
    //   AudioEngine().playBackgroundMusic(AudioLibrary.musicLargeVillage);
    // } else {
    //   AudioEngine().playBackgroundMusic(AudioLibrary.musicRaucousVillage);
    // }

    notifyListeners();
  }

  /// 采集木材
  void gatherWood() {
    final sm = StateManager();
    NotificationManager().notify(name, "干燥的灌木和枯枝散落在森林地面上");
    final gatherAmt = (sm.get('game.buildings["cart"]', true) ?? 0) > 0 ? 50 : 10;
    sm.add('stores.wood', gatherAmt);
    AudioEngine().playSound('gather_wood');
  }

  /// 检查陷阱
  void checkTraps() {
    final sm = StateManager();
    final drops = <String, int>{};
    final msg = <String>[];
    final numTraps = (sm.get('game.buildings["trap"]', true) ?? 0) as int;
    final numBait = (sm.get('stores.bait', true) ?? 0) as int;
    final numDrops = numTraps + min<int>(numBait, numTraps);
    final random = Random();

    for (var i = 0; i < numDrops; i++) {
      final roll = random.nextDouble();
      for (final drop in trapDrops) {
        if (roll < drop['rollUnder']) {
          final name = drop['name'] as String;
          final message = drop['message'] as String;
          final num = drops[name] ?? 0;
          if (num == 0) {
            msg.add(message);
          }
          drops[name] = num + 1;
          break;
        }
      }
    }

    // 构建消息
    var s = '陷阱里有 ';
    for (var l = 0; l < msg.length; l++) {
      if (msg.length > 1 && l > 0 && l < msg.length - 1) {
        s += ", ";
      } else if (msg.length > 1 && l == msg.length - 1) {
        s += " 和 ";
      }
      s += msg[l];
    }

    final baitUsed = min<int>(numBait, numTraps);
    drops['bait'] = -baitUsed;

    NotificationManager().notify(name, s);
    // sm.addM('stores', drops); // 当StateManager有addM方法时取消注释
    AudioEngine().playSound('check_traps');
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    final category = event['category'];
    final stateName = event['stateName'];

    if (category == 'stores') {
      updateVillage();
    } else if (stateName?.toString().startsWith('game.workers') == true ||
               stateName?.toString().startsWith('game.population') == true) {
      updateVillage();
      updateWorkersView();
      updateVillageIncome();
    }

    notifyListeners();
  }

  /// 按键处理
  void keyDown(dynamic event) {
    // 在原始游戏中，外部模块不处理按键
  }

  void keyUp(dynamic event) {
    // 在原始游戏中，外部模块不处理按键
  }

  /// 滑动处理
  void swipeLeft() {
    // 在原始游戏中，外部模块不处理滑动
  }

  void swipeRight() {
    // 在原始游戏中，外部模块不处理滑动
  }

  void swipeUp() {
    // 在原始游戏中，外部模块不处理滑动
  }

  void swipeDown() {
    // 在原始游戏中，外部模块不处理滑动
  }

  @override
  void dispose() {
    _popTimeout?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import 'room.dart';
import 'world.dart';

/// 路径模块 - 处理装备和出发到世界地图
/// 包括装备管理、背包空间、物品重量等功能
class Path extends ChangeNotifier {
  static final Path _instance = Path._internal();

  factory Path() {
    return _instance;
  }

  static Path get instance => _instance;

  Path._internal();

  // 模块名称
  final String name = "漫漫尘途";

  // 常量
  static const int defaultBagSpace = 10;
  static const int storesOffset = 0;

  // 物品重量配置
  static const Map<String, double> weight = {
    'bone spear': 2.0,
    'iron sword': 3.0,
    'steel sword': 5.0,
    'rifle': 5.0,
    'bullets': 0.1,
    'energy cell': 0.2,
    'laser rifle': 5.0,
    'plasma rifle': 5.0,
    'bolas': 0.5,
  };

  // 状态变量
  Map<String, dynamic> options = {};
  Map<String, int> outfit = {};

  /// 初始化路径模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    final sm = StateManager();

    // 初始化世界模块（暂时注释掉，直到World模块完成）
    // World().init();

    // 设置初始状态
    if (sm.get('features.location.path') == null) {
      sm.set('features.location.path', true);
    }

    // 获取装备配置
    final savedOutfit = sm.get('outfit', true);
    if (savedOutfit != null && savedOutfit is Map) {
      outfit = Map<String, int>.from(savedOutfit);
    }

    updateOutfitting();
    updatePerks();

    notifyListeners();
  }

  /// 打开路径
  void openPath() {
    init();
    Engine().event('progress', 'path');
    NotificationManager().notify(Room().name, '指南针指向东方'); // 暂时硬编码方向
  }

  /// 获取物品重量
  double getWeight(String thing) {
    return weight[thing] ?? 1.0;
  }

  /// 获取背包容量
  int getCapacity() {
    final sm = StateManager();

    if ((sm.get('stores["cargo drone"]', true) ?? 0) > 0) {
      return defaultBagSpace + 100;
    } else if ((sm.get('stores.convoy', true) ?? 0) > 0) {
      return defaultBagSpace + 60;
    } else if ((sm.get('stores.wagon', true) ?? 0) > 0) {
      return defaultBagSpace + 30;
    } else if ((sm.get('stores.rucksack', true) ?? 0) > 0) {
      return defaultBagSpace + 10;
    }
    return defaultBagSpace;
  }

  /// 获取剩余空间
  double getFreeSpace() {
    double num = 0;
    for (final k in outfit.keys) {
      final n = outfit[k] ?? 0;
      num += n * getWeight(k);
    }
    return getCapacity() - num;
  }

  /// 获取总重量
  double getTotalWeight() {
    double num = 0;
    for (final k in outfit.keys) {
      final n = outfit[k] ?? 0;
      num += n * getWeight(k);
    }
    return num;
  }

  /// 更新技能显示
  void updatePerks([bool ignoreStores = false]) {
    final sm = StateManager();
    final perks = sm.get('character.perks', true);

    if (perks != null && perks is Map) {
      // 在Flutter中，技能显示将通过状态管理自动更新
      // 这里保留逻辑但不直接操作DOM
      notifyListeners();
    }
  }

  /// 更新装备界面
  void updateOutfitting() {
    final sm = StateManager();

    if (outfit.isEmpty) {
      outfit = {};
    }

    // 获取护甲类型（暂时不使用，但保留逻辑）
    // String armour = "无";
    // if ((sm.get('stores["kinetic armour"]', true) ?? 0) > 0) {
    //   armour = "动能";
    // } else if ((sm.get('stores["s armour"]', true) ?? 0) > 0) {
    //   armour = "钢制";
    // } else if ((sm.get('stores["i armour"]', true) ?? 0) > 0) {
    //   armour = "铁制";
    // } else if ((sm.get('stores["l armour"]', true) ?? 0) > 0) {
    //   armour = "皮革";
    // }

    // 计算当前背包容量
    double currentBagCapacity = 0;
    // final freeSpace = getFreeSpace(); // 暂时不使用

    // 可携带物品配置
    final carryable = <String, Map<String, dynamic>>{
      'cured meat': {'type': 'tool', 'desc': '恢复 10 生命值'},
      'bullets': {'type': 'tool', 'desc': '与步枪一起使用'},
      'grenade': {'type': 'weapon'},
      'bolas': {'type': 'weapon'},
      'laser rifle': {'type': 'weapon'},
      'energy cell': {'type': 'tool', 'desc': '发出柔和的红光'},
      'bayonet': {'type': 'weapon'},
      'charm': {'type': 'tool'},
      'alien alloy': {'type': 'tool'},
      'medicine': {'type': 'tool', 'desc': '恢复 20 生命值'}
    };

    // 添加房间和制造器的可制作物品（暂时注释掉）
    // carryable.addAll(Room.craftables);
    // carryable.addAll(Fabricator.craftables);

    for (final k in carryable.keys) {
      final store = carryable[k]!;
      final have = (sm.get('stores["$k"]', true) ?? 0) as int;
      var num = outfit[k] ?? 0;

      if (have < num) {
        num = have;
      }
      outfit[k] = num;

      if ((store['type'] == 'tool' || store['type'] == 'weapon') && have > 0) {
        currentBagCapacity += num * getWeight(k);
      }
    }

    updateBagSpace(currentBagCapacity);
    notifyListeners();
  }

  /// 更新背包空间显示
  void updateBagSpace(double currentBagCapacity) {
    // final freeSpace = getCapacity() - currentBagCapacity; // 暂时不使用

    // 在Flutter中，背包空间显示将通过状态管理自动更新
    // 检查是否可以出发（需要有腌肉）
    // final canEmbark = (outfit['cured meat'] ?? 0) > 0; // 暂时不使用

    notifyListeners();
  }

  /// 增加补给
  void increaseSupply(String supply, int amount) {
    final sm = StateManager();
    final cur = outfit[supply] ?? 0;
    final available = (sm.get('stores["$supply"]', true) ?? 0) as int;

    if (getFreeSpace() >= getWeight(supply) && cur < available) {
      final maxExtraByWeight = (getFreeSpace() / getWeight(supply)).floor();
      final maxExtraByStore = available - cur;
      outfit[supply] =
          cur + min(amount, min(maxExtraByWeight, maxExtraByStore));
      sm.set('outfit[$supply]', outfit[supply]);
      updateOutfitting();
    }
  }

  /// 减少补给
  void decreaseSupply(String supply, int amount) {
    final sm = StateManager();
    final cur = outfit[supply] ?? 0;

    if (cur > 0) {
      outfit[supply] = max(0, cur - amount);
      sm.set('outfit[$supply]', outfit[supply]);
      updateOutfitting();
    }
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    setTitle();
    updateOutfitting();
    updatePerks(true);

    // 播放背景音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicDustyPath);

    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // 在Flutter中，标题设置将通过状态管理处理
    // document.title = '漫漫尘途';
  }

  /// 出发到世界地图
  void embark() {
    print('🚀 Path.embark() 被调用');
    final sm = StateManager();

    try {
      // 扣除装备中的物品
      for (final k in outfit.keys) {
        final amount = outfit[k] ?? 0;
        if (amount > 0) {
          print('扣除装备: $k x$amount');
          sm.add('stores["$k"]', -amount);
        }
      }

      print('🌍 初始化World模块...');
      // 初始化World模块
      World().init();

      print('🌍 设置世界功能为已解锁...');
      // 设置世界功能为已解锁
      sm.set('features.location.world', true);

      print('🌍 切换到World模块...');
      // 切换到世界模块
      Engine().travelTo(World());

      // 显示成功消息
      NotificationManager().notify('漫漫尘途', '你踏上了前往未知世界的旅程...');

      print('✅ embark() 完成');
    } catch (e, stackTrace) {
      print('❌ embark() 错误: $e');
      print('❌ 错误堆栈: $stackTrace');
      NotificationManager().notify('漫漫尘途', '出发失败: $e');
    }

    notifyListeners();
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    final category = event['category'];
    final stateName = event['stateName'];

    if (category == 'character' &&
        stateName?.toString().startsWith('character.perks') == true &&
        Engine().activeModule == this) {
      updatePerks();
    } else if (category == 'income' && Engine().activeModule == this) {
      updateOutfitting();
    }

    notifyListeners();
  }

  /// 获取护甲类型
  String getArmourType() {
    final sm = StateManager();

    if ((sm.get('stores["kinetic armour"]', true) ?? 0) > 0) {
      return "动能护甲";
    } else if ((sm.get('stores["s armour"]', true) ?? 0) > 0) {
      return "钢制护甲";
    } else if ((sm.get('stores["i armour"]', true) ?? 0) > 0) {
      return "铁制护甲";
    } else if ((sm.get('stores["l armour"]', true) ?? 0) > 0) {
      return "皮革护甲";
    }
    return "无护甲";
  }

  /// 获取最大水量（暂时返回固定值）
  int getMaxWater() {
    // 这个值应该从World模块获取
    return 10;
  }

  /// 检查是否可以出发
  bool canEmbark() {
    final curedMeat = outfit['cured meat'] ?? 0;
    final canGo = curedMeat > 0;
    print('🔍 canEmbark: 腌肉=$curedMeat, 可以出发=$canGo');
    return canGo;
  }

  /// 获取装备信息
  Map<String, int> getOutfit() {
    return Map<String, int>.from(outfit);
  }

  /// 设置装备
  void setOutfit(Map<String, int> newOutfit) {
    outfit = Map<String, int>.from(newOutfit);
    final sm = StateManager();
    sm.set('outfit', outfit);
    updateOutfitting();
  }
}

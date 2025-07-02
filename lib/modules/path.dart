import 'package:flutter/material.dart';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/engine.dart';
import '../core/localization.dart';
import 'room.dart';
import 'world.dart';
import '../core/logger.dart';
import '../config/game_config.dart';
import 'dart:async';

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
  String get name {
    final localization = Localization();
    return localization.translate('ui.modules.path');
  }

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
  Timer? _cooldownTimer;

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

    // 获取装备配置 - 支持两种格式的数据
    final savedOutfit = sm.get('outfit', true);
    if (savedOutfit != null && savedOutfit is Map) {
      outfit = Map<String, int>.from(savedOutfit);
    } else {
      // 如果没有整体的outfit数据，尝试从单个物品键值对中恢复
      outfit = {};
      // 这里可以添加从单个outfit["item"]键中恢复数据的逻辑
      // 但为了简化，我们先使用空的outfit
    }

    updateOutfitting();
    updatePerks();

    notifyListeners();
  }

  /// 打开路径
  void openPath() {
    init();
    Engine().event('progress', 'path');
    final localization = Localization();
    NotificationManager().notify(
        Room().name, localization.translate('path.compass_points_east'));
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
    } else if ((sm.get('stores["convoy"]', true) ?? 0) > 0) {
      return defaultBagSpace + 60;
    } else if ((sm.get('stores["wagon"]', true) ?? 0) > 0) {
      return defaultBagSpace + 30;
    } else if ((sm.get('stores["rucksack"]', true) ?? 0) > 0) {
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

    // 可携带物品配置 - 基于原游戏的carryable对象
    final carryable = <String, Map<String, dynamic>>{
      // 基础可携带物品
      'cured meat': {'type': 'tool', 'desc': 'restores 10 health'},
      'bullets': {'type': 'tool', 'desc': 'for use with rifle'},
      'grenade': {'type': 'weapon'},
      'bolas': {'type': 'weapon'},
      'laser rifle': {'type': 'weapon'},
      'energy cell': {'type': 'tool', 'desc': 'glows softly red'},
      'bayonet': {'type': 'weapon'},
      'charm': {'type': 'tool'},
      'alien alloy': {'type': 'tool'},
      'medicine': {'type': 'tool', 'desc': 'restores 20 health'},

      // 从Room.Craftables添加的武器
      'bone spear': {'type': 'weapon'},
      'iron sword': {'type': 'weapon'},
      'steel sword': {'type': 'weapon'},
      'rifle': {'type': 'weapon'},

      // 从Room.Craftables添加的工具 - 遗漏的重要物品！
      'torch': {'type': 'tool', 'desc': 'provides light in dark places'},

      // 从Fabricator.Craftables添加的工具 - 遗漏的重要物品！
      'hypo': {'type': 'tool', 'desc': 'restores 30 health'},
      'stim': {'type': 'tool', 'desc': 'provides temporary boost'},
      'glowstone': {'type': 'tool', 'desc': 'inextinguishable light source'},
      'energy blade': {'type': 'weapon'},
      'disruptor': {'type': 'weapon'},
      'plasma rifle': {'type': 'weapon'},
    };

    // 添加房间和制造器的可制作物品（暂时注释掉）
    // carryable.addAll(Room.craftables);
    // carryable.addAll(Fabricator.craftables);

    for (final k in carryable.keys) {
      final store = carryable[k]!;
      final have = sm.get('stores["$k"]', true);
      var num = outfit[k] ?? 0;

      // 参考原游戏逻辑：只有当仓库中有这个物品时才检查数量限制
      if (have != null) {
        final haveInt = have as int;
        if (haveInt < num) {
          num = haveInt;
        }
        // 重要：原游戏总是同步outfit数据到StateManager
        sm.set('outfit["$k"]', num);
        outfit[k] = num;
      }

      if ((store['type'] == 'tool' || store['type'] == 'weapon') &&
          (have ?? 0) > 0) {
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
    // 检查是否可以出发（需要有熏肉）
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
      // 使用统一的格式保存到StateManager
      sm.set('outfit["$supply"]', outfit[supply]);
      updateOutfitting();
    }
  }

  /// 减少补给
  void decreaseSupply(String supply, int amount) {
    final sm = StateManager();
    final cur = outfit[supply] ?? 0;

    if (cur > 0) {
      outfit[supply] = max(0, cur - amount);
      // 使用统一的格式保存到StateManager
      sm.set('outfit["$supply"]', outfit[supply]);
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

    // 检查是否有残留的冷却时间
    _checkResidualCooldown();

    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // 在Flutter中，标题设置将通过状态管理处理
    // final localization = Localization();
    // document.title = localization.translate('ui.modules.path');
  }

  /// 出发到世界地图
  void embark() {
    final localization = Localization();
    Logger.info('🚀 Path.embark() ${localization.translateLog('called')}');
    final sm = StateManager();

    try {
      // 标记已经出发过（用于后续冷却时间判断）
      markEmbarked();

      // 确保outfit已正确初始化
      if (outfit.isEmpty) {
        Logger.info('⚠️ outfit is empty, reinitializing...');
        updateOutfitting();
      }

      Logger.info('🎒 Current equipment status: $outfit');

      // 扣除装备中的物品
      for (final k in outfit.keys) {
        final amount = outfit[k] ?? 0;
        if (amount > 0) {
          Logger.info('Deducting equipment: $k x$amount');
          sm.add('stores["$k"]', -amount);
        }
      }

      // 保存装备状态到StateManager（确保World模块能访问）
      sm.set('outfit', outfit);
      for (final entry in outfit.entries) {
        sm.set('outfit["${entry.key}"]', entry.value);
      }
      Logger.info('🎒 ${localization.translateLog('equipment_status_saved')}');

      Logger.info(
          '🌍 ${localization.translateLog('initializing_world_module')}...');
      // 初始化World模块 - 使用单例实例确保APK版本兼容性
      final worldInstance = World.instance;
      worldInstance.init();

      Logger.info('🌍 Setting world feature as unlocked...');
      // 设置世界功能为已解锁
      sm.set('features.location.world', true);

      Logger.info('🌍 Switching to World module...');
      // 切换到世界模块 - 使用单例实例确保APK版本兼容性
      Engine().travelTo(worldInstance);

      // 显示成功消息
      NotificationManager()
          .notify(name, localization.translate('path.embark_success'));

      Logger.info('✅ embark() completed');
    } catch (e, stackTrace) {
      Logger.info('❌ embark() error: $e');
      Logger.info('❌ Error stack: $stackTrace');
      NotificationManager()
          .notify(name, localization.translate('path.embark_failed'));
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

    final localization = Localization();

    if ((sm.get('stores["kinetic armour"]', true) ?? 0) > 0) {
      return localization.translate('ui.status.kinetic');
    } else if ((sm.get('stores["s armour"]', true) ?? 0) > 0) {
      return localization.translate('ui.status.steel');
    } else if ((sm.get('stores["i armour"]', true) ?? 0) > 0) {
      return localization.translate('ui.status.iron');
    } else if ((sm.get('stores["l armour"]', true) ?? 0) > 0) {
      return localization.translate('ui.status.leather');
    }
    return localization.translate('ui.status.none');
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
    Logger.info('🔍 canEmbark: cured meat=$curedMeat, can go=$canGo');
    return canGo;
  }

  /// 检查是否有出发冷却时间
  bool hasEmbarkCooldown() {
    final sm = StateManager();
    final cooldownTime = sm.get('cooldown.embark', true) ?? 0;
    return cooldownTime > 0;
  }

  /// 获取剩余冷却时间（秒）
  int getEmbarkCooldownRemaining() {
    final sm = StateManager();
    return (sm.get('cooldown.embark', true) ?? 0).round();
  }

  /// 设置出发冷却时间
  void setEmbarkCooldown() {
    final sm = StateManager();
    sm.set('cooldown.embark', GameConfig.embarkCooldown.toDouble());
    Logger.info('🕐 设置出发冷却时间: ${GameConfig.embarkCooldown}秒');

    // 启动倒计时定时器
    _startCooldownTimer();
  }

  /// 启动冷却时间倒计时定时器
  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final sm = StateManager();
      final remaining = sm.get('cooldown.embark', true) ?? 0;

      if (remaining <= 1) {
        // 冷却时间结束
        timer.cancel();
        sm.remove('cooldown.embark');
        Logger.info('✅ 出发冷却时间结束');
        notifyListeners();
      } else {
        // 减少1秒
        sm.set('cooldown.embark', remaining - 1, true);
        notifyListeners();
      }
    });
  }

  /// 检查残留的冷却时间
  void _checkResidualCooldown() {
    final sm = StateManager();
    final remaining = sm.get('cooldown.embark', true) ?? 0;

    if (remaining > 0) {
      Logger.info('🕐 发现残留冷却时间: $remaining秒');
      _startCooldownTimer();
    }
  }

  /// 清除出发冷却时间
  void clearEmbarkCooldown() {
    final sm = StateManager();
    sm.remove('cooldown.embark');
    _cooldownTimer?.cancel();
    Logger.info('✅ 清除出发冷却时间');
    notifyListeners();
  }

  /// 检查是否为首次出发
  bool isFirstEmbark() {
    final sm = StateManager();
    return sm.get('game.firstEmbark', true) ?? true;
  }

  /// 标记已经出发过
  void markEmbarked() {
    final sm = StateManager();
    sm.set('game.firstEmbark', false);
    Logger.info('📝 标记已出发过');
  }

  /// 获取装备信息
  Map<String, int> getOutfit() {
    return Map<String, int>.from(outfit);
  }

  /// 设置装备
  void setOutfit(Map<String, int> newOutfit) {
    outfit = Map<String, int>.from(newOutfit);
    final sm = StateManager();

    // 保存整体outfit数据
    sm.set('outfit', outfit);

    // 同时保存单个物品数据（为了兼容性）
    for (final entry in outfit.entries) {
      sm.set('outfit["${entry.key}"]', entry.value);
    }

    updateOutfitting();
  }
}

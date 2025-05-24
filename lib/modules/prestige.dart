import 'package:flutter/material.dart';
import 'dart:math';
import '../core/state_manager.dart';
import 'score.dart';

/// 声望模块 - 处理游戏的声望系统
/// 包括前一局游戏的物品继承和分数记录
class Prestige extends ChangeNotifier {
  static final Prestige _instance = Prestige._internal();

  factory Prestige() {
    return _instance;
  }

  static Prestige get instance => _instance;

  Prestige._internal();

  // 模块名称
  final String name = "声望";

  // 状态变量
  Map<String, dynamic> options = {};

  /// 物品映射表
  static const List<Map<String, String>> storesMap = [
    // 基础资源 (g = goods)
    {'store': 'wood', 'type': 'g'},
    {'store': 'fur', 'type': 'g'},
    {'store': 'meat', 'type': 'g'},
    {'store': 'iron', 'type': 'g'},
    {'store': 'coal', 'type': 'g'},
    {'store': 'sulphur', 'type': 'g'},
    {'store': 'steel', 'type': 'g'},
    {'store': 'cured meat', 'type': 'g'},
    {'store': 'scales', 'type': 'g'},
    {'store': 'teeth', 'type': 'g'},
    {'store': 'leather', 'type': 'g'},
    {'store': 'bait', 'type': 'g'},
    {'store': 'torch', 'type': 'g'},
    {'store': 'cloth', 'type': 'g'},

    // 武器 (w = weapons)
    {'store': 'bone spear', 'type': 'w'},
    {'store': 'iron sword', 'type': 'w'},
    {'store': 'steel sword', 'type': 'w'},
    {'store': 'bayonet', 'type': 'w'},
    {'store': 'rifle', 'type': 'w'},
    {'store': 'laser rifle', 'type': 'w'},

    // 弹药 (a = ammunition)
    {'store': 'bullets', 'type': 'a'},
    {'store': 'energy cell', 'type': 'a'},
    {'store': 'grenade', 'type': 'a'},
    {'store': 'bolas', 'type': 'a'},
  ];

  /// 初始化声望模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }
    notifyListeners();
  }

  /// 获取当前物品数量（可选择是否减少）
  List<int> getStores([bool reduce = false]) {
    final stores = <int>[];
    final sm = StateManager();

    for (final storeInfo in storesMap) {
      final storeName = storeInfo['store']!;
      final storeType = storeInfo['type']!;
      final amount = (sm.get('stores["$storeName"]', true) ?? 0) as int;

      final divisor = reduce ? randGen(storeType) : 1;
      stores.add((amount / divisor).floor());
    }

    return stores;
  }

  /// 获取声望数据
  Map<String, dynamic> get() {
    final sm = StateManager();
    return {
      'stores': sm.get('previous.stores'),
      'score': sm.get('previous.score'),
    };
  }

  /// 设置声望数据
  void set(Map<String, dynamic> prestige) {
    final sm = StateManager();
    sm.set('previous.stores', prestige['stores']);
    sm.set('previous.score', prestige['score']);
    notifyListeners();
  }

  /// 保存当前游戏状态为声望
  void save() {
    final sm = StateManager();
    sm.set('previous.stores', getStores(true));
    sm.set('previous.score', Score().totalScore());
    notifyListeners();
  }

  /// 收集前一局的物品
  void collectStores() {
    final sm = StateManager();
    final prevStores = sm.get('previous.stores');

    if (prevStores != null && prevStores is List) {
      final toAdd = <String, int>{};

      for (int i = 0; i < storesMap.length && i < prevStores.length; i++) {
        final storeInfo = storesMap[i];
        final storeName = storeInfo['store']!;
        final amount = (prevStores[i] ?? 0) as int;

        if (amount > 0) {
          toAdd[storeName] = amount;
        }
      }

      // 添加物品到当前存储
      for (final entry in toAdd.entries) {
        sm.add('stores["${entry.key}"]', entry.value);
      }

      // 清除已收集的物品
      sm.set('previous.stores', <int>[]);
    }

    notifyListeners();
  }

  /// 随机生成器 - 根据物品类型生成随机除数
  int randGen(String storeType) {
    final random = Random();
    int amount;

    switch (storeType) {
      case 'g': // 基础资源
        amount = random.nextInt(10);
        break;
      case 'w': // 武器
        amount = (random.nextInt(10) / 2).floor();
        break;
      case 'a': // 弹药
        amount = (random.nextDouble() * 10 * (random.nextDouble() * 10 + 1)).ceil();
        break;
      default:
        return 1;
    }

    return amount != 0 ? amount : 1;
  }

  /// 检查是否有前一局的物品
  bool hasPreviousStores() {
    final sm = StateManager();
    final prevStores = sm.get('previous.stores');

    if (prevStores == null || prevStores is! List) {
      return false;
    }

    return prevStores.any((amount) => (amount ?? 0) > 0);
  }

  /// 检查是否有前一局的分数
  bool hasPreviousScore() {
    final sm = StateManager();
    final prevScore = sm.get('previous.score');
    return prevScore != null && prevScore > 0;
  }

  /// 获取前一局分数
  int getPreviousScore() {
    final sm = StateManager();
    return (sm.get('previous.score') ?? 0) as int;
  }

  /// 获取前一局物品总结
  Map<String, int> getPreviousStoresSummary() {
    final sm = StateManager();
    final prevStores = sm.get('previous.stores');
    final summary = <String, int>{};

    if (prevStores != null && prevStores is List) {
      for (int i = 0; i < storesMap.length && i < prevStores.length; i++) {
        final storeInfo = storesMap[i];
        final storeName = storeInfo['store']!;
        final amount = (prevStores[i] ?? 0) as int;

        if (amount > 0) {
          summary[storeName] = amount;
        }
      }
    }

    return summary;
  }

  /// 获取物品类型描述
  String getStoreTypeDescription(String type) {
    switch (type) {
      case 'g':
        return '基础资源';
      case 'w':
        return '武器';
      case 'a':
        return '弹药';
      default:
        return '未知';
    }
  }

  /// 获取声望状态
  Map<String, dynamic> getPrestigeStatus() {
    return {
      'hasPreviousStores': hasPreviousStores(),
      'hasPreviousScore': hasPreviousScore(),
      'previousScore': getPreviousScore(),
      'previousStores': getPreviousStoresSummary(),
      'canCollect': hasPreviousStores(),
    };
  }

  /// 清除声望数据
  void clearPrestige() {
    final sm = StateManager();
    sm.remove('previous.stores');
    sm.remove('previous.score');
    notifyListeners();
  }

  /// 获取物品继承率描述
  String getInheritanceDescription() {
    return '前一局的物品将以随机比例继承到新游戏中：\n'
           '• 基础资源：保留 10-100%\n'
           '• 武器装备：保留 20-100%\n'
           '• 弹药物品：保留 10-100%';
  }

  /// 计算总继承价值
  int calculateTotalInheritanceValue() {
    final summary = getPreviousStoresSummary();
    int totalValue = 0;

    // 简单的价值计算（可以根据需要调整）
    for (final entry in summary.entries) {
      final storeName = entry.key;
      final amount = entry.value;

      // 根据物品类型给予不同权重
      int weight = 1;
      for (final storeInfo in storesMap) {
        if (storeInfo['store'] == storeName) {
          switch (storeInfo['type']) {
            case 'g':
              weight = 1;
              break;
            case 'w':
              weight = 5;
              break;
            case 'a':
              weight = 2;
              break;
          }
          break;
        }
      }

      totalValue += amount * weight;
    }

    return totalValue;
  }

  /// 重置声望状态（用于新游戏）
  void reset() {
    clearPrestige();
  }
}

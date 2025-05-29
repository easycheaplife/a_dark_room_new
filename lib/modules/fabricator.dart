import 'package:flutter/material.dart';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';

/// 制造器模块 - 注册制造器功能
/// 包括高级物品制造、蓝图系统等功能
class Fabricator extends ChangeNotifier {
  static final Fabricator _instance = Fabricator._internal();

  factory Fabricator() {
    return _instance;
  }

  static Fabricator get instance => _instance;

  Fabricator._internal();

  // 模块名称
  final String name = "制造器";

  // 常量
  static const int storesOffset = 0;

  // 可制造物品配置
  static const Map<String, Map<String, dynamic>> craftables = {
    'energy blade': {
      'name': '能量刃',
      'type': 'weapon',
      'buildMsg': '刀刃嗡嗡作响，带电粒子闪烁着火花。',
      'cost': {'alien alloy': 1}
    },
    'fluid recycler': {
      'name': '流体回收器',
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': '水进水出，物尽其用。',
      'cost': {'alien alloy': 2}
    },
    'cargo drone': {
      'name': '货运无人机',
      'type': 'upgrade',
      'maximum': 1,
      'buildMsg': '流浪者舰队的主力工具。',
      'cost': {'alien alloy': 2}
    },
    'kinetic armour': {
      'name': '动能护甲',
      'type': 'upgrade',
      'maximum': 1,
      'blueprintRequired': true,
      'buildMsg': '流浪者士兵通过转化敌人的愤怒来获得成功。',
      'cost': {'alien alloy': 2}
    },
    'disruptor': {
      'name': '干扰器',
      'type': 'weapon',
      'blueprintRequired': true,
      'buildMsg': '有时最好不要战斗。',
      'cost': {'alien alloy': 1}
    },
    'hypo': {
      'name': '注射器',
      'type': 'tool',
      'blueprintRequired': true,
      'buildMsg': '一把注射器。瓶中的生命。',
      'cost': {'alien alloy': 1},
      'quantity': 5
    },
    'stim': {
      'name': '兴奋剂',
      'type': 'tool',
      'blueprintRequired': true,
      'buildMsg': '有时最好毫无约束地战斗。',
      'cost': {'alien alloy': 1}
    },
    'plasma rifle': {
      'name': '等离子步枪',
      'type': 'weapon',
      'blueprintRequired': true,
      'buildMsg': '流浪者武器技术的巅峰，光滑而致命。',
      'cost': {'alien alloy': 1}
    },
    'glowstone': {
      'name': '发光石',
      'type': 'tool',
      'blueprintRequired': true,
      'buildMsg': '一个光滑完美的球体。它的光芒永不熄灭。',
      'cost': {'alien alloy': 1}
    }
  };

  // 状态变量
  Map<String, dynamic> options = {};

  /// 初始化制造器模块
  void init([Map<String, dynamic>? options]) {
    if (options != null) {
      this.options = {...this.options, ...options};
    }

    final sm = StateManager();

    if (sm.get('features.location.fabricator') == null) {
      sm.set('features.location.fabricator', true);
    }

    updateBuildButtons();
    updateBlueprints();

    notifyListeners();
  }

  /// 到达时调用
  void onArrival([int transitionDiff = 0]) {
    setTitle();
    updateBlueprints(true);

    final sm = StateManager();
    if (sm.get('game.fabricator.seen', true) != true) {
      NotificationManager().notify(name, '熟悉的流浪者机械启动声。终于，真正的工具。');
      sm.set('game.fabricator.seen', true);
    }

    // 播放背景音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicShip);

    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // 在Flutter中，标题设置将通过状态管理处理
    // document.title = "嗡嗡作响的制造器";
  }

  /// 更新建造按钮
  void updateBuildButtons() {
    // 在Flutter中，按钮更新将通过状态管理自动处理
    notifyListeners();
  }

  /// 更新蓝图
  void updateBlueprints([bool ignoreStores = false]) {
    final sm = StateManager();
    if (sm.get('character.blueprints') == null) {
      return;
    }

    // 在Flutter中，蓝图显示将通过状态管理自动更新
    notifyListeners();
  }

  /// 检查是否可以制造
  bool canFabricate(String itemKey) {
    final craftable = craftables[itemKey];
    if (craftable == null) return false;

    final blueprintRequired = craftable['blueprintRequired'] ?? false;
    if (blueprintRequired) {
      final sm = StateManager();
      return sm.get('character.blueprints["$itemKey"]', true) == true;
    }
    return true;
  }

  /// 制造物品
  bool fabricate(String itemKey) {
    final craftable = craftables[itemKey];
    if (craftable == null) return false;

    final sm = StateManager();
    final numThings = max(0, (sm.get('stores["$itemKey"]', true) ?? 0) as int);
    final maximum = craftable['maximum'] as int?;

    if (maximum != null && maximum <= numThings) {
      return false;
    }

    // 检查成本
    final cost = craftable['cost'] as Map<String, dynamic>;
    final storeMod = <String, int>{};

    for (final entry in cost.entries) {
      final required = entry.value as int;
      final have = (sm.get('stores["${entry.key}"]', true) ?? 0) as int;
      if (have < required) {
        NotificationManager().notify(name, '${entry.key}不足');
        return false;
      } else {
        storeMod[entry.key] = have - required;
      }
    }

    // 扣除成本
    for (final entry in storeMod.entries) {
      sm.set('stores["${entry.key}"]', entry.value);
    }

    // 添加物品
    final quantity = (craftable['quantity'] ?? 1) as int;
    sm.add('stores["$itemKey"]', quantity);

    // 显示建造消息
    final buildMsg = craftable['buildMsg'] as String;
    NotificationManager().notify(name, buildMsg);

    // 播放制造音效（暂时注释掉）
    // AudioEngine().playSound(AudioLibrary.craft);

    notifyListeners();
    return true;
  }

  /// 获取可制造物品列表
  List<String> getAvailableItems() {
    final available = <String>[];
    for (final itemKey in craftables.keys) {
      if (canFabricate(itemKey)) {
        available.add(itemKey);
      }
    }
    return available;
  }

  /// 获取物品信息
  Map<String, dynamic>? getItemInfo(String itemKey) {
    return craftables[itemKey];
  }

  /// 检查是否有足够的材料
  bool hasEnoughMaterials(String itemKey) {
    final craftable = craftables[itemKey];
    if (craftable == null) return false;

    final sm = StateManager();
    final cost = craftable['cost'] as Map<String, dynamic>;

    for (final entry in cost.entries) {
      final required = entry.value as int;
      final have = (sm.get('stores["${entry.key}"]', true) ?? 0) as int;
      if (have < required) {
        return false;
      }
    }
    return true;
  }

  /// 获取制造状态
  Map<String, dynamic> getFabricatorStatus() {
    final sm = StateManager();
    final alienAlloy = (sm.get('stores["alien alloy"]', true) ?? 0) as int;
    final blueprints = sm.get('character.blueprints', true) ?? {};

    return {
      'alienAlloy': alienAlloy,
      'blueprints': blueprints,
      'availableItems': getAvailableItems(),
      'seen': sm.get('game.fabricator.seen', true) == true,
    };
  }

  /// 获取蓝图列表
  List<String> getBlueprints() {
    final sm = StateManager();
    final blueprints = sm.get('character.blueprints', true);
    if (blueprints == null) return [];

    final blueprintList = <String>[];
    for (final key in (blueprints as Map).keys) {
      if (blueprints[key] == true) {
        blueprintList.add(key.toString());
      }
    }
    return blueprintList;
  }

  /// 添加蓝图
  void addBlueprint(String itemKey) {
    final sm = StateManager();
    sm.set('character.blueprints["$itemKey"]', true);
    updateBlueprints();
  }

  /// 获取物品类型描述
  String getItemTypeDescription(String type) {
    switch (type) {
      case 'weapon':
        return '武器';
      case 'upgrade':
        return '升级';
      case 'tool':
        return '工具';
      default:
        return '未知';
    }
  }

  /// 获取制造成本描述
  String getCostDescription(String itemKey) {
    final craftable = craftables[itemKey];
    if (craftable == null) return '';

    final cost = craftable['cost'] as Map<String, dynamic>;
    final costParts = <String>[];

    for (final entry in cost.entries) {
      costParts.add('${entry.key} x${entry.value}');
    }

    return costParts.join(', ');
  }

  /// 处理状态更新
  void handleStateUpdates(Map<String, dynamic> event) {
    final category = event['category'];
    final stateName = event['stateName'];

    if (category == 'stores' && stateName?.toString().contains('alien alloy') == true) {
      updateBuildButtons();
    } else if (stateName?.toString().startsWith('character.blueprints') == true) {
      updateBlueprints();
    }

    notifyListeners();
  }

  /// 重置制造器状态（用于新游戏）
  void reset() {
    final sm = StateManager();
    sm.remove('game.fabricator.seen');
    sm.remove('character.blueprints');

    notifyListeners();
  }
}

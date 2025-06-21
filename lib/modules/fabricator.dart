import 'package:flutter/material.dart';
import 'dart:math';
import '../core/state_manager.dart';
import '../core/notifications.dart';
import '../core/localization.dart';

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
  String get name {
    final localization = Localization();
    return localization.translate('ui.modules.fabricator');
  }

  // 常量
  static const int storesOffset = 0;

  // 可制造物品配置
  static const Map<String, Map<String, dynamic>> craftables = {
    'energy blade': {
      'type': 'weapon',
      'cost': {'alien alloy': 1}
    },
    'fluid recycler': {
      'type': 'upgrade',
      'maximum': 1,
      'cost': {'alien alloy': 2}
    },
    'cargo drone': {
      'type': 'upgrade',
      'maximum': 1,
      'cost': {'alien alloy': 2}
    },
    'kinetic armour': {
      'type': 'upgrade',
      'maximum': 1,
      'blueprintRequired': true,
      'cost': {'alien alloy': 2}
    },
    'disruptor': {
      'type': 'weapon',
      'blueprintRequired': true,
      'cost': {'alien alloy': 1}
    },
    'hypo': {
      'type': 'tool',
      'blueprintRequired': true,
      'cost': {'alien alloy': 1},
      'quantity': 5
    },
    'stim': {
      'type': 'tool',
      'blueprintRequired': true,
      'cost': {'alien alloy': 1}
    },
    'plasma rifle': {
      'type': 'weapon',
      'blueprintRequired': true,
      'cost': {'alien alloy': 1}
    },
    'glowstone': {
      'type': 'tool',
      'blueprintRequired': true,
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
      final localization = Localization();
      NotificationManager().notify(name, localization.translate('fabricator.notifications.familiar_wanderer_tech'));
      sm.set('game.fabricator.seen', true);
    }

    // 播放背景音乐（暂时注释掉）
    // AudioEngine().playBackgroundMusic(AudioLibrary.musicShip);

    notifyListeners();
  }

  /// 设置标题
  void setTitle() {
    // 在Flutter中，标题设置将通过状态管理处理
    // final localization = Localization();
    // document.title = localization.translate('ui.modules.fabricator');
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
        final localization = Localization();
        NotificationManager().notify(name, localization.translate('fabricator.notifications.insufficient_resources', [entry.key]));
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
    final localization = Localization();
    final buildMsg = localization.translate('fabricator.descriptions.$itemKey');
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
    final localization = Localization();
    return localization.translate('fabricator.types.$type');
  }

  /// 获取物品名称
  String getItemName(String itemKey) {
    final localization = Localization();
    return localization.translate('fabricator.items.$itemKey');
  }

  /// 获取物品描述
  String getItemDescription(String itemKey) {
    final localization = Localization();
    return localization.translate('fabricator.descriptions.$itemKey');
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

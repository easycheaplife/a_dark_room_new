import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/room.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../widgets/game_button.dart';
import '../widgets/progress_button.dart';

/// 房间界面 - 显示火焰状态、建筑和交易
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<Room, StateManager, Localization>(
      builder: (context, room, stateManager, localization, child) {
        return Container(
          width: 700,
          height: 700,
          color: Colors.white,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 700,
              height: 1000, // 确保有足够的高度支持滚动
              child: Stack(
                children: [
                  // 火焰控制按钮 - 左上角
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _buildFireButtons(room, stateManager),
                  ),

                  // 建造按钮区域 - 原游戏位置: top: 50px, left: 0px
                  Positioned(
                    left: 0,
                    top: 50,
                    child: _buildBuildButtons(room, stateManager),
                  ),

                  // 制作按钮区域 - 原游戏位置: top: 50px, left: 150px
                  Positioned(
                    left: 150,
                    top: 50,
                    child: _buildCraftButtons(room, stateManager),
                  ),

                  // 购买按钮区域 - 原游戏位置: top: 50px, left: 300px
                  Positioned(
                    left: 300,
                    top: 50,
                    child: _buildBuyButtons(room, stateManager),
                  ),

                  // 库存容器 - 原游戏位置: top: 0px, right: 0px
                  Positioned(
                    right: 0,
                    top: 0,
                    child: _buildStoresContainer(stateManager),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 火焰控制按钮
  Widget _buildFireButtons(Room room, StateManager stateManager) {
    final fireValue = stateManager.get('game.fire.value', true) ?? 0;
    final wood = stateManager.get('stores.wood', true) ?? 0;
    final bool isFree = wood == 0;

    return Consumer<Localization>(
      builder: (context, localization, child) {
        // 根据原始游戏逻辑：火焰熄灭时显示点火按钮，否则显示添柴按钮
        if (fireValue == Room.fireEnum['Dead']!['value']) {
          // 火焰熄灭 - 显示点火按钮
          return ProgressButton(
            text: localization.translate('ui.buttons.light_fire'),
            onPressed: () => room.lightFire(),
            cost: isFree ? null : {'wood': 5},
            width: 80,
            free: isFree,
            showCost: true, // 显示成本信息，与原游戏一致
            progressDuration: 10000, // 10秒点火时间，与原游戏一致
          );
        } else {
          // 火焰燃烧 - 显示添柴按钮
          return ProgressButton(
            text: localization.translate('ui.buttons.stoke_fire'),
            onPressed: () => room.stokeFire(),
            cost: isFree ? null : {'wood': 1},
            width: 80,
            free: isFree,
            showCost: true, // 显示成本信息，与原游戏一致
            progressDuration: 10000, // 10秒添柴冷却时间，与原游戏一致
          );
        }
      },
    );
  }

  // 建筑按钮区域
  Widget _buildBuildButtons(Room room, StateManager stateManager) {
    final builderLevel = stateManager.get('game.builder.level', true) ?? -1;

    // 只有当建造者等级 >= 4 时才显示建造按钮
    if (builderLevel < 4) {
      return const SizedBox.shrink();
    }

    return Consumer<Localization>(
      builder: (context, localization, child) {
        return SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 - 模拟原游戏的 data-legend 属性
              Text(
                '${localization.translate('ui.buttons.build')}:',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),

              const SizedBox(height: 5),

              // 建筑按钮列表
              ...room.craftables.entries
                  .where((entry) => entry.value['type'] == 'building')
                  .map((entry) => _buildCraftableButton(
                      entry.key, entry.value, room, stateManager)),
            ],
          ),
        );
      },
    );
  }

  // 制作按钮区域
  Widget _buildCraftButtons(Room room, StateManager stateManager) {
    final hasWorkshop =
        (stateManager.get('game.buildings.workshop', true) ?? 0) > 0;

    // 只有当有工坊时才显示制作按钮
    if (!hasWorkshop) {
      return const SizedBox.shrink();
    }

    return Consumer<Localization>(
      builder: (context, localization, child) {
        return SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 - 模拟原游戏的 data-legend 属性
              Text(
                '${localization.translate('ui.buttons.craft')}:',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),

              const SizedBox(height: 5),

              // 制作按钮列表 - 只显示需要工坊的物品
              ...room.craftables.entries
                  .where((entry) => room.needsWorkshop(entry.value['type']))
                  .map((entry) => _buildCraftableButton(
                      entry.key, entry.value, room, stateManager)),
            ],
          ),
        );
      },
    );
  }

  // 购买按钮区域
  Widget _buildBuyButtons(Room room, StateManager stateManager) {
    final hasTradingPost =
        (stateManager.get('game.buildings.trading post', true) ?? 0) > 0;

    // 只有当有贸易站时才显示购买按钮
    if (!hasTradingPost) {
      return const SizedBox.shrink();
    }

    return Consumer<Localization>(
      builder: (context, localization, child) {
        return SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题 - 模拟原游戏的 data-legend 属性
              Text(
                '${localization.translate('ui.buttons.buy')}:',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),

              const SizedBox(height: 5),

              // 购买按钮列表
              ...room.tradeGoods.entries.map((entry) => _buildTradeButton(
                  entry.key, entry.value, room, stateManager)),
            ],
          ),
        );
      },
    );
  }

  // 资源存储区域
  Widget _buildStoresContainer(StateManager stateManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 库存区域
        _buildStoresDisplay(stateManager),

        const SizedBox(height: 15),

        // 武器区域
        _buildWeaponsDisplay(stateManager),
      ],
    );
  }

  // 库存显示 - 模拟原游戏的 stores 容器
  Widget _buildStoresDisplay(StateManager stateManager) {
    final stores = stateManager.get('stores', true) ?? {};
    final resourceStores = <String, dynamic>{};

    // 过滤出资源类物品（非武器、非升级、非建筑）
    for (var entry in stores.entries) {
      final key = entry.key;
      if (key.contains('blueprint')) continue; // 跳过蓝图

      // 这里需要根据物品类型分类，暂时显示所有非武器物品
      if (!_isWeapon(key)) {
        resourceStores[key] = entry.value;
      }
    }

    if (resourceStores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 - 模拟原游戏的 data-legend 属性
          Container(
            transform: Matrix4.translationValues(8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Consumer<Localization>(
                builder: (context, localization, child) {
                  return Text(
                    localization.translate('ui.menus.stores'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  );
                },
              ),
            ),
          ),

          // 资源列表
          ...resourceStores.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getLocalizedResourceName(entry.key),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // 武器显示 - 模拟原游戏的 weapons 容器
  Widget _buildWeaponsDisplay(StateManager stateManager) {
    final stores = stateManager.get('stores', true) ?? {};
    final weaponStores = <String, dynamic>{};

    // 过滤出武器类物品
    for (var entry in stores.entries) {
      final key = entry.key;
      if (_isWeapon(key)) {
        weaponStores[key] = entry.value;
      }
    }

    if (weaponStores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题 - 模拟原游戏的 data-legend 属性
          Container(
            transform: Matrix4.translationValues(8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Consumer<Localization>(
                builder: (context, localization, child) {
                  return Text(
                    localization.translate('ui.menus.weapons'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  );
                },
              ),
            ),
          ),

          // 武器列表
          ...weaponStores.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getLocalizedWeaponName(entry.key),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // 判断是否为武器
  bool _isWeapon(String itemName) {
    const weapons = [
      'bone spear',
      'iron sword',
      'steel sword',
      'rifle',
      'bolas',
      'grenade',
      'bayonet',
      'laser rifle'
    ];
    return weapons.contains(itemName);
  }

  // 获取本地化资源名称
  String _getLocalizedResourceName(String resourceKey) {
    final localization = Localization();
    // 使用新的翻译逻辑，它会自动尝试所有类别
    String localizedName = localization.translate(resourceKey);
    if (localizedName == resourceKey) {
      // 如果没有找到翻译，使用原名称
      return resourceKey;
    }
    return localizedName;
  }

  // 获取本地化武器名称
  String _getLocalizedWeaponName(String weaponKey) {
    final localization = Localization();
    String localizedName = localization.translate('resources.$weaponKey');
    if (localizedName == 'resources.$weaponKey') {
      // 如果没有找到翻译，使用原名称
      return weaponKey;
    }
    return localizedName;
  }

  // 构建可制作物品按钮
  Widget _buildCraftableButton(String key, Map<String, dynamic> item, Room room,
      StateManager stateManager) {
    // 检查是否解锁
    final isUnlocked = room.craftUnlocked(key);
    if (!isUnlocked) return const SizedBox.shrink();

    // 计算成本
    final costFunction = item['cost'] as Function(StateManager);
    final costResult = costFunction(stateManager);
    final cost = Map<String, int>.from(costResult);

    // 检查是否有足够资源
    bool canAfford = true;
    for (var k in cost.keys) {
      final have = stateManager.get('stores["$k"]', true) ?? 0;
      if (have < cost[k]!) {
        canAfford = false;
        break;
      }
    }

    // 检查是否达到最大数量限制
    bool hasReachedMaximum = false;
    final maximum = item['maximum'];
    if (maximum != null) {
      int currentCount = 0;
      switch (item['type']) {
        case 'building':
          currentCount = stateManager.get('game.buildings["$key"]', true) ?? 0;
          break;
        case 'good':
        case 'weapon':
        case 'tool':
        case 'upgrade':
          currentCount = stateManager.get('stores["$key"]', true) ?? 0;
          break;
      }
      hasReachedMaximum = currentCount >= maximum;
    }

    // 获取本地化名称
    String localizedName = room.getLocalizedName(key);

    // 按钮只有在有足够资源且未达到最大数量时才可用
    final isEnabled = canAfford && !hasReachedMaximum;

    // 生成禁用原因
    String? disabledReason;
    if (!isEnabled) {
      final localization = Localization();
      if (hasReachedMaximum) {
        disabledReason = localization.translate('messages.maximum_reached');
      } else if (!canAfford) {
        disabledReason =
            localization.translate('messages.not_enough_resources');
      }
    }

    return GameButton(
      text: localizedName,
      onPressed: isEnabled ? () => room.buildItem(key) : null,
      cost: cost,
      width: 130,
      disabled: !isEnabled,
      disabledReason: disabledReason,
    );
  }

  // 构建交易物品按钮
  Widget _buildTradeButton(String key, Map<String, dynamic> item, Room room,
      StateManager stateManager) {
    // 检查是否解锁
    final isUnlocked = room.buyUnlocked(key);
    if (!isUnlocked) return const SizedBox.shrink();

    // 计算成本
    final costFunction = item['cost'] as Function(StateManager);
    final costResult = costFunction(stateManager);
    final cost = Map<String, int>.from(costResult);

    // 检查是否有足够资源
    bool canAfford = true;
    for (var k in cost.keys) {
      final have = stateManager.get('stores["$k"]', true) ?? 0;
      if (have < cost[k]!) {
        canAfford = false;
        break;
      }
    }

    // 检查是否达到最大数量限制
    bool hasReachedMaximum = false;
    final maximum = item['maximum'];
    if (maximum != null) {
      final currentCount = stateManager.get('stores["$key"]', true) ?? 0;
      hasReachedMaximum = currentCount >= maximum;
    }

    // 获取本地化名称
    String localizedName = _getLocalizedResourceName(key);

    // 按钮只有在有足够资源且未达到最大数量时才可用
    final isEnabled = canAfford && !hasReachedMaximum;

    // 生成禁用原因
    String? disabledReason;
    if (!isEnabled) {
      final localization = Localization();
      if (hasReachedMaximum) {
        disabledReason = localization.translate('messages.maximum_reached');
      } else if (!canAfford) {
        disabledReason =
            localization.translate('messages.not_enough_resources');
      }
    }

    return GameButton(
      text: localizedName,
      onPressed: isEnabled ? () => room.buyItem(key) : null,
      cost: cost,
      width: 130,
      disabled: !isEnabled,
      disabledReason: disabledReason,
    );
  }
}

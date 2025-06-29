import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization.dart';
import '../core/state_manager.dart';
import '../core/responsive_layout.dart';
import '../modules/fabricator.dart';
import '../widgets/game_button.dart';
import '../widgets/unified_stores_container.dart';
import '../core/logger.dart';

/// 制造器界面 - 显示高级物品制造
/// 参考原游戏 fabricator.js 的实现
class FabricatorScreen extends StatelessWidget {
  const FabricatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Consumer3<Fabricator, StateManager, Localization>(
      builder: (context, fabricator, stateManager, localization, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 库存显示 - 只显示制造器相关的资源
              UnifiedStoresContainer(
                width: layoutParams.gameAreaWidth * 0.8,
              ),

              const SizedBox(height: 20),

              // 蓝图部分
              _buildBlueprintsSection(fabricator, stateManager, localization),

              const SizedBox(height: 20),

              // 制造按钮部分
              _buildFabricateSection(fabricator, stateManager, localization),
            ],
          ),
        );
      },
    );
  }

  /// 构建蓝图部分 - 参考原游戏 updateBlueprints 函数
  Widget _buildBlueprintsSection(Fabricator fabricator, StateManager stateManager, Localization localization) {
    final blueprints = fabricator.getBlueprints();

    if (blueprints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 蓝图标题
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            localization.translate('fabricator.blueprints_title'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // 蓝图列表
        ...blueprints.map((blueprint) => Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          margin: const EdgeInsets.only(bottom: 4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              const Icon(Icons.description, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localization.translate('fabricator.items.$blueprint'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// 构建制造部分 - 参考原游戏 updateBuildButtons 函数
  Widget _buildFabricateSection(Fabricator fabricator, StateManager stateManager, Localization localization) {
    final availableItems = fabricator.getAvailableItems();

    if (availableItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          localization.translate('fabricator.no_items_available'),
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 制造标题
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            localization.translate('fabricator.fabricate_title'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // 制造按钮网格
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: availableItems.map((itemKey) => _buildFabricateButton(
            itemKey,
            fabricator,
            stateManager,
            localization
          )).toList(),
        ),
      ],
    );
  }

  /// 构建单个制造按钮 - 参考原游戏的按钮创建逻辑
  Widget _buildFabricateButton(String itemKey, Fabricator fabricator, StateManager stateManager, Localization localization) {
    final itemInfo = fabricator.getItemInfo(itemKey);
    if (itemInfo == null) return const SizedBox.shrink();

    final hasEnoughMaterials = fabricator.hasEnoughMaterials(itemKey);
    final cost = itemInfo['cost'] as Map<String, dynamic>;
    final quantity = itemInfo['quantity'] ?? 1;

    // 构建物品名称（包含数量）
    String itemName = localization.translate('fabricator.items.$itemKey');
    if (quantity > 1) {
      itemName += ' (x$quantity)';
    }

    return GameButton(
      text: itemName,
      onPressed: hasEnoughMaterials ? () {
        Logger.info('🔧 制造物品: $itemKey');
        final success = fabricator.fabricate(itemKey);
        if (success) {
          Logger.info('🔧 制造成功: $itemKey');
        } else {
          Logger.info('🔧 制造失败: $itemKey');
        }
      } : null,
      width: 150,
      cost: cost.map((key, value) => MapEntry(key, value as int)),
      disabled: !hasEnoughMaterials,
    );
  }
}

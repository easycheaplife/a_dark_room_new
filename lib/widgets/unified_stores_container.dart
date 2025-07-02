import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import '../core/responsive_layout.dart';
import 'stores_display.dart';

/// 统一的库存容器组件 - 用于三个页签的库存显示，确保代码复用和一致性
/// 这个组件统一管理库存、武器和建筑的显示，避免在三个页签中重复相同的代码
class UnifiedStoresContainer extends StatelessWidget {
  /// 是否显示技能区域（仅漫漫尘途页签需要）
  final bool showPerks;

  /// 技能构建函数（可选）
  final Widget Function(StateManager, Localization)? perksBuilder;

  /// 是否显示村庄状态（仅村庄页签需要）
  final bool showVillageStatus;

  /// 村庄状态构建函数（可选）
  final Widget Function(StateManager, Localization)? villageStatusBuilder;

  /// 是否显示建筑（村庄页签显示建筑而不是武器）
  final bool showBuildings;

  /// 自定义宽度（可选，默认200）
  final double? width;

  const UnifiedStoresContainer({
    super.key,
    this.showPerks = false,
    this.perksBuilder,
    this.showVillageStatus = false,
    this.villageStatusBuilder,
    this.showBuildings = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Logger.info(
        '🏪 UnifiedStoresContainer: 构建统一库存容器 - 技能:$showPerks, 村庄:$showVillageStatus');

    return Consumer2<StateManager, Localization>(
      builder: (context, stateManager, localization, child) {
        final layoutParams = GameLayoutParams.getLayoutParams(context);

        return SizedBox(
          width: width ??
              (layoutParams.useVerticalLayout
                  ? double.infinity
                  : 200), // 移动端全宽，桌面端固定宽度
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 根据内容自适应高度，不使用固定高度
            children: [
              // 技能区域（仅漫漫尘途页签显示）
              if (showPerks && perksBuilder != null) ...[
                () {
                  Logger.info('🎯 UnifiedStoresContainer: 显示技能区域');
                  return perksBuilder!(stateManager, localization);
                }(),
              ],

              // 村庄状态区域（仅村庄页签显示）- 调换到库存之前
              if (showVillageStatus && villageStatusBuilder != null) ...[
                () {
                  Logger.info('🏘️ UnifiedStoresContainer: 显示村庄状态区域（建筑）');
                  return villageStatusBuilder!(stateManager, localization);
                }(),
                const SizedBox(height: 15), // 与其他区域保持一致的间距
              ],

              // 库存区域 - 使用light样式，只显示资源
              const StoresDisplay(
                style: StoresDisplayStyle.light,
                type: StoresDisplayType.resourcesOnly,
                collapsible: false,
                showIncomeInfo: false,
                customTitle: null, // 使用默认标题
              ),

              const SizedBox(height: 15), // 统一的间距

              // 武器区域 - 只有非村庄页签显示武器
              if (!showBuildings) ...[
                Consumer<Localization>(
                  builder: (context, localization, child) {
                    return StoresDisplay(
                      style: StoresDisplayStyle.light,
                      type: StoresDisplayType.weaponsOnly,
                      collapsible: false,
                      showIncomeInfo: false,
                      customTitle: localization.translate('ui.menus.weapons'),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

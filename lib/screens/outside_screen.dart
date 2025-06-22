import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/outside.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';
import '../widgets/progress_button.dart';
import '../widgets/stores_display.dart';

/// 外部界面 - 显示村庄状态、建筑和工人管理
/// 使用与房间界面一致的UI风格
class OutsideScreen extends StatelessWidget {
  const OutsideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Consumer3<Outside, StateManager, Localization>(
      builder: (context, outside, stateManager, localization, child) {
        return Container(
          width: layoutParams.gameAreaWidth,
          height: layoutParams.gameAreaHeight,
          color: Colors.white,
          padding: layoutParams.contentPadding,
          child: SingleChildScrollView(
            child: layoutParams.useVerticalLayout
                ? _buildMobileLayout(context, outside, stateManager, localization, layoutParams)
                : _buildDesktopLayout(context, outside, stateManager, localization, layoutParams),
          ),
        );
      },
    );
  }

  /// 移动设备垂直布局
  Widget _buildMobileLayout(BuildContext context, Outside outside, StateManager stateManager,
      Localization localization, GameLayoutParams layoutParams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 收集木材按钮区域
        _buildGatheringButtons(outside, stateManager, layoutParams),

        SizedBox(height: layoutParams.buttonSpacing),

        // 右侧信息栏 - 移动端放在上方
        _buildRightInfoPanel(outside, stateManager, layoutParams),

        SizedBox(height: layoutParams.buttonSpacing * 2),

        // 工人管理区域
        Consumer<Localization>(
          builder: (context, localization, child) {
            return _buildWorkersButtons(outside, stateManager, localization, layoutParams);
          },
        ),
      ],
    );
  }

  /// 桌面/Web水平布局（保持原有设计）
  Widget _buildDesktopLayout(BuildContext context, Outside outside, StateManager stateManager,
      Localization localization, GameLayoutParams layoutParams) {
    return SizedBox(
      width: 700,
      height: 1000, // 确保有足够的高度支持滚动
      child: Stack(
        children: [
          // 收集木材按钮区域 - 左上角
          Positioned(
            left: 10,
            top: 10,
            child: _buildGatheringButtons(outside, stateManager, layoutParams),
          ),

          // 工人管理区域 - 居中于伐木按钮和库存之间
          Positioned(
            left: 250, // 调整位置，避免与伐木按钮重叠
            top: 10,
            child: Consumer<Localization>(
              builder: (context, localization, child) {
                return _buildWorkersButtons(outside, stateManager, localization, layoutParams);
              },
            ),
          ),

          // 右侧信息栏 - 参考房间界面的库存和武器布局
          Positioned(
            right: 0,
            top: 0,
            child: _buildRightInfoPanel(outside, stateManager, layoutParams),
          ),
        ],
      ),
    );
  }

  // 收集木材按钮区域
  Widget _buildGatheringButtons(Outside outside, StateManager stateManager, GameLayoutParams layoutParams) {
    final numTraps = stateManager.get('game.buildings.trap', true) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 伐木按钮
        Consumer<Localization>(
          builder: (context, localization, child) {
            return ProgressButton(
              text: localization.translate('ui.buttons.gather_wood'),
              onPressed: () => outside.gatherWood(),
              width: layoutParams.buttonWidth,
              progressDuration: 1000, // 1秒收集时间
            );
          },
        ),

        // 如果有陷阱，显示检查陷阱按钮
        if (numTraps > 0) ...[
          const SizedBox(height: 10), // 垂直间距
          Consumer<Localization>(
            builder: (context, localization, child) {
              return ProgressButton(
                text: localization.translate('ui.buttons.check_traps'),
                onPressed: () => outside.checkTraps(),
                width: layoutParams.buttonWidth,
                progressDuration: 1500, // 1.5秒检查时间
              );
            },
          ),
        ],
      ],
    );
  }

  // 右侧信息栏 - 参考房间界面的库存和武器布局方式
  Widget _buildRightInfoPanel(Outside outside, StateManager stateManager, GameLayoutParams layoutParams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 库存区域 - 与房间界面相同的配置
        const StoresDisplay(
          style: StoresDisplayStyle.light,
          type: StoresDisplayType.resourcesOnly,
          collapsible: false,
          showIncomeInfo: false,
        ),

        const SizedBox(height: 15), // 与房间界面相同的间距

        // 村庄状态区域 - 排在库存下面
        _buildVillageStatus(outside, stateManager, layoutParams),
      ],
    );
  }

  // 村庄状态区域 - 模拟原游戏的 village 容器
  Widget _buildVillageStatus(Outside outside, StateManager stateManager, GameLayoutParams layoutParams) {
    final numHuts = stateManager.get('game.buildings.hut', true) ?? 0;

    // 如果没有小屋，不显示村庄状态
    if (numHuts == 0) {
      return const SizedBox.shrink();
    }

    return Consumer<Localization>(
      builder: (context, localization, child) {
        return _VillageWidget(
          outside: outside,
          stateManager: stateManager,
          localization: localization,
        );
      },
    );
  }

  // 工人管理区域 - 模拟原游戏的 workers 容器
  Widget _buildWorkersButtons(
      Outside outside, StateManager stateManager, Localization localization, GameLayoutParams layoutParams) {
    final population = stateManager.get('game.population', true) ?? 0;

    // 如果没有人口，不显示工人管理
    if (population == 0) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: layoutParams.useVerticalLayout ? layoutParams.gameAreaWidth : 200, // 进一步增加宽度，确保不重叠
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工人管理按钮
          _buildWorkerButton(localization.translate('workers.gatherer'),
              'gatherer', outside, stateManager, localization, layoutParams),
          _buildWorkerButton(localization.translate('workers.hunter'), 'hunter',
              outside, stateManager, localization, layoutParams),
          _buildWorkerButton(localization.translate('workers.trapper'),
              'trapper', outside, stateManager, localization, layoutParams),
          _buildWorkerButton(localization.translate('workers.tanner'), 'tanner',
              outside, stateManager, localization, layoutParams),
          _buildWorkerButton(localization.translate('workers.charcutier'),
              'charcutier', outside, stateManager, localization, layoutParams),
          _buildWorkerButton(localization.translate('workers.steelworker'),
              'steelworker', outside, stateManager, localization, layoutParams),
        ],
      ),
    );
  }

  // 构建工人按钮 - 模拟原游戏的 workerRow 样式
  Widget _buildWorkerButton(String name, String type, Outside outside,
      StateManager stateManager, Localization localization, GameLayoutParams layoutParams) {
    final currentWorkers = stateManager.get('game.workers["$type"]', true) ?? 0;
    final population = stateManager.get('game.population', true) ?? 0;
    final totalWorkers = stateManager
            .get('game.workers', true)
            ?.values
            .fold(0, (sum, count) => sum + count) ??
        0;
    final availableWorkers = population - totalWorkers;

    // 检查是否有相应的建筑物解锁此工人类型
    bool isUnlocked = _isWorkerUnlocked(type, stateManager);
    if (!isUnlocked) {
      return const SizedBox.shrink();
    }

    // 获取工人的生产/消耗信息
    final workerInfo =
        _getWorkerInfo(type, currentWorkers, availableWorkers, localization);

    // 对于伐木者，显示剩余人口数量，不显示调整按钮
    if (type == 'gatherer') {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8), // 增加内边距，减少拥挤
        child: Tooltip(
          message: workerInfo,
          child: Row(
            children: [
              // 工人名称
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: layoutParams.fontSize,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
              // 显示剩余人口数量（伐木者数量）- 右对齐
              Container(
                width: 70, // 与其他工人按钮宽度一致
                alignment: Alignment.centerRight,
                child: Text(
                  '$availableWorkers',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: layoutParams.fontSize,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8), // 增加内边距，与代木者保持一致
      child: Tooltip(
        message: workerInfo,
        child: Row(
          children: [
            // 工人名称和数量
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: layoutParams.fontSize,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),

            // 工人数量和控制按钮 - 修复溢出问题
            SizedBox(
              width: 70, // 进一步增加宽度，避免溢出
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$currentWorkers',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: layoutParams.fontSize,
                      fontFamily: 'Times New Roman',
                    ),
                  ),

                  const SizedBox(width: 4), // 适当间距

                  // 减少按钮
                  _buildWorkerControlButton(
                    '▼',
                    currentWorkers > 0
                        ? () => outside.decreaseWorker(type, 1)
                        : null,
                  ),

                  const SizedBox(width: 1), // 最小间距

                  // 增加按钮
                  _buildWorkerControlButton(
                    '▲',
                    availableWorkers > 0
                        ? () => outside.increaseWorker(type, 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建工人控制按钮 - 模拟原游戏的上下箭头按钮
  Widget _buildWorkerControlButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: 14,
      height: 12,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: onPressed != null ? Colors.black : Colors.grey),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: onPressed != null ? Colors.black : Colors.grey,
                fontSize: 8,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 检查工人类型是否已解锁
  bool _isWorkerUnlocked(String type, StateManager stateManager) {
    switch (type) {
      case 'gatherer':
        return true; // 伐木者总是可用
      case 'hunter':
        return (stateManager.get('game.buildings.lodge', true) ?? 0) > 0;
      case 'trapper':
        return (stateManager.get('game.buildings.lodge', true) ?? 0) >
            0; // 陷阱师也由狩猎小屋解锁
      case 'tanner':
        return (stateManager.get('game.buildings.tannery', true) ?? 0) > 0;
      case 'charcutier':
        return (stateManager.get('game.buildings.smokehouse', true) ?? 0) >
            0; // 熏肉师由熏肉房解锁
      case 'steelworker':
        return (stateManager.get('game.buildings.steelworks', true) ?? 0) > 0;
      default:
        return false;
    }
  }

  // 获取工人的生产/消耗信息
  String _getWorkerInfo(String type, int currentWorkers, int availableWorkers,
      [Localization? localization]) {
    // 基于原游戏的收入配置
    const incomeConfig = {
      'gatherer': {
        'delay': 10,
        'stores': {'wood': 1}
      },
      'hunter': {
        'delay': 10,
        'stores': {'fur': 0.5, 'meat': 0.5}
      },
      'trapper': {
        'delay': 10,
        'stores': {'meat': -1, 'bait': 1}
      },
      'tanner': {
        'delay': 10,
        'stores': {'fur': -5, 'leather': 1}
      },
      'charcutier': {
        'delay': 10,
        'stores': {'meat': -5, 'wood': -5, 'cured meat': 1}
      },
      'steelworker': {
        'delay': 10,
        'stores': {'coal': -1, 'iron': -1, 'steel': 1}
      },
    };

    final config = incomeConfig[type];
    if (config == null) return '';

    final stores = config['stores'] as Map<String, dynamic>;
    final delay = config['delay'] as int;

    List<String> effects = [];

    // 计算当前工人的效果
    if (type == 'gatherer') {
      final totalProduction = availableWorkers * (stores['wood'] as num);
      if (totalProduction > 0) {
        final producesText =
            localization?.translate('worker_info.produces') ?? 'produces';
        final everyText = localization?.translate('worker_info.every') ?? 'every';
        final secondsText =
            localization?.translate('worker_info.seconds') ?? 'seconds';
        final woodText = localization?.translate('resources.wood') ?? 'wood';
        effects.add(
            '$producesText: +${totalProduction.toStringAsFixed(1)} $woodText $everyText$delay$secondsText');
      }
    } else {
      for (final entry in stores.entries) {
        final resource = entry.key;
        final rate = entry.value as num;
        final totalRate = currentWorkers * rate;

        if (totalRate != 0) {
          final resourceName =
              localization?.translate('resources.$resource') ?? resource;
          final prefix = totalRate > 0 ? '+' : '';
          final actionText = totalRate > 0
              ? (localization?.translate('worker_info.produces') ?? 'produces')
              : (localization?.translate('worker_info.consumes') ?? 'consumes');
          final everyText = localization?.translate('worker_info.every') ?? 'every';
          final secondsText =
              localization?.translate('worker_info.seconds') ?? 'seconds';
          effects.add(
              '$actionText: $prefix${totalRate.toStringAsFixed(1)} $resourceName $everyText$delay$secondsText');
        }
      }
    }

    if (effects.isEmpty) {
      return localization?.translate('worker_info.no_production') ?? 'no production/consumption';
    }

    return effects.join('\n');
  }

}

// 可折叠的村庄状态显示组件
class _VillageWidget extends StatefulWidget {
  final Outside outside;
  final StateManager stateManager;
  final Localization localization;

  const _VillageWidget({
    required this.outside,
    required this.stateManager,
    required this.localization,
  });

  @override
  State<_VillageWidget> createState() => _VillageWidgetState();
}

class _VillageWidgetState extends State<_VillageWidget> {
  @override
  Widget build(BuildContext context) {
    final population = widget.stateManager.get('game.population', true) ?? 0;
    final villageTitle = widget.outside.getTitle(); // 这会根据小屋数量动态变化

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 村庄标题栏 - 不可点击，与库存显示风格一致
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    // 村庄标题 - 模拟原游戏的 data-legend 属性
                    Container(
                      transform: Matrix4.translationValues(-8, -13, 0),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          villageTitle,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 建筑物列表 - 始终显示
              Container(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildBuildingsList(),
                ),
              ),
            ],
          ),

          // 人口显示 - 与村庄标题在同一水平线上，右侧位置
          Positioned(
            top: -3,
            right: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '${widget.localization.translate('ui.status.population')} $population/${widget.outside.getMaxPopulation()}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建建筑物列表
  List<Widget> _buildBuildingsList() {
    final List<Widget> buildings = [];
    final gameBuildings = widget.stateManager.get('game.buildings', true) ?? {};

    for (final entry in gameBuildings.entries) {
      final buildingName = entry.key;
      final buildingCount = entry.value as int;

      if (buildingCount > 0) {
        if (buildingName == 'trap') {
          // 陷阱特殊处理：显示有饵料和无饵料的陷阱
          final numBait = widget.stateManager.get('stores.bait', true) ?? 0;
          final baitedTraps =
              (numBait < buildingCount) ? numBait : buildingCount;
          final unbaitedTraps = buildingCount - baitedTraps;

          if (unbaitedTraps > 0) {
            buildings.add(
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${widget.localization.translate('buildings.trap')}: $unbaitedTraps',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
            );
          }

          if (baitedTraps > 0) {
            buildings.add(
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '${widget.localization.translate('buildings.baited_trap')}: $baitedTraps',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ),
            );
          }
        } else {
          // 其他建筑物的显示
          String localizedName = _getBuildingLocalizedName(buildingName);
          buildings.add(
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '$localizedName: $buildingCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          );
        }
      }
    }

    return buildings;
  }

  // 获取建筑物的本地化名称
  String _getBuildingLocalizedName(String buildingName) {
    final translatedName =
        widget.localization.translate('buildings.$buildingName');

    // 如果翻译存在且不等于原键名，返回翻译
    if (translatedName != 'buildings.$buildingName') {
      return translatedName;
    }

    // 否则返回原名称
    return buildingName;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state_manager.dart';
import '../core/localization.dart';
import '../core/responsive_layout.dart';
import '../utils/weapon_utils.dart';

/// 库存显示样式枚举
enum StoresDisplayStyle {
  /// 黑色背景样式（原始样式）
  dark,

  /// 白色背景带边框样式（房间和外部界面）
  light,
}

/// 库存显示类型枚举
enum StoresDisplayType {
  /// 显示所有物品
  all,

  /// 只显示资源（非武器）
  resourcesOnly,

  /// 只显示武器
  weaponsOnly,
}

/// 统一的库存显示组件 - 支持不同样式和类型
class StoresDisplay extends StatefulWidget {
  /// 显示样式
  final StoresDisplayStyle style;

  /// 显示类型
  final StoresDisplayType type;

  /// 是否可折叠
  final bool collapsible;

  /// 初始展开状态（仅在可折叠时有效）
  final bool initiallyExpanded;

  /// 自定义宽度
  final double? width;

  /// 自定义标题
  final String? customTitle;

  /// 是否显示收入信息（tooltip）
  final bool showIncomeInfo;

  const StoresDisplay({
    super.key,
    this.style = StoresDisplayStyle.dark,
    this.type = StoresDisplayType.all,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.width,
    this.customTitle,
    this.showIncomeInfo = false,
  });

  @override
  State<StoresDisplay> createState() => _StoresDisplayState();
}

class _StoresDisplayState extends State<StoresDisplay> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StateManager, Localization>(
      builder: (context, stateManager, localization, child) {
        // 从StateManager获取实际的资源数据
        final storesData = stateManager.get('stores');
        final stores = (storesData is Map<String, dynamic>)
            ? storesData
            : <String, dynamic>{};

        final resources = <String, num>{};
        final weapons = <String, num>{};
        final special = <String, num>{};

        // 分类资源 - 参考原游戏：只显示数量大于0的资源
        for (final entry in stores.entries) {
          final value = entry.value as num? ?? 0;

          // 参考原游戏逻辑：只显示数量大于0的资源
          if (value <= 0) {
            continue;
          }

          // 根据显示类型过滤
          if (widget.type == StoresDisplayType.weaponsOnly &&
              !_isWeapon(entry.key)) {
            continue;
          }
          if (widget.type == StoresDisplayType.resourcesOnly &&
              _isWeapon(entry.key)) {
            continue;
          }

          switch (entry.key) {
            case 'wood':
            case 'fur':
            case 'meat':
            case 'bait':
            case 'leather':
            case 'cured meat':
            case 'iron':
            case 'coal':
            case 'sulphur':
            case 'steel':
            case 'bullets':
            case 'scales':
            case 'teeth':
            case 'medicine':
            case 'energy cell':
            case 'alien alloy':
            case 'cloth':
              resources[entry.key] = value;
              break;
            case 'iron sword':
            case 'steel sword':
            case 'rifle':
            case 'bone spear':
            case 'bolas':
            case 'grenade':
            case 'bayonet':
            case 'laser rifle':
              weapons[entry.key] = value;
              break;
            case 'compass':
              special[entry.key] = value;
              break;
            case 'torch':
            case 'waterskin':
            case 'cask':
            case 'water tank':
            case 'rucksack':
            case 'wagon':
            case 'convoy':
            case 'l armour':
            case 'i armour':
            case 's armour':
              special[entry.key] = value;
              break;
          }
        }

        // 根据显示类型决定显示哪些分类
        final showResources = widget.type != StoresDisplayType.weaponsOnly &&
            resources.isNotEmpty;
        final showWeapons = widget.type != StoresDisplayType.resourcesOnly &&
            weapons.isNotEmpty;
        // Special物品在resourcesOnly模式下也应该显示（如指南针等）
        final showSpecial =
            widget.type != StoresDisplayType.weaponsOnly && special.isNotEmpty;

        // 如果没有任何物品，不显示
        if (!showResources && !showWeapons && !showSpecial) {
          return const SizedBox.shrink();
        }

        return _buildContainer(
          stateManager,
          localization,
          showResources ? resources : {},
          showWeapons ? weapons : {},
          showSpecial ? special : {},
        );
      },
    );
  }

  /// 构建容器
  Widget _buildContainer(
    StateManager stateManager,
    Localization localization,
    Map<String, num> resources,
    Map<String, num> weapons,
    Map<String, num> special,
  ) {
    final isLight = widget.style == StoresDisplayStyle.light;
    final backgroundColor = isLight ? Colors.white : Colors.black;
    final textColor = isLight ? Colors.black : Colors.white;
    final layoutParams = GameLayoutParams.getLayoutParams(context);
    final containerWidth = widget.width ??
        (layoutParams.useVerticalLayout ? double.infinity : 200.0); // 移动端全宽

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题部分
        _buildTitle(localization, textColor),

        // 内容部分（可折叠）
        if (!widget.collapsible || _isExpanded) ...[
          _buildContent(stateManager, localization, resources, weapons, special,
              textColor),
        ],
      ],
    );

    if (isLight) {
      return Container(
        width: containerWidth,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.black),
        ),
        child: content,
      );
    } else {
      return Container(
        width: containerWidth,
        color: backgroundColor,
        child: content,
      );
    }
  }

  /// 构建标题
  Widget _buildTitle(Localization localization, Color textColor) {
    final title = widget.customTitle ?? _getDefaultTitle(localization);
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    if (!widget.collapsible) {
      // 不可折叠的标题
      if (widget.style == StoresDisplayStyle.light) {
        return Container(
          padding: EdgeInsets.all(
              layoutParams.useVerticalLayout ? 8 : 10), // 移动端减少内边距
          child: Container(
            transform: Matrix4.translationValues(8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: layoutParams.useVerticalLayout ? 14 : 16, // 移动端减小字体
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
          ),
        );
      } else {
        return Padding(
          padding: EdgeInsets.all(
              layoutParams.useVerticalLayout ? 6 : 8), // 移动端减少内边距
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: layoutParams.useVerticalLayout ? 14 : 16, // 移动端减小字体
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    } else {
      // 可折叠的标题
      return InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          child: Container(
            transform: Matrix4.translationValues(8, -13, 0),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  /// 构建内容
  Widget _buildContent(
    StateManager stateManager,
    Localization localization,
    Map<String, num> resources,
    Map<String, num> weapons,
    Map<String, num> special,
    Color textColor,
  ) {
    final isLight = widget.style == StoresDisplayStyle.light;
    final layoutParams = GameLayoutParams.getLayoutParams(context);
    final padding = isLight
        ? EdgeInsets.fromLTRB(
            layoutParams.useVerticalLayout ? 8 : 10, // 移动端减少左右内边距
            0,
            layoutParams.useVerticalLayout ? 8 : 10, // 移动端减少左右内边距
            layoutParams.useVerticalLayout ? 8 : 10 // 移动端减少底部内边距
            )
        : EdgeInsets.symmetric(
            horizontal: layoutParams.useVerticalLayout ? 12 : 16, // 移动端减少水平内边距
            vertical: layoutParams.useVerticalLayout ? 3 : 4 // 移动端减少垂直内边距
            );

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resources
          if (resources.isNotEmpty) ...[
            if (widget.type == StoresDisplayType.all && !isLight) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  localization.translate('resources.title'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ...resources.entries.map((entry) => _buildResourceRow(
                stateManager, entry.key, entry.value, localization, textColor)),
          ],

          // Special items
          if (special.isNotEmpty) ...[
            if (widget.type == StoresDisplayType.all && !isLight) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  localization.translate('ui.menus.special_items'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ...special.entries.map((entry) => _buildResourceRow(
                stateManager, entry.key, entry.value, localization, textColor)),
          ],

          // Weapons
          if (weapons.isNotEmpty) ...[
            if (widget.type == StoresDisplayType.all && !isLight) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  localization.translate('ui.menus.weapons'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ...weapons.entries.map((entry) => _buildResourceRow(
                stateManager, entry.key, entry.value, localization, textColor)),
          ],
        ],
      ),
    );
  }

  /// 构建资源行
  Widget _buildResourceRow(
    StateManager stateManager,
    String name,
    num value,
    Localization localization,
    Color textColor,
  ) {
    // 获取本地化的资源名称
    String localizedName = localization.translate('resources.$name');
    if (localizedName == 'resources.$name') {
      // 如果没有找到翻译，使用原名称
      localizedName = name;
    }

    final isLight = widget.style == StoresDisplayStyle.light;
    final layoutParams = GameLayoutParams.getLayoutParams(context);
    final fontSize = isLight
        ? (layoutParams.useVerticalLayout ? 14.0 : 16.0) // 移动端减小字体
        : (layoutParams.useVerticalLayout ? 12.0 : 14.0); // 移动端减小字体
    final fontFamily = isLight ? 'Times New Roman' : null;

    Widget row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localizedName,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        ),
        Text(
          value.floor().toString(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        ),
      ],
    );

    // 如果需要显示收入信息，添加tooltip
    if (widget.showIncomeInfo) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Tooltip(
          message: _getResourceIncomeInfo(stateManager, localization, name),
          child: row,
        ),
      );
    } else {
      return Padding(
        padding: isLight
            ? const EdgeInsets.only(bottom: 2)
            : const EdgeInsets.symmetric(vertical: 4),
        child: row,
      );
    }
  }

  /// 获取默认标题
  String _getDefaultTitle(Localization localization) {
    switch (widget.type) {
      case StoresDisplayType.all:
        return localization.translate('resources.title');
      case StoresDisplayType.resourcesOnly:
        return localization.translate('resources.title');
      case StoresDisplayType.weaponsOnly:
        return localization.translate('ui.menus.weapons');
    }
  }

  /// 判断是否为武器
  bool _isWeapon(String itemName) {
    return WeaponUtils.isWeapon(itemName);
  }

  /// 获取资源的收入信息
  String _getResourceIncomeInfo(StateManager stateManager,
      Localization localization, String resourceKey) {
    final income = stateManager.get('income', true) ?? {};
    List<String> effects = [];

    // 遍历所有收入来源，查找影响此资源的
    for (final entry in income.entries) {
      final sourceName = entry.key;
      final incomeData = entry.value;
      final stores = incomeData['stores'] as Map<String, dynamic>? ?? {};
      final delay = incomeData['delay'] as int? ?? 10;

      if (stores.containsKey(resourceKey)) {
        final rate = stores[resourceKey] as num;
        if (rate != 0) {
          final sourceDisplayName =
              _getWorkerDisplayName(localization, sourceName);
          final prefix = rate > 0 ? '+' : '';
          final everyText = localization.translate('worker_info.every');
          final secondsText = localization.translate('worker_info.seconds');
          effects.add(
              '$sourceDisplayName: $prefix${rate.toStringAsFixed(1)} $everyText$delay$secondsText');
        }
      }
    }

    if (effects.isEmpty) {
      return localization.translate('worker_info.no_production');
    }

    // 计算总计
    double totalRate = 0;
    int commonDelay = 10;
    for (final entry in income.entries) {
      final incomeData = entry.value;
      final stores = incomeData['stores'] as Map<String, dynamic>? ?? {};
      if (stores.containsKey(resourceKey)) {
        totalRate += (stores[resourceKey] as num).toDouble();
      }
    }

    if (totalRate != 0) {
      final prefix = totalRate > 0 ? '+' : '';
      final totalText = localization.translate('worker_info.total');
      final everyText = localization.translate('worker_info.every');
      final secondsText = localization.translate('worker_info.seconds');
      effects.add(
          '$totalText: $prefix${totalRate.toStringAsFixed(1)} $everyText$commonDelay$secondsText');
    }

    return effects.join('\n');
  }

  /// 获取工人显示名称
  String _getWorkerDisplayName(Localization localization, String workerKey) {
    return localization.translate('workers.$workerKey');
  }
}

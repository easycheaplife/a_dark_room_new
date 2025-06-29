import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/state_manager.dart';
import '../modules/ship.dart';
import '../widgets/unified_stores_container.dart';

/// 飞船界面 - 显示飞船状态和升级选项
class ShipScreen extends StatefulWidget {
  const ShipScreen({super.key});

  @override
  State<ShipScreen> createState() => _ShipScreenState();
}

class _ShipScreenState extends State<ShipScreen> {
  late Ship _ship;
  late StateManager _stateManager;

  @override
  void initState() {
    super.initState();
    _ship = Ship();
    _stateManager = StateManager();

    // 监听状态变化
    _ship.addListener(_onShipStateChanged);
    _stateManager.addListener(_onStateChanged);

    // 确保Ship模块已初始化
    _ship.init();

    // 调用onArrival
    _ship.onArrival();
  }

  @override
  void dispose() {
    _ship.removeListener(_onShipStateChanged);
    _stateManager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onShipStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = Localization();
    final shipStatus = _ship.getShipStatus();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SingleChildScrollView(
        // 添加整个页面的滚动支持
        child: SizedBox(
          width: double.infinity,
          height: 800, // 设置足够的高度以容纳所有内容
          child: Stack(
            children: [
              // 左侧：飞船状态和操作按钮区域 - 绝对定位，与漫漫尘途保持一致
              Positioned(
                left: 10,
                top: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 飞船状态显示区域
                    _buildShipStatusSection(localization, shipStatus),

                    const SizedBox(height: 20),

                    // 飞船操作按钮区域
                    _buildShipActionsSection(localization, shipStatus),
                  ],
                ),
              ),

              // 库存容器 - 绝对定位，与漫漫尘途完全一致的位置: top: 0px, right: 0px
              Positioned(
                right: 0,
                top: 0,
                child: _buildStoresContainer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 飞船状态显示区域 - 参考漫漫尘途页签的装备区域样式
  Widget _buildShipStatusSection(Localization localization, Map<String, dynamic> shipStatus) {
    return Container(
      width: 300, // 固定宽度，与漫漫尘途装备区域保持一致
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1), // 与原游戏保持一致的边框样式
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题 - 模拟原游戏的 data-legend 属性
              Container(
                transform: Matrix4.translationValues(-8, -13, 0),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    localization.translate('ship.status.title'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 船体状态
              _buildStatusRow(
                localization.translate('ship.status.hull'),
                '${shipStatus['hull']}',
              ),

              const SizedBox(height: 8),

              // 引擎状态
              _buildStatusRow(
                localization.translate('ship.status.engine'),
                '${shipStatus['thrusters']}',
              ),

              const SizedBox(height: 8),

              // 飞船描述
              Text(
                _ship.getShipDescription(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 状态行显示 - 参考原游戏风格
  Widget _buildStatusRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70, // 与原游戏保持一致的宽度
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman',
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Times New Roman',
          ),
        ),
      ],
    );
  }

  // 飞船操作按钮区域 - 参考漫漫尘途页签的出发按钮样式
  Widget _buildShipActionsSection(Localization localization, Map<String, dynamic> shipStatus) {
    return SizedBox(
      width: 300, // 与状态区域保持一致的宽度
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 强化船体按钮
          _buildActionButton(
            text: localization.translate('ship.actions.reinforce_hull'),
            onPressed: shipStatus['canReinforceHull'] ? () => _ship.reinforceHull() : null,
            cost: '${localization.translate('ship.costs.alien_alloy_label')}: ${Ship.alloyPerHull}',
            enabled: shipStatus['canReinforceHull'],
          ),

          const SizedBox(height: 12),

          // 升级引擎按钮
          _buildActionButton(
            text: localization.translate('ship.actions.upgrade_engine'),
            onPressed: shipStatus['canUpgradeEngine'] ? () => _ship.upgradeEngine() : null,
            cost: '${localization.translate('ship.costs.alien_alloy_label')}: ${Ship.alloyPerThruster}',
            enabled: shipStatus['canUpgradeEngine'],
          ),

          const SizedBox(height: 12),

          // 起飞按钮
          _buildActionButton(
            text: localization.translate('ship.actions.lift_off'),
            onPressed: shipStatus['canLiftOff'] ? () => _ship.checkLiftOff() : null,
            cost: shipStatus['canLiftOff'] ? '' : localization.translate('ship.requirements.hull_needed'),
            enabled: shipStatus['canLiftOff'],
            isSpecial: true,
          ),
        ],
      ),
    );
  }

  // 构建操作按钮 - 参考原游戏风格
  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    required String cost,
    required bool enabled,
    bool isSpecial = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? Colors.white : Colors.grey[300],
              foregroundColor: enabled ? Colors.black : Colors.grey[600],
              side: BorderSide(
                color: enabled ? Colors.black : Colors.grey[500]!,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0), // 方形按钮，符合原游戏风格
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),
          if (cost.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                cost,
                style: TextStyle(
                  color: enabled ? Colors.black : Colors.grey[600],
                  fontSize: 12,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 库存显示区域 - 与小黑屋保持一致
  Widget _buildStoresContainer() {
    return const UnifiedStoresContainer(
      showPerks: false,
      showVillageStatus: false,
    );
  }
}

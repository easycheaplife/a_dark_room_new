import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../modules/space.dart';
import '../modules/ship.dart';
import '../core/localization.dart';
import '../core/logger.dart';
import '../core/state_manager.dart';
import '../core/engine.dart';
import '../core/responsive_layout.dart';
import '../widgets/game_ending_dialog.dart';

/// 太空界面 - 显示太空飞行和小行星躲避游戏
class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  late Space _space;

  @override
  void initState() {
    super.initState();
    _space = Space();

    // 监听状态变化
    _space.addListener(_onSpaceStateChanged);

    Logger.info('🚀 SpaceScreen initialized');
  }

  @override
  void dispose() {
    _space.removeListener(_onSpaceStateChanged);
    super.dispose();
  }

  void _onSpaceStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Space>(
      builder: (context, space, child) {
        // 检查是否需要显示结束对话框或切换页签
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final stateManager =
              Provider.of<StateManager>(context, listen: false);
          _checkShowEndingDialog(context, stateManager);
          _checkSwitchToShip(context, stateManager);
        });

        return GestureDetector(
          onTap: () {
            // 确保Focus获得焦点
            FocusScope.of(context).requestFocus();
          },
          child: Focus(
            autofocus: true,
            canRequestFocus: true,
            onKeyEvent: (node, event) => _handleKeyEvent(space, event),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black, // 太空背景
              child: Stack(
                children: [
                  // 星空背景
                  _buildStarField(space),

                  // 小行星
                  ..._buildAsteroids(space),

                  // 飞船
                  _buildShip(space),

                  // UI界面
                  Consumer<Localization>(
                    builder: (context, localization, child) =>
                        _buildUI(space, localization),
                  ),

                  // APK版本的方向控制按钮
                  if (!kIsWeb) _buildDirectionControls(space),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 处理键盘事件
  KeyEventResult _handleKeyEvent(Space space, KeyEvent event) {
    // 使用正确的键盘事件类型检查
    if (event is KeyDownEvent) {
      space.keyDown(event.logicalKey);
      Logger.info('🎮 按键按下: ${event.logicalKey}');
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      space.keyUp(event.logicalKey);
      Logger.info('🎮 按键释放: ${event.logicalKey}');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 检查是否需要显示结束对话框
  void _checkShowEndingDialog(BuildContext context, StateManager stateManager) {
    final shouldShowDialog =
        stateManager.get('game.showEndingDialog', true) == true;
    if (shouldShowDialog) {
      final isVictory = stateManager.get('game.endingIsVictory', true) == true;

      // 清除标志，避免重复显示
      stateManager.set('game.showEndingDialog', false);

      // 显示结束对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameEndingDialog(
          isVictory: isVictory,
          onRestart: () {
            // 胜利后重新开始：清档重新开始游戏
            // 不需要额外操作，GameEndingDialog已经处理了deleteSave和重新初始化
            Logger.info('🚀 胜利后重新开始游戏，已清档重新初始化');
          },
        ),
      );
    }
  }

  /// 检查是否需要切换到破旧星舰页签
  void _checkSwitchToShip(BuildContext context, StateManager stateManager) {
    final shouldSwitch = stateManager.get('game.switchToShip', false) == true;
    Logger.info(
        '🔍 SpaceScreen._checkSwitchToShip() 被调用，shouldSwitch: $shouldSwitch');

    if (shouldSwitch) {
      Logger.info('🚀 检测到需要切换到破旧星舰页签，开始切换...');

      // 清除标志，避免重复切换
      stateManager.set('game.switchToShip', false);
      Logger.info('🚀 已清除 game.switchToShip 标志');

      // 获取Engine和Ship实例
      final engine = Provider.of<Engine>(context, listen: false);
      final ship = Provider.of<Ship>(context, listen: false);
      Logger.info('🚀 已获取Engine和Ship实例');

      // 切换到破旧星舰页签
      Logger.info('🚀 调用 engine.travelTo(ship)...');
      engine.travelTo(ship);
      Logger.info('🚀 已从太空切换到破旧星舰页签');
    }
  }

  /// 构建星空背景
  Widget _buildStarField(Space space) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: _StarFieldPainter(space.altitude),
      ),
    );
  }

  /// 构建小行星
  List<Widget> _buildAsteroids(Space space) {
    return space.asteroids.map((asteroid) {
      return Positioned(
        left: asteroid['x'],
        top: asteroid['y'],
        child: SizedBox(
          width: asteroid['width'],
          height: asteroid['height'],
          child: Text(
            asteroid['character'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 构建飞船
  Widget _buildShip(Space space) {
    return Positioned(
      left: space.shipX,
      top: space.shipY,
      child: SizedBox(
        width: 20,
        height: 20,
        child: const Text(
          '@',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建UI界面
  Widget _buildUI(Space space, Localization localization) {
    return Positioned(
      top: 20,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 船体状态
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              '${localization.translate('space.hull_remaining')}: ${space.hull}/${Ship().getMaxHull()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 高度显示
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              '${_getAltitudeLayer(space.altitude, localization)}: ${space.altitude}km',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Times New Roman',
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 控制说明
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('space.controls.title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Times New Roman',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  localization.translate('space.controls.wasd'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取高度层级名称
  String _getAltitudeLayer(int altitude, Localization localization) {
    if (altitude < 10) {
      return localization.translate('space.atmosphere_layers.troposphere');
    } else if (altitude < 20) {
      return localization.translate('space.atmosphere_layers.stratosphere');
    } else if (altitude < 30) {
      return localization.translate('space.atmosphere_layers.mesosphere');
    } else if (altitude < 45) {
      return localization.translate('space.atmosphere_layers.thermosphere');
    } else if (altitude < 60) {
      return localization.translate('space.atmosphere_layers.exosphere');
    } else {
      return localization.translate('space.atmosphere_layers.space');
    }
  }

  /// 构建方向控制按钮（仅APK版本）
  Widget _buildDirectionControls(Space space) {
    final layoutParams = GameLayoutParams.getLayoutParams(context);

    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '飞船控制',
              style: TextStyle(
                fontSize: layoutParams.useVerticalLayout ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Times New Roman',
              ),
            ),
            const SizedBox(height: 12),

            // 方向按钮布局
            Column(
              children: [
                // 上方按钮
                _buildDirectionButton('↑', '上', () {
                  Logger.info('📱 飞船方向按钮: 上');
                  space.setShipDirection(up: true);
                }, () {
                  space.setShipDirection(up: false);
                }, layoutParams),

                const SizedBox(height: 8),

                // 中间行：左、中、右
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 左按钮
                    _buildDirectionButton('←', '左', () {
                      Logger.info('📱 飞船方向按钮: 左');
                      space.setShipDirection(left: true);
                    }, () {
                      space.setShipDirection(left: false);
                    }, layoutParams),

                    const SizedBox(width: 8),

                    // 中间占位
                    SizedBox(
                      width: layoutParams.useVerticalLayout ? 48 : 56,
                      height: layoutParams.useVerticalLayout ? 48 : 56,
                    ),

                    const SizedBox(width: 8),

                    // 右按钮
                    _buildDirectionButton('→', '右', () {
                      Logger.info('📱 飞船方向按钮: 右');
                      space.setShipDirection(right: true);
                    }, () {
                      space.setShipDirection(right: false);
                    }, layoutParams),
                  ],
                ),

                const SizedBox(height: 8),

                // 下方按钮
                _buildDirectionButton('↓', '下', () {
                  Logger.info('📱 飞船方向按钮: 下');
                  space.setShipDirection(down: true);
                }, () {
                  space.setShipDirection(down: false);
                }, layoutParams),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个方向按钮
  Widget _buildDirectionButton(
    String arrow,
    String label,
    VoidCallback onPressStart,
    VoidCallback onPressEnd,
    GameLayoutParams layoutParams,
  ) {
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: () => onPressEnd(),
      child: Container(
        width: layoutParams.useVerticalLayout ? 48 : 56,
        height: layoutParams.useVerticalLayout ? 48 : 56,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              arrow,
              style: TextStyle(
                color: Colors.white,
                fontSize: layoutParams.useVerticalLayout ? 16 : 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: layoutParams.useVerticalLayout ? 8 : 10,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 星空绘制器
class _StarFieldPainter extends CustomPainter {
  final int altitude;

  _StarFieldPainter(this.altitude);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 根据高度绘制不同密度的星星
    final starCount = (altitude * 2).clamp(10, 100);

    for (int i = 0; i < starCount; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73) % size.height;
      final radius = (i % 3 + 1).toDouble();

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is _StarFieldPainter && oldDelegate.altitude != altitude;
  }
}

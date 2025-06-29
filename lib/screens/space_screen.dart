import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modules/space.dart';
import '../modules/ship.dart';
import '../core/localization.dart';
import '../core/logger.dart';

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
    return Consumer2<Space, Localization>(
      builder: (context, space, localization, child) {
        return Container(
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
              _buildUI(space, localization),
            ],
          ),
        );
      },
    );
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
          width: asteroid['size'],
          height: asteroid['size'],
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
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

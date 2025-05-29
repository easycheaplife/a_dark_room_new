import 'package:flutter/material.dart';

/// 世界界面 - 显示地图探索和生存状态
class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '��️ 世界探索\n\n即将推出...',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}

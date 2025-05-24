import 'package:flutter/material.dart';

/// 飞船界面 - 显示飞船状态和升级选项
class ShipScreen extends StatelessWidget {
  const ShipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '🚀 飞船\n\n即将推出...',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
